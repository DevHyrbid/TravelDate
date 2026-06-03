//
//  ChatInputView.swift
//  TravelDate
//
//  Bottom input bar matching the screenshot:
//  rounded pill text field + emoji + attach + orange circular send button.
//

import UIKit

final class ChatInputView: UIView {

    // MARK: - Callbacks
    var onSend: ((String) -> Void)?
    var onAttach: (() -> Void)?

    // MARK: - Views
    private let container   = UIView()
    private let textView    = UITextView()
    private let placeholder = UILabel()
    private let emojiButton  = UIButton(type: .system)
    private let attachButton = UIButton(type: .system)
    private let sendButton   = UIButton(type: .system)

    private var heightConstraint: NSLayoutConstraint!
    private let maxTextHeight: CGFloat = 100

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - Setup

    private func setupViews() {
        // Pill container
        container.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        container.layer.cornerRadius = 24
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        // Text view
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = UIFont(name: "Poppins-Regular", size: 15) ?? .systemFont(ofSize: 15)
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textView)

        // Placeholder
        placeholder.text = "Type a message..."
        placeholder.textColor = UIColor.white.withAlphaComponent(0.4)
        placeholder.font = UIFont(name: "Poppins-Regular", size: 15) ?? .systemFont(ofSize: 15)
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(placeholder)

        // Emoji + attach (inside pill)
        emojiButton.setImage(UIImage(systemName: "face.smiling"), for: .normal)
        emojiButton.tintColor = UIColor.white.withAlphaComponent(0.6)
        emojiButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emojiButton)

        attachButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachButton.tintColor = UIColor.white.withAlphaComponent(0.6)
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
        attachButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(attachButton)

        // Send button (orange circle)
        sendButton.backgroundColor = UIColor.themeOrange
        sendButton.tintColor = .white
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.layer.cornerRadius = 24
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sendButton)

        heightConstraint = container.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            container.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            heightConstraint,

            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            textView.trailingAnchor.constraint(equalTo: emojiButton.leadingAnchor, constant: -4),

            placeholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 4),
            placeholder.centerYAnchor.constraint(equalTo: textView.centerYAnchor),

            emojiButton.trailingAnchor.constraint(equalTo: attachButton.leadingAnchor, constant: -4),
            emojiButton.centerYAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
            emojiButton.widthAnchor.constraint(equalToConstant: 28),

            attachButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            attachButton.centerYAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
            attachButton.widthAnchor.constraint(equalToConstant: 28),

            sendButton.leadingAnchor.constraint(equalTo: container.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 48),
            sendButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    // MARK: - Actions

    @objc private func sendTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onSend?(text)
        textView.text = ""
        textViewDidChange(textView)   // reset height + placeholder
    }

    @objc private func attachTapped() { onAttach?() }

    func dismissKeyboard() { textView.resignFirstResponder() }
}

// MARK: - UITextViewDelegate (auto-grow + placeholder)

extension ChatInputView: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        placeholder.isHidden = !textView.text.isEmpty

        let size = textView.sizeThatFits(
            CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude)
        )
        let newHeight = min(max(48, size.height), maxTextHeight)
        heightConstraint.constant = newHeight
        textView.isScrollEnabled = size.height > maxTextHeight
    }
}
