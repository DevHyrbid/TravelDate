//
//  SocketIOManager.swift
//  TravelDate
//

import Foundation
import SocketIO

// MARK: - Chat Room Type

enum ChatRoomType: String {
    case group      = "group"
    case individual = "individual"
}

// MARK: - Active Room State

struct ActiveRoom {
    let roomId:       String
    let type:         ChatRoomType
    let groupId:      String
    let participants: [String]
}

// MARK: - Delegate Protocol

protocol ChatSocketDelegate: AnyObject {
    func socketConnected()
    func didJoinRoom(roomId: String)
    func didReceiveMessages(_ messages: [MessageModel])
    func didReceiveNewMessage(_ message: MessageModel)
    func didReceiveTyping(senderId: String, isTyping: Bool)
    func didReceiveMessagesRead(roomId: String)
    func didReceiveUserOnline(userId: String)
    func didReceiveUserOffline(userId: String)
    func didReceiveChatDeleted(roomId: String)
    func didReceiveMessagesDeleted(messageIds: [String])
    func didLeaveGroupChat(roomId: String)
}

// MARK: - Optional Defaults

extension ChatSocketDelegate {
    func didReceiveTyping(senderId: String, isTyping: Bool)  {}
    func didReceiveMessagesRead(roomId: String)              {}
    func didReceiveUserOnline(userId: String)                {}
    func didReceiveUserOffline(userId: String)               {}
    func didReceiveChatDeleted(roomId: String)               {}
    func didReceiveMessagesDeleted(messageIds: [String])     {}
    func didLeaveGroupChat(roomId: String)                   {}
}

// MARK: - SocketIOManager

final class SocketIOManager {

    // MARK: - Singleton
    static let shared = SocketIOManager()

    // MARK: - Private Properties
    private var manager:           SocketManager!
    private(set) var socket:       SocketIOClient!
    private var hasSetupListeners  = false
    private(set) var activeRoom:   ActiveRoom?

    // NSHashTable = weak refs, auto-removes deallocated delegates
    private let delegates = NSHashTable<AnyObject>.weakObjects()

    // MARK: - Init
    private init() {
        buildSocket()
    }

    // MARK: - Build Socket
    private func buildSocket() {
        guard let url = URL(string: APiConstant.base) else {
            print("🔴 Invalid socket URL")
            return
        }
        let token = UserDefaults.standard.string(forKey: "UserToken") ?? ""

        manager = SocketManager(
            socketURL: url,
            config: [
                .log(false),
                .compress,
                .reconnects(true),
                .reconnectAttempts(-1),
                .extraHeaders(["Authorization": "Bearer \(token)"])
            ]
        )
        socket = manager.defaultSocket
    }

    // MARK: - Delegate Management

    func addDelegate(_ delegate: ChatSocketDelegate) {
        delegates.add(delegate as AnyObject)
    }

    func removeDelegate(_ delegate: ChatSocketDelegate) {
        delegates.remove(delegate as AnyObject)
    }

    private func notifyAll(_ block: (ChatSocketDelegate) -> Void) {
        delegates.allObjects
            .compactMap { $0 as? ChatSocketDelegate }
            .forEach(block)
    }

    // MARK: - Connect / Disconnect

    func connect() {
        switch socket.status {
        case .connected:
            print("⚡ Already connected — notifying delegates")
            DispatchQueue.main.async { [weak self] in
                self?.notifyAll { $0.socketConnected() }
            }
        case .connecting:
            print("⏳ Socket is connecting…")
        default:
            print("🔌 Connecting socket…")
            socket.connect()
        }
    }

    func disconnect() {
        activeRoom = nil
        socket.disconnect()
    }

    // MARK: - Setup Listeners (call ONCE from AppDelegate)

    func setupListeners() {
        guard !hasSetupListeners else { return }
        hasSetupListeners = true

        // ── Connection Events ──────────────────────────────────────

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("✅ Socket connected")
            DispatchQueue.main.async {
                self?.notifyAll { $0.socketConnected() }
            }
        }

        socket.on(clientEvent: .disconnect) { _, _ in
            print("❌ Socket disconnected")
        }

        socket.on(clientEvent: .error) { data, _ in
            print("🔴 Socket error: \(data)")
        }

        socket.on(clientEvent: .reconnect) { [weak self] _, _ in
            print("🔄 Reconnected — rejoining active room")
            self?.rejoinActiveRoomIfNeeded()
        }

        // ── newMessage ─────────────────────────────────────────────
        socket.on("newMessage") { [weak self] data, _ in
            guard let self,
                  let dict = data.first as? [String: Any] else { return }

            let msg = MessageModel(dict: dict)

            // ✅ Filter: ignore messages not for active room
//            guard let activeRoomId = self.activeRoom?.roomId,
//                  msg.roomId == activeRoomId else {
//                print("🚫 Ignored newMessage — wrong room: \(msg.roomId ?? "nil")")
//                return
//            }

            print("📩 newMessage: \(msg.content ?? "")")
            DispatchQueue.main.async {
                self.notifyAll { $0.didReceiveNewMessage(msg) }
            }
        }

        // ── joinedRoom ─────────────────────────────────────────────
        socket.on("joinedRoom") { [weak self] data, _ in
            guard let dict   = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? String else { return }
            print("🏠 joinedRoom: \(roomId)")
            DispatchQueue.main.async {
                self?.notifyAll { $0.didJoinRoom(roomId: roomId) }
            }
        }

        // ── rooms (fallback after joinRoom) ────────────────────────
        socket.on("rooms") { [weak self] data, _ in
            guard let roomsArr  = data.first as? [[String: Any]],
                  let firstRoom = roomsArr.first,
                  let roomId    = firstRoom["id"] as? String else { return }
            print("🏠 rooms → roomId: \(roomId)")
            DispatchQueue.main.async {
                self?.notifyAll { $0.didJoinRoom(roomId: roomId) }
            }
        }

