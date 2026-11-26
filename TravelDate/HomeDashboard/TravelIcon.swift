
//
//  TravelStyleIcon.swift
//  TravelDate
//
//  Single source of truth for mapping the comma-separated `travelStyle`
//  string (e.g. "Cultural Traveler, Partygoer") to icons in Assets.xcassets.
//  Used by MatchCardView (swipe cards) and HomeViewController (trip header).
//

import UIKit

enum TravelStyleIcon: CaseIterable {
    case cultural
    case partygoer
    case adventure
    case leisure

    /// Image name in Assets.xcassets (existing asset names, typos included).
    var assetName: String {
        switch self {
        case .cultural:  return "imgClutral"
        case .partygoer: return "imgPartygoeres"
        case .adventure: return "imgAdventure"
        case .leisure:   return "imgLesiures"
        }
    }

    var image: UIImage? { UIImage(named: assetName) }

    /// Lenient match: "Cultural Traveler", "cultural traveller", "Culture",
    /// "Party goer", "Adventure", "Beach", "Leisure Traveler", etc.
    init?(rawStyle: String) {
        let s = rawStyle
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'[]")))
            .lowercased()
        guard !s.isEmpty else { return nil }

        if s.contains("cultur")                         { self = .cultural }
        else if s.contains("party")                     { self = .partygoer }
        else if s.contains("adventur")                  { self = .adventure }
        else if s.contains("leisure") || s.contains("beach") { self = .leisure }
        else { return nil }
    }

    /// Parses the style string. Handles "A, B, C", "A|B", "A;B", "A/B",
    /// new lines and JSON-array strings like ["A","B"].
    /// - Unknown / empty entries are skipped (and logged in DEBUG).
    /// - Duplicates are removed, original order is kept.
    static func icons(from styles: String?) -> [TravelStyleIcon] {
        guard let styles, !styles.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        let separators = CharacterSet(charactersIn: ",|;/\n")
        var result: [TravelStyleIcon] = []
        for part in styles.components(separatedBy: separators) {
            guard let icon = TravelStyleIcon(rawStyle: part) else {
                #if DEBUG
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { print("⚠️ Unknown travel style skipped: '\(trimmed)'") }
                #endif
                continue
            }
            if !result.contains(icon) { result.append(icon) }
        }
        return result
    }
}
//
//  PremiumAccess.swift
//  TravelDate
//
//  One place that decides whether the current user has premium access.
//  Built only on the existing sources: `User.curentUser.isSubscriptionByAdmin`
//  and the existing `hasPaidSubscription` already used by every screen.
//

import UIKit

extension BaseClassVc {

    /// True if the admin granted a subscription or the user has an active paid one.
    var hasPremiumAccess: Bool {
        if User.curentUser?.isSubscriptionByAdmin == 1 { return true }
        return hasPaidSubscription
    }

    /// Re-syncs the subscription status through the existing presenter
    /// (same call HomeViewController makes), then calls back on the main thread.
    func refreshPremiumStatus(completion: @escaping () -> Void) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            DispatchQueue.main.async { completion() }
            return
        }
        Task {
            await appDelegate.subscriptionPresenter?.refreshSubscriptionStatus()
            await MainActor.run { completion() }
        }
    }
}
