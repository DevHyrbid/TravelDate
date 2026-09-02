//
//  LegalVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 02/09/26.
//

import UIKit
import WebKit

final class LegalViewController: UIViewController {

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Legal"
        view.backgroundColor = .systemBackground
        setupCloseButton()
        setupWebView()
        loadHTML()
    }

    
    private func setupCloseButton() {

        let closeButton = UIBarButtonItem(
            image: UIImage(
                systemName: "xmark"
            ),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )

        closeButton.tintColor = .label

        navigationItem.rightBarButtonItem = closeButton
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    private func setupWebView() {

        let configuration = WKWebViewConfiguration()

        webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            webView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            webView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            webView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])

        webView.navigationDelegate = self

        webView.isOpaque = false
        webView.backgroundColor = .clear

        // Prevent bounce if you want the page to feel more like
        // a native app screen.
        webView.scrollView.alwaysBounceVertical = false
    }

    private func loadHTML() {

        guard let url = Bundle.main.url(
            forResource: "legal",
            withExtension: "html"
        ) else {
            print("❌ legal.html not found")
            return
        }

        webView.loadFileURL(
            url,
            allowingReadAccessTo: url.deletingLastPathComponent()
        )
    }
}

extension LegalViewController: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // External links:
        if navigationAction.navigationType == .linkActivated {

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }

            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
