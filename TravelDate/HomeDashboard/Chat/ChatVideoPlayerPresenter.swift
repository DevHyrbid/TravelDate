//
//  ChatVideoPlayerPresenter.swift
//  TravelDate
//
//  Deliberately thin: AVPlayerViewController already gives scrubbing,
//  fullscreen, AirPlay, PiP for free.
//
//  CHANGED: URL resolution now goes through ChatMediaURL instead of its
//  own local http/https-prefix check, so video playback resolves URLs
//  exactly the same way the thumbnail loader and image loader do — a
//  video whose fileUrl is an absolute CDN link is never mangled.
//

import UIKit
import AVKit

enum ChatVideoPlayerPresenter {

    /// `urlString` may be remote (server fileUrl) — resolved the same way
    /// as everywhere else in Chat/. Silently does nothing if the URL
    /// can't be resolved (never presents a player with a nil/garbage URL).
    static func present(remoteURLString urlString: String, from presenter: UIViewController) {
        guard let url = ChatMediaURL.resolved(urlString) else { return }
        present(url: url, from: presenter)
    }

    /// For a locally-picked video that hasn't finished uploading yet.
    static func present(localURL: URL, from presenter: UIViewController) {
        present(url: localURL, from: presenter)
    }

    private static func present(url: URL, from presenter: UIViewController) {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        // AVPlayerViewController retains its player; presenter retains the
        // controller for as long as it's on screen — no extra strong refs
        // needed here to keep playback alive.
        presenter.present(controller, animated: true) {
            player.play()
        }
    }
}
