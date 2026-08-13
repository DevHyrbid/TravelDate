//
//  ChatVideoThumbnailLoader.swift
//  TravelDate
//
//  Mirrors ChatImageLoader's cache-by-URL pattern, but generates the
//  thumbnail itself via AVAssetImageGenerator instead of downloading an
//  image, since the API doesn't return a separate thumbnail for videos
//  (same "fileUrl is the only signal" situation as ChatModels.swift).
//  Works for both a remote fileUrl (server video) and a local file URL
//  (freshly picked video, before upload finishes).
//
//  Two call styles are supported:
//   - into:imageView   — fire-and-forget, sets the image view directly.
//   - completion:       — hands you the UIImage (or nil on failure) so the
//                         caller can size the attachment correctly and can
//                         ignore the result if the cell has been reused
//                         (ChatMessageCell does this via its loadToken).
//

import UIKit
import AVFoundation

enum ChatVideoThumbnailLoader {

    private static let cache = NSCache<NSString, UIImage>()

    // MARK: - into:imageView (fire-and-forget)

    /// `urlString` may be a relative path (resolved against APiConstant.base,
    /// same convention as ChatImageLoader) or an absolute URL.
    static func loadRemote(_ urlString: String, into imageView: UIImageView) {
        loadRemote(urlString) { thumbnail in
            guard let thumbnail else { return }
            imageView.image = thumbnail
        }
    }

    /// For a locally-picked video (before it's uploaded).
    static func loadLocal(_ fileURL: URL, into imageView: UIImageView) {
        loadLocal(fileURL) { thumbnail in
            guard let thumbnail else { return }
            imageView.image = thumbnail
        }
    }

    // MARK: - completion-based (cancellation-safe; use in table/collection cells)

    /// Calls `completion` on the main thread with the generated thumbnail,
    /// or nil on failure. Caller is responsible for checking whether the
    /// requesting cell/view is still current before applying the result.
    static func loadRemote(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        if let cached = cache.object(forKey: urlString as NSString) {
            DispatchQueue.main.async { completion(cached) }
            return
        }
        guard let url = resolvedURL(from: urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = generateThumbnail(for: url)
            if let thumbnail {
                cache.setObject(thumbnail, forKey: urlString as NSString)
            }
            DispatchQueue.main.async { completion(thumbnail) }
        }
    }

    static func loadLocal(_ fileURL: URL, completion: @escaping (UIImage?) -> Void) {
        let key = fileURL.absoluteString as NSString
        if let cached = cache.object(forKey: key) {
            DispatchQueue.main.async { completion(cached) }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = generateThumbnail(for: fileURL)
            if let thumbnail {
                cache.setObject(thumbnail, forKey: key)
            }
            DispatchQueue.main.async { completion(thumbnail) }
        }
    }

    /// Synchronous variant used when you need the UIImage immediately
    /// (e.g. building the optimistic `ChatItem.temporaryVideo` before the
    /// cell has even been created). Safe to call off the main thread.
    static func generateThumbnailSync(for fileURL: URL) -> UIImage? {
        generateThumbnail(for: fileURL)
    }

    /// Duration in whole seconds for a local video file, used for the
    /// optimistic bubble's duration label before the server confirms.
    static func duration(for fileURL: URL) -> Int? {
        let asset = AVURLAsset(url: fileURL)
        let seconds = CMTimeGetSeconds(asset.duration)
        guard seconds.isFinite, seconds >= 0 else { return nil }
        return Int(seconds)
    }

    // MARK: - Private

    private static func generateThumbnail(for url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 440, height: 440) // 2x @220pt bubble width

        do {
            let cgImage = try generator.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }

    private static func resolvedURL(from raw: String) -> URL? {
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            return URL(string: raw)
        }
        return URL(string: APiConstant.base + raw)
    }
}
