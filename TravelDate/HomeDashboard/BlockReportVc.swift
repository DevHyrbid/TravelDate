//
//  BlockReportVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 07/07/26.

//  Single popup class that handles BOTH flows:
//  1. Block confirmation -> "Are you sure you want to block?" + Block/Cancel
//  2. Report -> radio button list (standard EULA reasons) + "Other" text field + Submit
//
//  Programmatic UIKit, no Storyboards/XIBs.
//

import UIKit

// MARK: - Mode

enum BlockReportPopupMode {
    case block(username: String)
    case report(username: String)
}

// MARK: - Report Reason Model

struct ReportReason {
    let title: String
    let isOtherOption: Bool
}

// MARK: - Delegate

protocol BlockReportPopupDelegate: AnyObject {
    func blockReportPopup(_ popup: BlockReportPopupViewController, didConfirmBlockUser username: String)
    func blockReportPopup(_ popup: BlockReportPopupViewController, didSubmitReportForUser username: String, reason: String, otherText: String?)
    func blockReportPopupDidCancel(_ popup: BlockReportPopupViewController)
}

// Make delegate methods optional-feeling without @objc
extension BlockReportPopupDelegate {
    func blockReportPopup(_ popup: BlockReportPopupViewController, didConfirmBlockUser username: String) {}
    func blockReportPopup(_ popup: BlockReportPopupViewController, didSubmitReportForUser username: String, reason: String, otherText: String?) {}
    func blockReportPopupDidCancel(_ popup: BlockReportPopupViewController) {}
}

final class BlockReportPopupViewController: UIViewController {

    // MARK: - Public

    weak var delegate: BlockReportPopupDelegate?

    // MARK: - Config

    private let mode: BlockReportPopupMode

    private let reportReasons: [ReportReason] = [
        ReportReason(title: "Spam or scam", isOtherOption: false),
        ReportReason(title: "Inappropriate photos", isOtherOption: false),
        ReportReason(title: "Harassment or bullying", isOtherOption: false),
        ReportReason(title: "Fake profile / impersonation", isOtherOption: false),
        ReportReason(title: "Underage user", isOtherOption: false),
        ReportReason(title: "Other", isOtherOption: true)
    ]

    private var selectedReasonIndex: Int? = nil

    // MARK: - UI - Shared

