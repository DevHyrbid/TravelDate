//
//  ChatGalleryPresenter.swift
//  TravelDate
//
//  MVP — Presenter owns all gallery logic (loading, grouping, filtering, uploads).
//  ChatGalleryViewController only renders what the presenter tells it to.
//
//  No new backend endpoints: a "memory" is a normal chat media message.
//    • List   → ChatAPIService.fetchMessages, keep only image/video messages
//    • Upload → User.uploadImage (same as chat) → ChatAPIService.sendMessage(image|video)
//  So anything shared here also appears in the chat, and vice versa.
//

import UIKit

// MARK: - Notifications

extension Notification.Name {
    /// Posted after a memory is uploaded. userInfo["roomId"] = String.
    /// ChatMessageVc can observe this and refresh so the new media shows in the thread.
    static let chatGalleryDidUpload = Notification.Name("chatGalleryDidUpload")
}

// MARK: - Models

enum GalleryMediaKind {
    case photo
    case video
}

enum GalleryUploadState {
    case uploaded
    case uploading
    case failed
}

enum GalleryFilter: Int, CaseIterable {
    case all, photos, videos

    var title: String {
        switch self {
        case .all:    return "All"
        case .photos: return "Photos"
        case .videos: return "Videos"
        }
    }

    func includes(_ kind: GalleryMediaKind) -> Bool {
        switch self {
        case .all:    return true
        case .photos: return kind == .photo
        case .videos: return kind == .video
        }
    }
}

struct GalleryItem {
    let id: String
    let kind: GalleryMediaKind
    var remoteURL: String?          // server path / URL once uploaded
    var localPreview: UIImage?      // photo, or video thumbnail, while uploading
    var localVideoURL: URL?         // picked video file, while uploading
    var videoDuration: Int?         // seconds (known for local picks)
    let senderId: String
    let senderName: String
    let createdAt: Date
    var state: GalleryUploadState

    var isMine: Bool { senderId == (User.curentUser?.id ?? "") }

    /// Builds an item from a chat message. Returns nil for text messages.
    /// Reuses ChatItem's existing image/video detection so both screens agree.
    init?(message: ChatMessage) {
        let chat = ChatItem(message: message)
        switch chat.messageType {
        case 2:
            guard let url = chat.imageURL, !url.isEmpty else { return nil }
            kind = .photo
            remoteURL = url
        case 3:
            guard let url = chat.videoURL, !url.isEmpty else { return nil }
            kind = .video
            remoteURL = url
        default:
            return nil
        }
        id = chat.id
        senderId = chat.senderId
        senderName = chat.senderName
        createdAt = chat.createdAt
        state = .uploaded
    }

    /// Optimistic local item shown instantly while uploading.
    init(localKind: GalleryMediaKind,
         preview: UIImage?,
         videoURL: URL?,
         duration: Int?) {
        id = "temp-\(UUID().uuidString)"
        kind = localKind
        localPreview = preview
        localVideoURL = videoURL
        videoDuration = duration
        senderId = User.curentUser?.id ?? ""
        senderName = User.curentUser?.name ?? "You"
        createdAt = Date()
        state = .uploading
    }
}

struct GallerySection {
    let id: String        // "2026-11"
    let title: String     // "November 2026"
    let items: [GalleryItem]
}

// MARK: - View Protocol

@MainActor
protocol ChatGalleryView: AnyObject {
    func render(sections: [GallerySection], animated: Bool)
    func reloadItem(id: String)
    func showLoading(_ isLoading: Bool)
    func showEmptyState(_ isEmpty: Bool)
    func updateSummary(_ text: String)
    func showError(_ message: String)
}

// MARK: - Presenter

@MainActor
final class ChatGalleryPresenter {

    // MARK: Config
    /// Keep in line with what your upload endpoint accepts.
    static let maxVideoBytes: Int64 = 100 * 1024 * 1024    // 100 MB
    static let maxSelection = 10
    private static let minItemsBeforeAutoPaging = 30

    // MARK: Dependencies
    weak var view: ChatGalleryView?
    let roomId: String
    private let service = ChatAPIService()

    // MARK: State
    private var uploaded: [GalleryItem] = []           // from server, newest first
    private var pending: [GalleryItem] = []            // uploading / failed, newest first
    private var pendingPayloads: [String: UploadPayload] = [:]
    private var knownMessageIds = Set<String>()        // ALL message ids seen (text too)

    private(set) var filter: GalleryFilter = .all
    private(set) var sections: [GallerySection] = []

