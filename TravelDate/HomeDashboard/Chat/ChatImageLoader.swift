//
//  ChatImageLoader.swift
//  TravelDate
//
//  Tiny cached image loader for avatars. Replace with your existing
//  `loadImage(_:url:)` if you'd rather keep one loader app-wide.
//

import UIKit

enum ChatImageLoader {

    private static let cache = NSCache<NSURL, UIImage>()

    static func load(url: URL, into imageView: UIImageView) {
        
        
//        if let cached = cache.object(forKey: url as NSURL) {
//            imageView.image = cached
//            return
//        }
        var  urlStr = url
        if url.absoluteString.contains("https://lh3.googleusercontent.com") {
            urlStr =  URL(string: url.absoluteString)!
        } else {
            urlStr = URL(string:APiConstant.base + url.absoluteString)!
        }
        print(urlStr,"GOOGLE LINK HERE CALLED")
        URLSession.shared.dataTask(with: urlStr) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            cache.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async { imageView.image = image }
        }.resume()
    }
}
