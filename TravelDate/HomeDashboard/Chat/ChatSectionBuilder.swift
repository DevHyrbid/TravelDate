//
//  ChatSectionBuilder.swift
//  TravelDate
//
//  Turns a flat [ChatItem] into day-grouped sections for the table.
//

import Foundation

struct ChatSection {
    let title: String        // "Today", "Yesterday", "May 24, 2026"
    var items: [ChatItem]
}

enum ChatSectionBuilder {

    /// Input must be sorted oldest → newest.
    static func build(from items: [ChatItem]) -> [ChatSection] {
        guard !items.isEmpty else { return [] }

        var sections: [ChatSection] = []
        var currentKey = ""

        for item in items {
            let key = ChatDate.dayKey(item.createdAt)
            if key != currentKey {
                currentKey = key
                sections.append(
                    ChatSection(title: ChatDate.sectionTitle(item.createdAt), items: [item])
                )
            } else {
                sections[sections.count - 1].items.append(item)
            }
        }
        return sections
    }
}
