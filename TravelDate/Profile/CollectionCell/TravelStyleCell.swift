//
//  ColectionCell.swift
//  TravelDate
//
//  Created by Dev CodingZone on 23/04/26.
//

import UIKit

final class TravelStyleCell: UICollectionViewCell {

    static let identifier = "TravelStyleCell"

    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

     let titleLabel: UILabel = {
        let label = UILabel()
         label.setFont(.medium, size: 14.0)
         label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            // Container fills cell
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Label padding
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
        ])
    }

    // MARK: - Configure
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = "• \(title)"

        
            containerView.layer.borderColor = UIColor.themeOrange.cgColor
            containerView.backgroundColor = UIColor.themeOrange.withAlphaComponent(0.1)
            titleLabel.textColor = .themeOrange
       
    }
}


import UIKit

final class AboutEditView: UIView {

    // MARK: - Callback
    var onSave: ((String) -> Void)?

    // MARK: - UI
    private let dimView = UIView()
    private let containerView = UIView()
    private let textView = UITextView()
    private let saveButton = UIButton(type: .system)

    private var bottomConstraint: NSLayoutConstraint!

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupKeyboardObservers()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear

        // Dim
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimView)

        // Container
        containerView.backgroundColor = UIColor(hex: "#161616")
        containerView.layer.cornerRadius = 24
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // TextView
        textView.backgroundColor = UIColor(hex: "#1A1A1A")
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.layer.cornerRadius = 12
        textView.translatesAutoresizingMaskIntoConstraints = false

        // Button
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = .orange
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 25
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        containerView.addSubview(textView)
        containerView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 400)
        bottomConstraint.isActive = true

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 120),

            saveButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])

        // Tap to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        dimView.addGestureRecognizer(tap)
    }

    // MARK: - Actions
    @objc private func saveTapped() {
        onSave?(textView.text)
        dismiss()
    }

    @objc private func dismiss() {
        bottomConstraint.constant = 400
        UIView.animate(withDuration: 0.3, animations: {
            self.dimView.alpha = 0
            self.layoutIfNeeded()
        }) { _ in
            self.removeFromSuperview()
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardFrame.height

        // Move sheet up
        bottomConstraint.constant = -keyboardHeight - 20

        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        bottomConstraint.constant = -150 // your original position

        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // MARK: - Show
    func present(in view: UIView, text: String?) {
        frame = view.bounds
        view.addSubview(self)

        textView.text = text

        layoutIfNeeded()

        bottomConstraint.constant = -150

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5) {
            self.dimView.alpha = 1
            self.layoutIfNeeded()
        }
    }
}
