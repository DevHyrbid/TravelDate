//
//  ChatVideoThumbnailLoader.swift
//  TravelDate
//
//  NEW FILE — nothing existing was touched to add this.
//
//  Mirrors ChatImageLoader's cache-by-URL pattern, but generates the
//  thumbnail itself via AVAssetImageGenerator instead of downloading an
//  image, since the API doesn't return a separate thumbnail for videos
//  (same "fileUrl is the only signal" situation as ChatModels.swift).
//  Works for both a remote fileUrl (server video) and a local file URL
//  (freshly picked video, before upload finishes).
//

import UIKit
import AVFoundation

enum ChatVideoThumbnailLoader {

    private static let cache = NSCache<NSString, UIImage>()

    /// `urlString` may be a relative path (resolved against APiConstant.base,
    /// same convention as ChatImageLoader) or an absolute URL.
    static func loadRemote(_ urlString: String, into imageView: UIImageView) {
        if let cached = cache.object(forKey: urlString as NSString) {
            imageView.image = cached
            return
        }
        guard let url = resolvedURL(from: urlString) else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let thumbnail = generateThumbnail(for: url) else { return }
            cache.setObject(thumbnail, forKey: urlString as NSString)
            DispatchQueue.main.async { imageView.image = thumbnail }
        }
    }

    /// For a locally-picked video (before it's uploaded) — synchronous-feeling
    /// but still generated off the main thread; call from the picker callback.
    static func loadLocal(_ fileURL: URL, into imageView: UIImageView) {
        let key = fileURL.absoluteString as NSString
        if let cached = cache.object(forKey: key) {
            imageView.image = cached
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            guard let thumbnail = generateThumbnail(for: fileURL) else { return }
            cache.setObject(thumbnail, forKey: key)
            DispatchQueue.main.async { imageView.image = thumbnail }
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
