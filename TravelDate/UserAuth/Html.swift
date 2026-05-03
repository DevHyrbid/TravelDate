
import UIKit
import WebKit

class VoiceTestViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Configure WKWebView
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        loadHTML()
    }

    private func loadHTML() {
        // OPTION 1: Load from URL (recommended)
        if let filePath = Bundle.main.path(forResource: "index", ofType: "html") {
                    let url = URL(fileURLWithPath: filePath)
                    webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                }

        // OPTION 2: Load local HTML file
        /*
        if let filePath = Bundle.main.path(forResource: "index", ofType: "html") {
            let url = URL(fileURLWithPath: filePath)
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        */
    }
}
