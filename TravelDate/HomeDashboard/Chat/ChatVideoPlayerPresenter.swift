//
//  ChatVideoPlayerPresenter.swift
//  TravelDate
//
//  NEW FILE — nothing existing was touched to add this.
//
//  Deliberately thin: AVPlayerViewController already gives scrubbing,
//  fullscreen, AirPlay, PiP for free. Resolves relative-vs-absolute URL
//  the same way ChatImageLoader/ChatVideoThumbnailLoader do.
//

import UIKit
import AVKit

enum ChatVideoPlayerPresenter {

    /// `urlString` may be remote (server fileUrl) — resolved the same way
    /// as everywhere else in Chat/.
    static func present(remoteURLString urlString: String, from presenter: UIViewController) {
        let resolved: URL?
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            resolved = URL(string: urlString)
        } else {
            resolved = URL(string: APiConstant.base + urlString)
        }
        guard let url = resolved else { return }
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
        presenter.present(controller, animated: true) {
            player.play()
        }
    }
}