        // ── messages (history) ─────────────────────────────────────
        socket.on("messages") { [weak self] data, _ in
            guard let self,
                  let dict   = data.first as? [String: Any],
                  let msgArr = dict["messages"] as? [[String: Any]] else { return }

            let all      = msgArr.map { MessageModel(dict: $0) }
            let filtered = all.filter { $0.roomId == self.activeRoom?.roomId }

            print("💬 messages received: \(all.count), filtered: \(filtered.count)")
            DispatchQueue.main.async {
                self.notifyAll { $0.didReceiveMessages(filtered) }
            }
        }

        // ── typing ─────────────────────────────────────────────────
        socket.on("typing") { [weak self] data, _ in
            guard let dict     = data.first as? [String: Any],
                  let senderId = dict["senderId"] as? String,
                  let isTyping = dict["isTyping"] as? Bool else { return }
            DispatchQueue.main.async {
                self?.notifyAll { $0.didReceiveTyping(senderId: senderId, isTyping: isTyping) }
            }
        }

        // ── messagesRead ───────────────────────────────────────────
        socket.on("messagesRead") { [weak self] data, _ in
            guard let dict   = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? String else { return }
            DispatchQueue.main.async {
                self?.notifyAll { $0.didReceiveMessagesRead(roomId: roomId) }
            }
        }

        // ── chatDeleted ────────────────────────────────────────────
        socket.on("chatDeleted") { [weak self] data, _ in
            guard let dict   = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? String else { return }
            DispatchQueue.main.async {
                self?.notifyAll { $0.didReceiveChatDeleted(roomId: roomId) }
            }
        }

        // ── messagesDeleted ────────────────────────────────────────
        socket.on("messagesDeleted") { [weak self] data, _ in
            guard let dict       = data.first as? [String: Any],
                  let messageIds = dict["messageIds"] as? [String] else { return }
            DispatchQueue.main.async {
                self?.notifyAll { $0.didReceiveMessagesDeleted(messageIds: messageIds) }
            }
        }

        // ── userOnline ─────────────────────────────────────────────
        socket.on("userOnline") { [weak self] data, _ in
            guard let dict   = data.first as? [String: Any],
                  let userId = dict["userId"] as? String else { return }
            DispatchQueue.main.async {
                self?.notifyAll { $0.didReceiveUserOnline(userId: userId) }
            }
        }

        // ── userOffline ────────────────────────────────────────────
        socket.on("userOffline") { [weak self] data, _ in
            guard let dict   = data.first as? [String: Any],
                  let userId = dict["userId"] as? String else { return }
            DispatchQueue.main.async {
                self?.notifyAll { $0.didReceiveUserOffline(userId: userId) }
            }
        }

        // ── leaveGroupChat ─────────────────────────────────────────
        socket.on("leaveGroupChat") { [weak self] data, _ in
            guard let dict   = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? String else { return }
            DispatchQueue.main.async {
                self?.notifyAll { $0.didLeaveGroupChat(roomId: roomId) }
            }
        }
    }

    // MARK: - Room Management

    func joinRoom(
        roomId:       String,
        type:         ChatRoomType,
        groupId:      String      = "",
        participants: [String]    = []
    ) {
        // Leave previous room if different
        if let prev = activeRoom, prev.roomId != roomId {
            leaveCurrentRoom()
        }

        // ✅ Set active room BEFORE emit so filter works instantly
        activeRoom = ActiveRoom(
            roomId:       roomId,
            type:         type,
            groupId:      groupId,
            participants: participants
        )

        // Build params cleanly
        var params: [String: Any] = ["type": type.rawValue]

        if !participants.isEmpty { params["participants"] = participants }
        if !groupId.isEmpty      { params["groupId"]      = groupId     }
        if !roomId.isEmpty       { params["roomId"]        = roomId     }

        print("🚀 emit joinRoom: \(params)")
        socket.emit("joinRoom", params)
    }

    func leaveCurrentRoom() {
        guard let room = activeRoom else { return }
        print("🚪 Leaving room: \(room.roomId)")
        if room.type == .group {
            socket.emit("leaveGroupChat", ["roomId": room.roomId])
        }
        activeRoom = nil
    }

    private func rejoinActiveRoomIfNeeded() {
        guard let room = activeRoom else { return }
        joinRoom(
            roomId:       room.roomId,
            type:         room.type,
            groupId:      room.groupId,
            participants: room.participants
        )
    }

    // MARK: - Emit Helpers

    func sendTextMessage(roomId: String, content: String) {
        
        var params: [String: Any] = [
            "content": content,
            "contentType": "text"
        ]

        if !roomId.isEmpty {
            params["roomId"] = roomId
        }
        print("🚀 emit sendMessage: \(params)")
        socket.emit("sendMessage", params)
    }

    func sendImageMessage(roomId: String, imageUrl: String) {
        let params: [String: Any] = [
            "roomId":      roomId,
            "content":     "",
            "contentType": "image",
            "imageUrl":    imageUrl
        ]
        socket.emit("sendMessage", params)
    }

    func sendTyping(roomId: String, isTyping: Bool) {
        socket.emit("typing", ["roomId": roomId, "isTyping": isTyping])
    }

    func getMessages(roomId: String) {
        print("🚀 emit getMessages: \(roomId)")
        socket.emit("getMessages", ["roomId": roomId])
    }

    func leaveGroupChat(roomId: String) {
        socket.emit("leaveGroupChat", ["roomId": roomId])
    }
}
