// AI Wrapper SwiftUI
// Created by Adam Lyttle on 7/9/2024

// Make cool stuff and share your build with me:

//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import Foundation
import SwiftUI

class ChatModel: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var messages: [ChatMessage] = []
    @Published var isSending: Bool = false
    @Published var title: String? = nil
    @Published var date: Date
    @Published var maxMessagesPerDay: Int = 5
    @Published var currentDayMessageCount: Int = 0
    @Published var lastMessageDate: Date?
    @Published var maxMessagesReached: Bool = false
    
    // Update this to your proxy endpoint
    private let location = "https://thedropout.club/api/openai_proxy"
    
    private let sharedSecretKey: String?

    enum CodingKeys: String, CodingKey {
        case id
        case messages
        case isSending
        case title
        case date
    }

    init(id: UUID = UUID(), messages: [ChatMessage] = [], isSending: Bool = false, title: String? = nil, date: Date = Date()) {
        self.id = id
        self.messages = messages
        self.isSending = isSending
        self.title = title
        self.date = date
        self.maxMessagesPerDay = 10
        self.currentDayMessageCount = 0
        self.lastMessageDate = nil
        self.maxMessagesReached = false

        // Initialize sharedSecretKey
        var secretKey: String? = nil

        // Load the shared secret key from Config.plist
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = config["SharedSecretKey"] as? String {
            secretKey = key
        } else {
            print("Warning: SharedSecretKey not found in Config.plist")
        }

        self.sharedSecretKey = secretKey
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        isSending = try container.decode(Bool.self, forKey: .isSending)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        
        // Initialize other properties with default values
        maxMessagesPerDay = 10
        currentDayMessageCount = 0
        lastMessageDate = nil
        maxMessagesReached = false
        
        // Initialize sharedSecretKey
        var secretKey: String? = nil
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = config["SharedSecretKey"] as? String {
            secretKey = key
        } else {
            print("Warning: SharedSecretKey not found in Config.plist")
        }
        sharedSecretKey = secretKey
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(messages, forKey: .messages)
        try container.encode(isSending, forKey: .isSending)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
    }
    
    var messageData: String? {
        // Convert ChatModel instance to JSON
        do {
            let jsonData = try JSONEncoder().encode(self.messages)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                return jsonString
            }
        } catch {
            print("Failed to encode ChatModel to JSON: \(error)")
        }
        return nil
    }
    
    func generateTitle(completion: @escaping (String?) -> Void) {
        let titlePrompt = "Pick a food item from the conversation to label this, use only the food item (or list of food items) as the label:"
        let messages = self.messages + [ChatMessage(role: .user, message: titlePrompt)]
        
        let parameters: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.message ?? ""] }
        ]
        
        let connectionRequest = ConnectionRequest()
        connectionRequest.fetchData(location, parameters: parameters, sharedSecretKey: sharedSecretKey) { data, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: String],
               let content = message["content"] {
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                completion(nil)
            }
        }
    }
    
    func sendMessage(role: MessageRole = .user, message: String? = nil, image: UIImage? = nil) {
        if currentDayMessageCount >= maxMessagesPerDay {
            if !maxMessagesReached {
                maxMessagesReached = true
                appendMessage(role: .system, message: "You've reached the maximum number of messages for today. Please try again tomorrow.")
            }
            return
        }
        
        appendMessage(role: role, message: message, image: image)
        self.isSending = true
        
        currentDayMessageCount += 1
        lastMessageDate = Date()
        
        let messages = self.messages.map { chatMessage -> [String: Any] in
            var messageDict: [String: Any] = [
                "role": chatMessage.role.rawValue,
                "message": chatMessage.message ?? ""
            ]
            
            if let image = chatMessage.image,
               let resizedImage = resizedImage(image),
               let imageData = resizedImage.jpegData(compressionQuality: 0.4) {
                let base64Image = imageData.base64EncodedString()
                messageDict["image"] = base64Image
            }
            
            return messageDict
        }
        
        let parameters: [String: Any] = [
            "messages": JSON.stringify(messages)
        ]
        
        let connectionRequest = ConnectionRequest()
        connectionRequest.fetchData(location, parameters: parameters, sharedSecretKey: sharedSecretKey) { [weak self] data, error in
            DispatchQueue.main.async {
                self?.isSending = false
                
                if let error = error {
                    print("Error: \(error)")
                    self?.appendMessage(role: .system, message: "Error: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    self?.appendMessage(role: .system, message: "No data received")
                    return
                }
                
                // Try to parse as JSON first
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: String],
                       let content = message["content"] {
                        self?.appendMessage(role: .system, message: content)
                    } else {
                        // If not JSON, treat as plain text
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Plain text response: \(responseString)")
                            self?.appendMessage(role: .system, message: responseString)
                        } else {
                            self?.appendMessage(role: .system, message: "Received response in unknown format")
                        }
                    }
                } catch {
                    // If JSON parsing fails, treat as plain text
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Plain text response: \(responseString)")
                        self?.appendMessage(role: .system, message: responseString)
                    } else {
                        print("Error parsing response: \(error)")
                        self?.appendMessage(role: .system, message: "Error parsing response: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func appendMessage(role: MessageRole, message: String? = nil, image: UIImage? = nil) {
        self.date = Date()
        messages.append(ChatMessage(
            role: role,
            message: message,
            image: image
        ))
    }
    
    private func canSendMessage() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastDate = lastMessageDate,
           calendar.isDate(lastDate, inSameDayAs: now) {
            return currentDayMessageCount < maxMessagesPerDay
        } else {
            // It's a new day, reset the count and maxMessagesReached flag
            currentDayMessageCount = 0
            maxMessagesReached = false
            lastMessageDate = now
            return true
        }
    }
}

