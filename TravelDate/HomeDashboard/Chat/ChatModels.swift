//
//  ChatModels.swift
//  TravelDate
//
//  Pure data models for the API-only chat module.
//

import Foundation
import UIKit

// MARK: - Room Type

enum ChatRoomType: String, Codable {
    case individual
    case group
    case match
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
    let contentType: String?      // or Int if your API sends a number
    let messageType: Int?         // add if needed
    let createdAt: String?
    let sender: ChatUser?
    let fileUrl: String?
}

// MARK: - Chat Item (what the UI actually renders)
//
// We wrap the server message so we can also carry a local status
// (sending / sent / failed) and a temporary id for optimistic updates.

struct ChatItem {
    var id: String
    let senderId: String
    let senderName: String
    let senderImage: String?
    var content: String?          // make optional (image-only messages have no text)
    let createdAt: Date
    var status: MessageStatus
    var messageType: Int          // 1 = text, 2 = image
    var imageURL: String?
    var localImage: UIImage?
    var isMine: Bool {
        senderId == (User.curentUser?.id ?? "")
    }
}

extension ChatItem {

    init(message: ChatMessage) {
        self.id          = message.id
        self.senderId    = message.senderId ?? message.sender?.id ?? ""
        self.senderName  = message.sender?.name ?? ""
        self.senderImage = message.sender?.profileImage
        self.createdAt   = ChatDate.parse(message.createdAt)
        self.status      = .sent

        // ✅ Only signal is fileUrl — contentType/messageType are always nil
        let isImage = message.fileUrl != nil
        self.messageType = isImage ? 2 : 1

        if isImage {
            self.content  = nil
            self.imageURL = message.fileUrl   // direct full URL, no fallback needed
        } else {
            self.content  = message.content ?? ""
            self.imageURL = nil
        }
    }
    
    static func temporary(content: String, senderId: String) -> ChatItem {
        ChatItem(
            id:          "temp-\(UUID().uuidString)",
            senderId:    senderId,
            senderName:  "",
            senderImage: nil,
            content:     content,
            createdAt:   Date(),
            status:      .sending,
            messageType: 1
        )
    }

    static func temporaryImage(localImage: UIImage, senderId: String) -> ChatItem {
        ChatItem(
            id:          "temp-\(UUID().uuidString)",
            senderId:    senderId,
            senderName:  "",
            senderImage: nil,
            content:     nil,
            createdAt:   Date(),
            status:      .sending,
            messageType: 2,
            localImage:  localImage
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
