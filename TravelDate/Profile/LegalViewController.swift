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

    // MARK: - Colors

    private let backgroundColor = UIColor(
        red: 13.0 / 255.0,
        green: 11.0 / 255.0,
        blue: 10.0 / 255.0,
        alpha: 1.0
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Force this screen to use dark appearance
        overrideUserInterfaceStyle = .dark

        setupNavigationBar()
        setupCloseButton()
        setupWebView()
        loadHTML()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        self.title = "EULA Terms"
        view.backgroundColor = backgroundColor

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = backgroundColor
        appearance.shadowColor = .clear

        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(
                ofSize: 17,
                weight: .semibold
            )
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        }

        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false
    }

    // MARK: - Close Button

    private func setupCloseButton() {

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )

        closeButton.tintColor = .white

        navigationItem.rightBarButtonItem = closeButton
    }

    @objc
    private func closeTapped() {

        if let navigationController = navigationController,
           navigationController.presentingViewController != nil {

            navigationController.dismiss(animated: true)

        } else {

            dismiss(animated: true)
        }
    }

    // MARK: - WebView

    private func setupWebView() {

        let configuration = WKWebViewConfiguration()



        webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        webView.translatesAutoresizingMaskIntoConstraints = false

        webView.backgroundColor = backgroundColor
        webView.isOpaque = false

        // Force dark appearance inside WKWebView
        webView.overrideUserInterfaceStyle = .dark

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

        webView.scrollView.backgroundColor = backgroundColor
        webView.scrollView.alwaysBounceVertical = false

        // Prevent the white overscroll area
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }

    // MARK: - Load HTML

    private func loadHTML() {

        guard let url = Bundle.main.url(
            forResource: "legal",
            withExtension: "html"
        ) else {

            print("❌ legal.html not found in Bundle")
            return
        }

        webView.loadFileURL(
            url,
            allowingReadAccessTo: url.deletingLastPathComponent()
        )
    }
}

// MARK: - WKNavigationDelegate

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

        // Open external links outside the WebView
        if navigationAction.navigationType == .linkActivated {

            if UIApplication.shared.canOpenURL(url) {

                UIApplication.shared.open(
                    url,
                    options: [:],
                    completionHandler: nil
                )
            }

            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
