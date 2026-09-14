//
//  ChatImageLoader.swift
//  TravelDate
//
//  Tiny cached image loader for avatars. Replace with your existing
//  `loadImage(_:url:)` if you'd rather keep one loader app-wide.
//
//  CHANGED: URL resolution now goes through the single ChatMediaURL
//  helper instead of hand-rolling "does this string contain
//  googleusercontent.com" checks here — this loader used to be the only
//  place in Chat/ that got Google avatar URLs right; everywhere else
//  (ChatMessageCell's avatar load, ChatHeaderView) either force-prefixed
//  APiConstant.base onto an already-absolute URL or duplicated this same
//  "is it Google" special case. One resolver now, used everywhere.
//
//  Also: the cache was dead code before (read was commented out, so
//  every avatar re-downloaded on every reuse). Re-enabled.
//

import UIKit

enum ChatImageLoader {

    private static let cache = NSCache<NSURL, UIImage>()

    /// `rawURLString` may be a relative API path or an already-absolute
    /// URL (Google profile photo, CDN link, etc.) — resolved centrally.
    static func load(rawURLString: String, into imageView: UIImageView) {
        guard let url = ChatMediaURL.resolved(rawURLString) else { return }
        load(url: url, into: imageView)
    }

    static func load(url: URL, into imageView: UIImageView) {
        if let cached = cache.object(forKey: url as NSURL) {
            imageView.image = cached
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            cache.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async { imageView.image = image }
        }.resume()
    }
}