    private var page = 1
    private var isLoading = false
    private var reachedEnd = false

    private enum UploadPayload {
        case photo(Data)
        case video(URL)
    }

    private let monthKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    // MARK: Init

    init(roomId: String, view: ChatGalleryView?) {
        self.roomId = roomId
        self.view = view
    }

    // MARK: - Public: Loading

    func load() {
        page = 1
        reachedEnd = false
        knownMessageIds.removeAll()
        fetch(page: 1, reset: true)
    }

    func refresh() {
        load()
    }

    /// Call from the collection view when the user scrolls near the bottom.
    func loadMoreIfNeeded() {
        guard !isLoading, !reachedEnd else { return }
        fetch(page: page + 1, reset: false)
    }

    private func fetch(page requestedPage: Int, reset: Bool) {
        isLoading = true
        if uploaded.isEmpty && pending.isEmpty { view?.showLoading(true) }

        service.fetchMessages(roomId: roomId, page: requestedPage) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.view?.showLoading(false)

                switch result {
                case .success(let messages):
                    self.handleFetched(messages, page: requestedPage, reset: reset)
                case .failure(let error):
                    if self.uploaded.isEmpty && self.pending.isEmpty {
                        self.view?.showError(error.localizedDescription)
                    }
                    self.rebuild(animated: false)
                }
            }
        }
    }

    private func handleFetched(_ messages: [ChatMessage], page: Int, reset: Bool) {
        // A page with no message ids we haven't seen = the end. This also stops
        // safely if the backend ignores `page` and returns the same page again.
        let newMessages = messages.filter { !knownMessageIds.contains($0.id) }
        newMessages.forEach { knownMessageIds.insert($0.id) }
        if newMessages.isEmpty { reachedEnd = true }

        let media = newMessages.compactMap(GalleryItem.init(message:))
        uploaded = (reset ? media : uploaded + media)
            .sorted { $0.createdAt > $1.createdAt }
        self.page = page

        rebuild(animated: !reset)

        // Text-heavy chats: keep paging until there's enough media to fill the screen.
        if !reachedEnd && visibleCount < Self.minItemsBeforeAutoPaging {
            loadMoreIfNeeded()
        }
    }

    // MARK: - Public: Filter

    func setFilter(_ newFilter: GalleryFilter) {
        guard newFilter != filter else { return }
        filter = newFilter
        rebuild(animated: true)
    }

    // MARK: - Public: Lookup (for the viewer)

    /// Flat list in display order — what the full-screen viewer pages through.
    var flatItems: [GalleryItem] {
        sections.flatMap(\.items)
    }

    func item(id: String) -> GalleryItem? {
        pending.first { $0.id == id } ?? uploaded.first { $0.id == id }
    }

    // MARK: - Public: Uploads

    func upload(photo: UIImage) {
        guard let data = photo.jpegData(compressionQuality: 0.8) else {
            view?.showError("Couldn't read that photo.")
            return
        }
        let item = GalleryItem(localKind: .photo, preview: photo, videoURL: nil, duration: nil)
        startUpload(item: item, payload: .photo(data))
    }

    /// `fileURL` must be a file you own (copied out of the picker's temp location).
    func upload(videoAt fileURL: URL) {
        let size = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
        guard size <= Self.maxVideoBytes else {
            let limitMB = Self.maxVideoBytes / 1024 / 1024
            view?.showError("This video is too large. Please choose one under \(limitMB) MB.")
            try? FileManager.default.removeItem(at: fileURL)
            return
        }

        let thumbnail = ChatVideoThumbnailLoader.generateThumbnailSync(for: fileURL)
        let duration = ChatVideoThumbnailLoader.duration(for: fileURL)
        let item = GalleryItem(localKind: .video, preview: thumbnail, videoURL: fileURL, duration: duration)
        startUpload(item: item, payload: .video(fileURL))
    }

    func retry(id: String) {
        guard let index = pending.firstIndex(where: { $0.id == id }),
              pending[index].state == .failed,
              let payload = pendingPayloads[id] else { return }
        pending[index].state = .uploading
        view?.reloadItem(id: id)
        performUpload(id: id, payload: payload)
    }

    /// Removes a failed upload the user doesn't want to retry.
    func discardFailed(id: String) {
        guard let index = pending.firstIndex(where: { $0.id == id }),
              pending[index].state == .failed else { return }
        cleanUpPayload(for: id)
        pending.remove(at: index)
        rebuild(animated: true)
    }

    // MARK: - Upload pipeline

    private func startUpload(item: GalleryItem, payload: UploadPayload) {
        pending.insert(item, at: 0)
        pendingPayloads[item.id] = payload
        // Make sure the new item is visible even if a filter would hide it.
        if !filter.includes(item.kind) { filter = .all }
        rebuild(animated: true)
        performUpload(id: item.id, payload: payload)
    }

    private func performUpload(id: String, payload: UploadPayload) {
        // Large video files are read off the main thread.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let isPhoto: Bool
            let data: Data?
            switch payload {
            case .photo(let d):
                isPhoto = true
                data = d
            case .video(let url):
                isPhoto = false
                data = try? Data(contentsOf: url)
            }

            DispatchQueue.main.async {
                guard let self else { return }
                guard let data else {
                    self.markFailed(id: id)
                    return
                }

                // 1) Upload the file — same helper the chat screen uses.
                User.new().uploadImage(isPhoto, data) { [weak self] fileURL, code in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        guard code == Constants.APIResponseCodes.statusCodeSuccessfull,
                              !fileURL.isEmpty else {
                            self.markFailed(id: id)
                            return
                        }
                        // 2) Post it to the chat so everyone in the room sees it.
                        self.sendToChat(id: id, fileURL: fileURL, isPhoto: isPhoto)
                    }
                }
            }
        }
    }

    private func sendToChat(id: String, fileURL: String, isPhoto: Bool) {
        service.sendMessage(roomId: roomId,
                            content: fileURL,
                            contentType: isPhoto ? "image" : "video") { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let message):
                    self.finishUpload(tempId: id, message: message, fileURL: fileURL)
                case .failure:
                    self.markFailed(id: id)
                }
            }
        }
    }

    private func finishUpload(tempId: String, message: ChatMessage, fileURL: String) {
        guard let index = pending.firstIndex(where: { $0.id == tempId }) else { return }
        var local = pending.remove(at: index)

        // Prefer the server's version; fall back to the local one marked as uploaded.
        let final: GalleryItem
        if let serverItem = GalleryItem(message: message) {
            final = serverItem
        } else {
            local.remoteURL = fileURL
            local.state = .uploaded
            final = local
        }
        knownMessageIds.insert(message.id)
        uploaded.removeAll { $0.id == final.id }
        uploaded.insert(final, at: 0)

        cleanUpPayload(for: tempId)
        rebuild(animated: true)

        NotificationCenter.default.post(name: .chatGalleryDidUpload,
                                        object: nil,
                                        userInfo: ["roomId": roomId])
    }

    private func markFailed(id: String) {
        guard let index = pending.firstIndex(where: { $0.id == id }) else { return }
        pending[index].state = .failed
        view?.reloadItem(id: id)
    }

    private func cleanUpPayload(for id: String) {
        if case .video(let url)? = pendingPayloads[id] {
            try? FileManager.default.removeItem(at: url)
        }
        pendingPayloads[id] = nil
    }

    // MARK: - Grouping

    private var visibleCount: Int {
        sections.reduce(0) { $0 + $1.items.count }
    }

    private func rebuild(animated: Bool) {
        let all = pending + uploaded
        let filtered = all.filter { filter.includes($0.kind) }

        // Group by month, keep newest month first. Pending items have "now" dates,
        // so they land in the current month at the top.
        var order: [String] = []
        var buckets: [String: [GalleryItem]] = [:]
        for item in filtered {
            let key = monthKeyFormatter.string(from: item.createdAt)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(item)
        }

        sections = order.map { key in
            let items = buckets[key] ?? []
            let title = items.first.map { monthTitleFormatter.string(from: $0.createdAt) } ?? key
            return GallerySection(id: key, title: title, items: items)
        }

        let photos = all.filter { $0.kind == .photo }.count
        let videos = all.filter { $0.kind == .video }.count
        view?.updateSummary(Self.summary(photos: photos, videos: videos))
        view?.render(sections: sections, animated: animated)
        view?.showEmptyState(sections.isEmpty && !isLoading)
    }

    private static func summary(photos: Int, videos: Int) -> String {
        func plural(_ n: Int, _ word: String) -> String { "\(n) \(word)\(n == 1 ? "" : "s")" }
        switch (photos, videos) {
        case (0, 0): return "No memories yet"
        case (_, 0): return plural(photos, "photo")
        case (0, _): return plural(videos, "video")
        default:     return "\(plural(photos, "photo")) · \(plural(videos, "video"))"
        }
    }
}
