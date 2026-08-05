//
//  ImagePreview .swift
//  TravelDate
//
//  Created by Dev CodingZone on 05/08/26.
//

import UIKit

final class ImagePreviewVC: UIViewController {

    private let image: UIImage

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.image = image
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.95)

        view.addSubview(imageView)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([

            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(closeTapped))
        view.addGestureRecognizer(tap)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        imageView.addGestureRecognizer(pinch)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        switch gesture.state {
        case .began, .changed:
            view.transform = CGAffineTransform(scaleX: gesture.scale, y: gesture.scale)
        default:
            UIView.animate(withDuration: 0.25) {
                view.transform = .identity
            }
        }
    }
}
