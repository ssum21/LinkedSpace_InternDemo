//
//  Message.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/31/25.
//

// Message.swift
import Foundation

class Message: Identifiable, Hashable, Equatable {
    let id = UUID()
    let role: Message.Role
    var content: String
    init(role: Message.Role, content: String) { self.role = role; self.content = content }
    enum Role { case system, user, assistant }
    static func == (lhs: Message, rhs: Message) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func system(_ content: String) -> Message { Message(role: .system, content: content) }
    static func user(_ content: String) -> Message { Message(role: .user, content: content) }
    static func assistant(_ content: String) -> Message { Message(role: .assistant, content: content) }
}
