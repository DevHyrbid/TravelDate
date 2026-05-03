


//
//  SocketIOManager.swift
//  TravelDate
//
//  Created by Dev CodingZone on 01/05/26.
//

import Foundation
import SocketIO

// MARK: - Socket Event Delegates

protocol ChatSocketDelegate: AnyObject {
    func didReceiveNewMessage(_ message: MessageModel)
    func didJoinRoom(roomId: String)
    func didReceiveMessages(_ messages: [MessageModel])
    func didReceiveTyping(senderId: String, isTyping: Bool)
    func didReceiveMessagesRead(roomId: String)
    func didReceiveUserOnline(userId: String)
    func didReceiveUserOffline(userId: String)
    func didReceiveChatDeleted(roomId: String)
    func didReceiveMessagesDeleted(messageIds: [String])
    func didLeaveGroupChat(roomId: String)
    func didReceiveRooms(_ rooms: [[String: Any]])
}

// Optional defaults so VC doesn't have to implement all
extension ChatSocketDelegate {
    func didReceiveTyping(senderId: String, isTyping: Bool) {}
    func didReceiveMessagesRead(roomId: String) {}
    func didReceiveUserOnline(userId: String) {}
    func didReceiveUserOffline(userId: String) {}
    func didReceiveChatDeleted(roomId: String) {}
    func didReceiveMessagesDeleted(messageIds: [String]) {}
    func didLeaveGroupChat(roomId: String) {}
    func didReceiveRooms(_ rooms: [[String: Any]]) {}
}

// MARK: - SocketIOManager

class SocketIOManager {
    var currentGroupId: String = ""  // 👈 ADD

    static let shared = SocketIOManager()

    private var manager: SocketManager!
    var socket: SocketIOClient!
    private var isListening = false

    weak var delegate: ChatSocketDelegate?

    private init() {
       
        let url = URL(string: APiConstant.base)!
        let token = UserDefaults.standard.string(forKey: "UserToken") ?? ""

        manager = SocketManager(
            socketURL: url,
            config: [
                .log(true),
                .compress,
                .reconnects(true),
                .reconnectAttempts(-1),
                .extraHeaders([
                    "Authorization": "Bearer \(token)"
                ])
            ]
        )

        socket = manager.defaultSocket
    }

    // MARK: - Connect / Disconnect

    func connect() {
        guard socket.status != .connected else {
            print("⚡ Socket already connected")
            return
        }
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
        isListening = false
    }

    // MARK: - Setup All Listeners

