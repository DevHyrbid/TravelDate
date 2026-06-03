//
//  ChatViewModel.swift
//  TravelDate
//
//  Owns all chat state and logic. The VC only renders what this exposes.
//
//  Init matches your EXISTING call site in ChatVc:
//      ChatViewModel(currentUserId: User.curentUser?.id ?? "")
//
//  Participants / type / roomId are injected by the VC via `configure(...)`.
//

import Foundation

final class ChatViewModel {

    // MARK: - Dependencies
    private let service: ChatAPIService
    let currentUserId: String

    // MARK: - Inputs (injected by the VC before start())
    var participants: [String] = []
     var roomType: ChatRoomType = .individual
    private(set) var roomId: String?

    // MARK: - State
    private(set) var items: [ChatItem] = []        // sorted oldest → newest
    private(set) var sections: [ChatSection] = []

    private var page = 1
    private var isLoading = false
    private var canLoadMore = true

    // MARK: - Callbacks (VC binds to these)
    var onReload: (() -> Void)?
    var onAppend: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    // MARK: - Init (single arg, matches ChatVc)

    init(currentUserId: String,
         service: ChatAPIService = ChatAPIService()) {
        self.currentUserId = currentUserId
        self.service       = service
    }

    /// Inject the room context. Called by the VC right after init.
    func configure(participants: [String],
                   type: ChatRoomType,
                   roomId: String? = nil) {
        self.participants = participants
        self.roomType     = type
        self.roomId       = roomId
    }

    // MARK: - Entry point (call from viewDidLoad)

    func start() {
        if let roomId = roomId, !roomId.isEmpty {
            loadFirstPage()
        } else {
            createRoom()
        }
    }

    // MARK: - 1. Create / Get Room

    private func createRoom() {
        let safe = safeParticipants()
        guard safe.count >= 1 else {
            onError?("Missing participant info"); return
        }
        setLoading(true)

        service.createRoom(participants: safe, type: roomType) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let roomId):
                    self.roomId = roomId
                    self.loadFirstPage()
                case .failure(let err):
                    self.setLoading(false)
                    self.onError?(err.localizedDescription)
                }
            }
        }
    }

    /// Always include current user, find the OTHER one, never duplicate.
//    private func safeParticipants() -> [String] {
//        let other = participants.first(where: { $0 != currentUserId && !$0.isEmpty }) ?? ""
//        var result = [currentUserId]
//        if !other.isEmpty { result.append(other) }
//        return result
//    }
    private func safeParticipants() -> [String] {
print(participants,"COUN")
        return participants
            .joined(separator: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - 2. Send Message (optimistic)

    func send(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let roomId = roomId else { return }

        // a) Show instantly
        let temp = ChatItem.temporary(content: text, senderId: currentUserId)
        items.append(temp)
        rebuildSections()
        onAppend?()

        // b) Hit API
        service.sendMessage(roomId: roomId, content: text) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let serverMsg):
                    self.replaceTemp(id: temp.id, with: ChatItem(message: serverMsg))
                case .failure:
                    self.markFailed(id: temp.id)
                }
            }
        }
    }

    /// Retry a previously failed message.
    func retry(itemId: String) {
        guard let index = items.firstIndex(where: { $0.id == itemId }),
              let roomId = roomId else { return }
        let text = items[index].content
        items[index].status = .sending
        rebuildSections()
        onReload?()

        service.sendMessage(roomId: roomId, content: text) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let serverMsg):
                    self.replaceTemp(id: itemId, with: ChatItem(message: serverMsg))
                case .failure:
                    self.markFailed(id: itemId)
                }
            }
        }
    }

    private func replaceTemp(id: String, with newItem: ChatItem) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        // Avoid duplicate if the same server message already arrived via fetch.
        if items.contains(where: { $0.id == newItem.id }) {
            items.remove(at: index)
        } else {
            items[index] = newItem
        }
        rebuildSections()
        onReload?()
    }

    private func markFailed(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].status = .failed
        rebuildSections()
        onReload?()
    }

    // MARK: - 3. Fetch Messages

    func loadFirstPage() {
        page = 1
        canLoadMore = true
        fetch(page: page, isFirst: true)
    }

    func refresh() { loadFirstPage() }

    /// Called when user scrolls near the top → older messages.
    func loadOlderIfNeeded() {
        guard !isLoading, canLoadMore, roomId != nil else { return }
        fetch(page: page + 1, isFirst: false)
    }

    private func fetch(page: Int, isFirst: Bool) {
        guard let roomId = roomId, !isLoading else { return }
        setLoading(true)

        service.fetchMessages(roomId: roomId, page: page) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.setLoading(false)
                switch result {
                case .success(let messages):
                    self.handleFetched(messages, page: page, isFirst: isFirst)
                case .failure(let err):
                    self.onError?(err.localizedDescription)
                }
            }
        }
    }

    private func handleFetched(_ messages: [ChatMessage], page: Int, isFirst: Bool) {
        // Server returns newest → oldest; we render oldest → newest.
        let fetched = messages
            .map(ChatItem.init(message:))
            .sorted { $0.createdAt < $1.createdAt }

        if fetched.isEmpty { canLoadMore = false }

        if isFirst {
            // Keep any in-flight (sending/failed) local messages on top.
            let pending = items.filter { $0.status != .sent }
            items = mergeUnique(server: fetched, pending: pending)
            self.page = 1
        } else {
            // Prepend older, drop duplicates.
            let existingIds = Set(items.map { $0.id })
            let older = fetched.filter { !existingIds.contains($0.id) }
            items.insert(contentsOf: older, at: 0)
            self.page = page
        }
        rebuildSections()
        onReload?()
    }

    /// Server messages + still-pending local messages, no duplicate ids.
    private func mergeUnique(server: [ChatItem], pending: [ChatItem]) -> [ChatItem] {
        var seen = Set<String>()
        var result: [ChatItem] = []
        for item in (server + pending) where !seen.contains(item.id) {
            seen.insert(item.id)
            result.append(item)
        }
        return result.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Helpers

    private func rebuildSections() {
        sections = ChatSectionBuilder.build(from: items)
    }

    private func setLoading(_ value: Bool) {
        isLoading = value
        onLoadingChanged?(value)
    }
}
