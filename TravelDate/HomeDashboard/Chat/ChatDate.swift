//
//  ChatDate.swift
//  TravelDate
//
//  Small date helper: parse ISO strings + format for bubbles and sections.
//

import Foundation

enum ChatDate {

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Parse a server ISO string. Falls back to "now" if it can't parse.
    static func parse(_ string: String?) -> Date {
        guard let string else { return Date() }
        return iso.date(from: string) ?? isoNoFraction.date(from: string) ?? Date()
    }

    /// "10:32 AM" — shown under each bubble.
    static func bubbleTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    /// "Today" / "Yesterday" / "May 24, 2026" — shown as a section header.
    static func sectionTitle(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    /// Key used to group messages into day-sections.
    static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