    func setupListeners() {
        guard !isListening else { return }
        isListening = true

        // ─── Connection ───────────────────────────────────────────
        socket.on(clientEvent: .connect) { _, _ in
            print("✅ Socket connected")
        }

        socket.on(clientEvent: .disconnect) { data, _ in
            print("❌ Socket disconnected — \(data)")
        }

        socket.on(clientEvent: .error) { data, _ in
            print("🔴 Socket error — \(data)")
        }

        // ─── 1. newMessage ────────────────────────────────────────
        // Server sends when someone sends a message in the room
        socket.on("newMessage") { [weak self] data, _ in
            print("📩 newMessage received: \(data)")
            guard let dict = data.first as? [String: Any] else { return }
            let msg = MessageModel(dict: dict)
            DispatchQueue.main.async {
                self?.delegate?.didReceiveNewMessage(msg)
            }
        }

        // ─── 2. joinedRoom ────────────────────────────────────────
        // Server confirms room join and returns roomId
        socket.on("joinedRoom") { [weak self] data, _ in
            print("🏠 joinedRoom received: \(data)")
            guard let dict   = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? String else { return }
            DispatchQueue.main.async {
                self?.delegate?.didJoinRoom(roomId: roomId)
            }
        }

        // ─── 3. typing ───────────────────────────────────────────
        // Server broadcasts typing status to room members
        socket.on("typing") { [weak self] data, _ in
            print("⌨️ typing received: \(data)")
            guard let dict       = data.first as? [String: Any],
                  let senderId   = dict["senderId"] as? String,
                  let isTyping   = dict["isTyping"] as? Bool else { return }
            DispatchQueue.main.async {
                self?.delegate?.didReceiveTyping(senderId: senderId, isTyping: isTyping)
            }
        }

        // ─── 4. messagesRead ─────────────────────────────────────
        // Server notifies when messages are read
        socket.on("messagesRead") { [weak self] data, _ in
            print("👁 messagesRead received: \(data)")
            guard let dict   = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? String else { return }
            DispatchQueue.main.async {
                self?.delegate?.didReceiveMessagesRead(roomId: roomId)
            }
        }

        // ─── 5. chatDeleted ──────────────────────────────────────
        // Server notifies when a chat/room is deleted
        socket.on("chatDeleted") { [weak self] data, _ in
            print("🗑 chatDeleted received: \(data)")
            guard let dict   = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? String else { return }
            DispatchQueue.main.async {
                self?.delegate?.didReceiveChatDeleted(roomId: roomId)
            }
        }

        // ─── 6. messagesDeleted ──────────────────────────────────
        // Server notifies when specific messages are deleted
        socket.on("messagesDeleted") { [weak self] data, _ in
            print("🗑 messagesDeleted received: \(data)")
            guard let dict       = data.first as? [String: Any],
                  let messageIds = dict["messageIds"] as? [String] else { return }
            DispatchQueue.main.async {
                self?.delegate?.didReceiveMessagesDeleted(messageIds: messageIds)
            }
        }

        // ─── 7. rooms ────────────────────────────────────────────
        // Server sends list of rooms
        socket.on("rooms") { [weak self] data, _ in
            print("🏠 rooms received: \(data)")
            guard let rooms = data.first as? [[String: Any]] else { return }
            DispatchQueue.main.async {
                self?.delegate?.didReceiveRooms(rooms)
            }
        }

        // ─── 8. messages ─────────────────────────────────────────
        // Server returns old messages on getMessages emit
        socket.on("messages") { [weak self] data, _ in
            print("💬 messages received: \(data)")
            guard let dict   = data.first as? [String: Any],
                  let msgArr = dict["messages"] as? [[String: Any]] else { return }  // ✅ dict["messages"]
            let messages = msgArr.map { MessageModel(dict: $0) }
            DispatchQueue.main.async {
                self?.delegate?.didReceiveMessages(messages)
            }
        }

        // ─── 9. userOnline ───────────────────────────────────────
        socket.on("userOnline") { [weak self] data, _ in
            print("🟢 userOnline received: \(data)")
            guard let dict   = data.first as? [String: Any],
                  let userId = dict["userId"] as? String else { return }
            DispatchQueue.main.async {
                self?.delegate?.didReceiveUserOnline(userId: userId)
            }
        }

        // ─── 10. userOffline ─────────────────────────────────────
        socket.on("userOffline") { [weak self] data, _ in
            print("🔴 userOffline received: \(data)")
            guard let dict   = data.first as? [String: Any],
                  let userId = dict["userId"] as? String else { return }
            DispatchQueue.main.async {
                self?.delegate?.didReceiveUserOffline(userId: userId)
            }
        }

        // ─── 11. leaveGroupChat ──────────────────────────────────
        socket.on("leaveGroupChat") { [weak self] data, _ in
            print("🚪 leaveGroupChat received: \(data)")
            guard let dict   = data.first as? [String: Any],
                  let roomId = dict["roomId"] as? String else { return }
            DispatchQueue.main.async {
                self?.delegate?.didLeaveGroupChat(roomId: roomId)
            }
        }
        
        
        // SocketIOManager mein rooms listener update karo
        socket.on("rooms") { [weak self] data, _ in
            print("🏠 rooms received: \(data)")
            guard let roomsArr = data.first as? [[String: Any]] else { return }
            
            // Pehla room le lo — joinRoom ke baad server sirf usi room ka data bhejta hai
            if let firstRoom = roomsArr.first,
               let roomId = firstRoom["id"] as? String {
                print("✅ roomId from rooms: \(roomId)")
                DispatchQueue.main.async {
                    self?.delegate?.didJoinRoom(roomId: roomId)
                }
            }
        }
    }

    // MARK: - Emit Events

    /// Emit: joinRoom
    func joinRoom(participants: [String], type: String, groupId: String, roomId: String = "") {
        var params: [String: Any] = [
            "participants": participants,
            "type":         type
        ]
        if !groupId.isEmpty { params["groupId"] = groupId }
        if !roomId.isEmpty  { params["roomId"]  = roomId  }

        print("🚀 emit joinRoom: \(params)")
        socket.emit("joinRoom", params)
    }

    /// Emit: sendMessage (text)
    func sendTextMessage(roomId: String, content: String) {
        let params: [String: Any] = [
            "roomId":      roomId,
            "content":     content,
            "contentType": "text"
        ]
        print("🚀 emit sendMessage (text): \(params)")
        socket.emit("sendMessage", params)
    }

    /// Emit: sendMessage (image)
    func sendImageMessage(roomId: String, imageUrl: String) {
        let params: [String: Any] = [
            "roomId":      roomId,
            "content":     "",
            "contentType": "image",
            "imageUrl":    imageUrl
        ]
        print("🚀 emit sendMessage (image): \(params)")
        socket.emit("sendMessage", params)
    }

    /// Emit: typing
    func sendTyping(roomId: String, isTyping: Bool) {
        let params: [String: Any] = [
            "roomId":   roomId,
            "isTyping": isTyping
        ]
        print("🚀 emit typing: \(params)")
        socket.emit("typing", params)
    }

    /// Emit: getMessages (fetch old messages)
    func getMessages(roomId: String) {
        let params: [String: Any] = ["roomId": roomId]
        print("🚀 emit getMessages: \(params)")
        socket.emit("getMessages", params)
    }

    /// Emit: leaveGroupChat
    func leaveGroupChat(roomId: String) {
//        let params: [String: Any] = ["roomId": roomId]
//        print("🚀 emit leaveGroupChat: \(params)")
//        socket.emit("leaveGroupChat", params)
    }
}