    private let dimmingView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0
        return view
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.11, alpha: 1.0)
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    private let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        view.layer.cornerRadius = 2.5
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(white: 1.0, alpha: 0.6)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private var cardBottomConstraint: NSLayoutConstraint!

    // MARK: - UI - Block Mode

    private let blockButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private lazy var blockButton: UIButton = {
        let button = makeGradientButton(title: "Block", isDestructive: true)
        button.addTarget(self, action: #selector(didTapBlock), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        return button
    }()

    // MARK: - UI - Report Mode

    private let reasonsTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.isScrollEnabled = false
        table.register(ReportReasonCell.self, forCellReuseIdentifier: ReportReasonCell.reuseIdentifier)
        return table
    }()

    private var reasonsTableHeightConstraint: NSLayoutConstraint!

    private let otherTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        tv.textColor = .white
        tv.font = .systemFont(ofSize: 14)
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tv.isHidden = true
        return tv
    }()

    private let otherPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Tell us more (optional)"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(white: 1.0, alpha: 0.35)
        label.isHidden = true
        return label
    }()

    private lazy var submitButton: UIButton = {
        let button = makeGradientButton(title: "Submit", isDestructive: false)
        button.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    // MARK: - Init

    init(mode: BlockReportPopupMode, delegate: BlockReportPopupDelegate? = nil) {
        self.mode = mode
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDimmingView()
        setupCard()
        configureContent()

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView))
        dimmingView.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.25) {
            self.dimmingView.alpha = 1
        }
        cardBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Setup

    private func setupDimmingView() {
        view.backgroundColor = .clear
        view.addSubview(dimmingView)
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCard() {
        view.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        cardBottomConstraint = cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 400)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            cardBottomConstraint
        ])

        cardView.addSubview(handleBar)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)

        handleBar.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            handleBar.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            handleBar.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20)
        ])
    }

    private func configureContent() {
        switch mode {
        case .block(let username):
            titleLabel.text = "Block @\(username)?"
            subtitleLabel.text = "Are you sure you want to block this user? They won't be able to message you or see your profile."
            setupBlockUI()
        case .report(let username):
            titleLabel.text = "Report @\(username)"
            subtitleLabel.text = "Select a reason. Your report is anonymous."
            setupReportUI()
        }
    }

    // MARK: - Block UI

    private func setupBlockUI() {
        blockButtonsStack.addArrangedSubview(blockButton)
        blockButtonsStack.addArrangedSubview(cancelButton)

        cardView.addSubview(blockButtonsStack)
        blockButtonsStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            blockButtonsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            blockButtonsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            blockButtonsStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            blockButtonsStack.bottomAnchor.constraint(equalTo: cardView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - Report UI

    private func setupReportUI() {
        reasonsTableView.dataSource = self
        reasonsTableView.delegate = self

        cardView.addSubview(reasonsTableView)
        cardView.addSubview(otherTextView)
        cardView.addSubview(otherPlaceholderLabel)
        cardView.addSubview(submitButton)

        reasonsTableView.translatesAutoresizingMaskIntoConstraints = false
        otherTextView.translatesAutoresizingMaskIntoConstraints = false
        otherPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false

        reasonsTableHeightConstraint = reasonsTableView.heightAnchor.constraint(equalToConstant: CGFloat(reportReasons.count) * 50)

        NSLayoutConstraint.activate([
            reasonsTableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            reasonsTableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            reasonsTableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            reasonsTableHeightConstraint,

            otherTextView.topAnchor.constraint(equalTo: reasonsTableView.bottomAnchor, constant: 4),
            otherTextView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            otherTextView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            otherTextView.heightAnchor.constraint(equalToConstant: 80),

            otherPlaceholderLabel.topAnchor.constraint(equalTo: otherTextView.topAnchor, constant: 10),
            otherPlaceholderLabel.leadingAnchor.constraint(equalTo: otherTextView.leadingAnchor, constant: 14),

            submitButton.topAnchor.constraint(equalTo: otherTextView.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            submitButton.bottomAnchor.constraint(equalTo: cardView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        otherTextView.delegate = self
    }

    // MARK: - Helpers

    private func makeGradientButton(title: String, isDestructive: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 14
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let gradient = CAGradientLayer()
        gradient.colors = isDestructive
            ? [UIColor.systemRed.cgColor, UIColor(red: 0.85, green: 0.15, blue: 0.25, alpha: 1).cgColor]
            : [UIColor(red: 0.99, green: 0.29, blue: 0.42, alpha: 1).cgColor, UIColor(red: 0.95, green: 0.45, blue: 0.2, alpha: 1).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.name = "gradientLayer"
        button.layer.insertSublayer(gradient, at: 0)
        button.layoutIfNeeded()

        // Update gradient frame after layout
        DispatchQueue.main.async {
            gradient.frame = button.bounds
        }
        return button
    }

    private func updateSubmitButtonState() {
        let hasSelection = selectedReasonIndex != nil
        submitButton.isEnabled = hasSelection
        UIView.animate(withDuration: 0.2) {
            self.submitButton.alpha = hasSelection ? 1.0 : 0.5
        }
    }

    private func dismissPopup(completion: (() -> Void)? = nil) {
        cardBottomConstraint.constant = 400
        UIView.animate(withDuration: 0.25, animations: {
            self.dimmingView.alpha = 0
            self.view.layoutIfNeeded()
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    // MARK: - Actions

    @objc private func didTapBlock() {
        guard case .block(let username) = mode else { return }
        dismissPopup {
            self.delegate?.blockReportPopup(self, didConfirmBlockUser: username)
        }
    }

    @objc private func didTapCancel() {
        dismissPopup {
            self.delegate?.blockReportPopupDidCancel(self)
        }
    }

    @objc private func didTapDimmingView() {
        dismissPopup {
            self.delegate?.blockReportPopupDidCancel(self)
        }
    }

    @objc private func didTapSubmit() {
        guard case .report(let username) = mode, let index = selectedReasonIndex else { return }
        let reason = reportReasons[index].title
        let otherText = reportReasons[index].isOtherOption ? otherTextView.text : nil
        dismissPopup {
            self.delegate?.blockReportPopup(self, didSubmitReportForUser: username, reason: reason, otherText: otherText)
        }
    }
}

// MARK: - UITableViewDataSource / Delegate (Report reasons)

extension BlockReportPopupViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reportReasons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReportReasonCell.reuseIdentifier, for: indexPath) as? ReportReasonCell else {
            return UITableViewCell()
        }
        let reason = reportReasons[indexPath.row]
        let isSelected = indexPath.row == selectedReasonIndex
        cell.configure(title: reason.title, isSelected: isSelected)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedReasonIndex = indexPath.row
        tableView.reloadData()

        let isOther = reportReasons[indexPath.row].isOtherOption
        otherTextView.isHidden = !isOther
        otherPlaceholderLabel.isHidden = !isOther || !otherTextView.text.isEmpty

        updateSubmitButtonState()
    }
}

// MARK: - UITextViewDelegate

extension BlockReportPopupViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        otherPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - ReportReasonCell

final class ReportReasonCell: UITableViewCell {

    static let reuseIdentifier = "ReportReasonCell"

    private let radioOuter: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor(white: 1.0, alpha: 0.4).cgColor
        return view
    }()

    private let radioInner: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.99, green: 0.29, blue: 0.42, alpha: 1)
        view.layer.cornerRadius = 5
        view.isHidden = true
        return view
    }()

    private let reasonLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(radioOuter)
        radioOuter.addSubview(radioInner)
        contentView.addSubview(reasonLabel)

        radioOuter.translatesAutoresizingMaskIntoConstraints = false
        radioInner.translatesAutoresizingMaskIntoConstraints = false
        reasonLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            radioOuter.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            radioOuter.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            radioOuter.widthAnchor.constraint(equalToConstant: 20),
            radioOuter.heightAnchor.constraint(equalToConstant: 20),

            radioInner.centerXAnchor.constraint(equalTo: radioOuter.centerXAnchor),
            radioInner.centerYAnchor.constraint(equalTo: radioOuter.centerYAnchor),
            radioInner.widthAnchor.constraint(equalToConstant: 10),
            radioInner.heightAnchor.constraint(equalToConstant: 10),

            reasonLabel.leadingAnchor.constraint(equalTo: radioOuter.trailingAnchor, constant: 12),
            reasonLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            reasonLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(title: String, isSelected: Bool) {
        reasonLabel.text = title
        radioInner.isHidden = !isSelected
        radioOuter.layer.borderColor = isSelected
            ? UIColor(red: 0.99, green: 0.29, blue: 0.42, alpha: 1).cgColor
            : UIColor(white: 1.0, alpha: 0.4).cgColor
    }
}

// MARK: - Usage Example
//
// Block:
// let popup = BlockReportPopupViewController(mode: .block(username: "priya_23"), delegate: self)
// present(popup, animated: false)
//
// Report:
// let popup = BlockReportPopupViewController(mode: .report(username: "priya_23"), delegate: self)
// present(popup, animated: false)
//
// extension YourViewController: BlockReportPopupDelegate {
//     func blockReportPopup(_ popup: BlockReportPopupViewController, didConfirmBlockUser username: String) {
//         // call your block API here
//     }
//     func blockReportPopup(_ popup: BlockReportPopupViewController, didSubmitReportForUser username: String, reason: String, otherText: String?) {
//         // call your report API here
//     }
// }
