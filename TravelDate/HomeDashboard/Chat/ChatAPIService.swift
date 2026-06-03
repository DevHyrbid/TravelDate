//
//  ChatAPIService.swift
//  TravelDate
//
//  All chat networking in one place. APIs only — no sockets.

import Foundation

// MARK: - Endpoints (add these to your APiConstant if you prefer)

enum ChatAPI {
    
    static var baseUrl: String { "http://187.124.251.134:9800/api/v1/" }
    
    static let createRoom  = baseUrl + "api-chat/room"
    static let sendMessage = baseUrl + "api-chat/message"
    
    static func getMessages(roomId: String, page: Int, limit: Int = 20) -> String {
        baseUrl + "api-chat/room/\(roomId)/messages?page=\(page)&limit=\(limit)"
    }
}

// MARK: - Service

final class ChatAPIService {
    
    typealias Completion<T> = (Result<T, Error>) -> Void
    
    // MARK: 1. Create / Get Room
    
    func createRoom(participants: [String],
                    type: ChatRoomType,
                    completion: @escaping Completion<String>) {
        
        let body: [String: Any] = [
            "participants": participants,
            "type": type.rawValue
        ]
        
        request(url: ChatAPI.createRoom,
                method: "POST",
                body: body) { (result: Result<CreateRoomResponse, Error>) in
            switch result {
            case .success(let res):
                if let roomId = res.data?.id {
                    completion(.success(roomId))
                } else {
                    completion(.failure(ChatError.message(res.message ?? "Could not create room")))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    // MARK: 2. Send Message
    
    func sendMessage(roomId: String,
                     content: String,
                     contentType: String = "text",
                     completion: @escaping Completion<ChatMessage>) {
        
        let body: [String: Any] = [
            "roomId": roomId,
            "content": content,
            "contentType": contentType
        ]
        
        request(url: ChatAPI.sendMessage,
                method: "POST",
                body: body) { (result: Result<SendMessageResponse, Error>) in
            switch result {
            case .success(let res):
                if let msg = res.data {
                    completion(.success(msg))
                } else {
                    completion(.failure(ChatError.message(res.message ?? "Send failed")))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    // MARK: 3. Fetch Messages (paginated)
    
    func fetchMessages(roomId: String,
                       page: Int,
                       completion: @escaping Completion<[ChatMessage]>) {
        
        request(url: ChatAPI.getMessages(roomId: roomId, page: page),
                method: "GET",
                body: nil) { (result: Result<MessagesResponse, Error>) in
            switch result {
            case .success(let res):
                completion(.success(res.data ?? []))
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    // MARK: - Core request
    
    private func request<T: Decodable>(url: String,
                                       method: String,
                                       body: [String: Any]?,
                                       completion: @escaping Completion<T>) {
        
        guard let url = URL(string: url) else {
            completion(.failure(ChatError.message("Bad URL")))
            return
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = ChatAuth.bearerToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // ──────────────────────────────────────────────────────────────
        
        if let body = body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        
        
        // MARK: - API REQUEST LOG
        print("\n================ API REQUEST ================")
        print("🌍 URL:", req.url?.absoluteString ?? "")
        print("📌 METHOD:", req.httpMethod ?? "")
        
        if let headers = req.allHTTPHeaderFields {
            print("📦 HEADERS:", headers)
        }
        
        if let bodyData = req.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📨 BODY:", bodyString)
        }
        
        print("================================================\n")
        
        let startTime = Date()
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            
            
            // MARK: - API RESPONSE LOG
            print("\n================ API RESPONSE ================")
            
            let duration = Date().timeIntervalSince(startTime)
            print("⏱ DURATION:", String(format: "%.2f sec", duration))
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 STATUS CODE:", httpResponse.statusCode)
                print("🌍 RESPONSE URL:", httpResponse.url?.absoluteString ?? "")
                
                print("📦 RESPONSE HEADERS:", httpResponse.allHeaderFields)
            }
            
            if let error = error {
                print("❌ ERROR:", error.localizedDescription)
            }
            
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("📨 RESPONSE:", responseString)
            }
            
            print("================================================\n")
            
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(ChatError.message("No data"))); return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                
                print("✅ DECODE SUCCESS:", decoded)
                
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Error

enum ChatError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let m): return m }
    }
}


enum ChatAuth {
    static var bearerToken: String? {
        return UserDefaults.standard.string(forKey: "UserToken")
    }
}


// MARK: - cURL Logger

extension URLRequest {
    
    func curlString() -> String {
        
        guard let url = self.url else { return "" }
        
        var command = "curl \(url.absoluteString)"
        
        if let method = self.httpMethod {
            command += " -X \(method)"
        }
        
        self.allHTTPHeaderFields?.forEach {
            command += " -H '\($0): \($1)'"
        }
        
        if let body = self.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            command += " -d '\(bodyString)'"
        }
        
        return command
    }
}
