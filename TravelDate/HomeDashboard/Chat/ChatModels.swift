//
//  ChatModels.swift
//  TravelDate
//
//  Pure data models for the API-only chat module.
//

import Foundation

// MARK: - Room Type

enum ChatRoomType: String, Codable {
    case individual
    case group
}

// MARK: - Message Status (for optimistic UI)

enum MessageStatus {
    case sending   // shown immediately, waiting for API
    case sent      // API confirmed
    case failed    // API failed → allow retry
}

// MARK: - Chat User

struct ChatUser: Codable {
    let id: String?
    let name: String?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case id, name, profileImage
    }
}

// MARK: - Chat Message (server model)

struct ChatMessage: Codable {
    let id: String
    let roomId: String?
    let senderId: String?
    let content: String?
    let contentType: String?
    let createdAt: String?
    let sender: ChatUser?
}

// MARK: - Chat Item (what the UI actually renders)
//
// We wrap the server message so we can also carry a local status
// (sending / sent / failed) and a temporary id for optimistic updates.

struct ChatItem {
    var id: String              // server id OR temp local id
    let senderId: String
    let senderName: String
    let senderImage: String?
    var content: String
    let createdAt: Date
    var status: MessageStatus

    var isMine: Bool {
        senderId == (User.curentUser?.id ?? "")
    }
}

extension ChatItem {

    /// Build from a server message.
    init(message: ChatMessage) {
        self.id          = message.id
        self.senderId    = message.senderId ?? message.sender?.id ?? ""
        self.senderName  = message.sender?.name ?? ""
        self.senderImage = message.sender?.profileImage
        self.content     = message.content ?? ""
        self.createdAt   = ChatDate.parse(message.createdAt)
        self.status      = .sent
    }

    /// Build a temporary local message for optimistic UI.
    /// `senderId` is passed in (the VM's currentUserId) so this model has no
    /// hard dependency on the shape of your `User` object beyond `.id`.
    static func temporary(content: String, senderId: String) -> ChatItem {
        ChatItem(
            id:          "temp-\(UUID().uuidString)",
            senderId:    senderId,
            senderName:  "",          // not shown for my own bubbles
            senderImage: nil,         // not shown for my own bubbles
            content:     content,
            createdAt:   Date(),
            status:      .sending
        )
    }
}

// MARK: - API Envelopes

struct CreateRoomResponse: Codable {
    let success: Bool?
    let code: Int?
    let message: String?
    let data: RoomData?
}

struct RoomData: Codable {
    let id: String?
    let type: String?
}

struct SendMessageResponse: Codable {
    let success: Bool?
    let code: Int?
    let message: String?
    let data: ChatMessage?
}

struct MessagesResponse: Codable {
    let success: Bool?
    let code: Int?
    let data: [ChatMessage]?
}
