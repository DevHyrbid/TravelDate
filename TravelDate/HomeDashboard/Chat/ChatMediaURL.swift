//
//  ChatMediaURL.swift
//  TravelDate
//
//  NEW FILE.
//
//  Root-cause fix for one of the bugs in the audit: there were three
//  different, inconsistent "build the real URL" implementations spread
//  across ChatImageLoader, ChatMessageCell, ChatHeaderView, and
//  ChatVideoThumbnailLoader/ChatVideoPlayerPresenter — some checked for
//  an absolute URL first, some didn't (and would have produced
//  "https://api.tripsapp.io/api/v1/https://cdn.example.com/x.jpg" for an
//  already-absolute CDN/Google URL).
//
//  Every image/video/avatar loader in Chat/ now routes through this one
//  function instead.
//

import Foundation

enum ChatMediaURL {

    /// Resolves `raw` into a loadable URL.
    ///
    /// - Already-absolute `http://` / `https://` URLs (CDN links, Google
    ///   profile photos, signed URLs with query params, etc.) are
    ///   returned as-is — never re-prefixed with the API base.
    /// - Anything else is treated as a server-relative path (e.g.
    ///   `/uploads/chat/image.jpg`) and prefixed with `APiConstant.base`,
    ///   normalizing the slash between the two so we never produce a
    ///   double slash or a missing one.
    static func resolved(_ raw: String?) -> URL? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }

        let base = APiConstant.base
        switch (trimmed.hasPrefix("/"), base.hasSuffix("/")) {
        case (true, true):
            return URL(string: base + trimmed.dropFirst())
        case (false, false):
            return URL(string: base + "/" + trimmed)
        default:
            return URL(string: base + trimmed)
        }
    }
}