private func resizedImage(_ image: UIImage) -> UIImage? {
    if image.size.height > 1000 {
        return image.resized(toHeight: 1000)
    } else {
        return image
    }
}

enum MessageRole: String, Codable {
    case user
    case system
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    var message: String?
    var image: UIImage?
    
    enum CodingKeys: String, CodingKey {
        case id
        case role
        case message
        case image
    }

    init(id: UUID = UUID(), role: MessageRole, message: String?, image: UIImage? = nil) {
        self.id = id
        self.role = role
        self.message = message
        self.image = image //?.jpegData(compressionQuality: 1.0)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(MessageRole.self, forKey: .role)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        /*if let imageData = try container.decodeIfPresent(Data.self, forKey: .image) ?? nil {
            image = UIImage(data: imageData)
        }*/
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(role, forKey: .role)
        try container.encode(message, forKey: .message)
        //try container.encode(image?.jpegData(compressionQuality: 1.0), forKey: .image)
        
        if let image = self.image,
           let resizedImage = self.resizedImage(image),
           let resizedImageData = resizedImage.jpegData(compressionQuality: 0.4) {
            let imageData = self.encodeToPercentEncodedString(resizedImageData)
            try container.encode(imageData, forKey: .image)
        }
        
    }

    private func resizedImage(_ image: UIImage) -> UIImage? {
        //increase size of image here:
        if image.size.height > 1000 {
            return image.resized(toHeight: 1000)
        }
        else {
            return image
        }
    }
    
    
    private func encodeToPercentEncodedString(_ data: Data) -> String {
        return data.map { String(format: "%%%02hhX", $0) }.joined()
    }

    


}

// Helper function to stringify JSON
struct JSON {
    static func stringify(_ value: Any) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: value, options: [])
        return String(data: jsonData, encoding: .utf8)!
    }
}

// Modify ConnectionRequest to work with the proxy
extension ConnectionRequest {
    func fetchData(_ urlString: String, parameters: [String: Any], sharedSecretKey: String?, completion: @escaping (Data?, String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let sharedSecretKey = sharedSecretKey {
            request.setValue(sharedSecretKey, forHTTPHeaderField: "X-Secret-Key")
        }
        
        let body = createMultipartFormData(parameters: parameters, boundary: boundary)
        request.httpBody = body
        
        // Print out all request headers
        print("Request Headers:")
        request.allHTTPHeaderFields?.forEach { key, value in
            print("\(key): \(value)")
        }
        
        // Print out the raw request body
        if let bodyString = String(data: body, encoding: .utf8) {
            print("Raw request body:")
            print(bodyString)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                completion(nil, "No data received")
                return
            }
            
            completion(data, nil)
        }.resume()
    }
    
    private func createMultipartFormData(parameters: [String: Any], boundary: String) -> Data {
        var body = Data()
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}