//
//  BlockReportListVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 07/07/26.
//  Title: "Block"
//  Table view list: profile image, name, username, Unblock button.
//
//  Programmatic UIKit, no Storyboards/XIBs.
//

import UIKit

// MARK: - Model

struct BlockedUser {
    let id: String
    let name: String
    let username: String
    let imageURL: URL?
}

final class BlockedUsersListViewController: UIViewController {

    // MARK: - Data

    private var blockedUsers: [BlockedUser] = []

    // MARK: - UI

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .black
        table.separatorStyle = .none
        table.register(BlockedUserCell.self, forCellReuseIdentifier: BlockedUserCell.reuseIdentifier)
        table.rowHeight = 76
        return table
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "You haven't blocked anyone yet"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor(white: 1.0, alpha: 0.5)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Block"
        view.backgroundColor = .black
        setupNavigationBar()
        setupTableView()
        loadBlockedUsers()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    // MARK: - Data Loading

    private func loadBlockedUsers() {
        // TODO: replace with your API call, e.g.:
        // BlockService.fetchBlockedUsers { [weak self] result in ... }
        //
        // Sample data for now:
        blockedUsers = [
            BlockedUser(id: "1", name: "Priya Sharma", username: "priya_23", imageURL: nil),
            BlockedUser(id: "2", name: "Rahul Verma", username: "rahulv", imageURL: nil)
        ]
        refreshEmptyState()
        tableView.reloadData()
    }

    private func refreshEmptyState() {
        emptyStateLabel.isHidden = !blockedUsers.isEmpty
        tableView.isHidden = blockedUsers.isEmpty
    }

    // MARK: - Unblock

    private func handleUnblockTapped(for user: BlockedUser) {
        let alert = UIAlertController(
            title: "Unblock @\(user.username)?",
            message: "They will be able to see your profile and message you again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Unblock", style: .destructive) { [weak self] _ in
            self?.unblockUser(user)
        })
        present(alert, animated: true)
    }

    private func unblockUser(_ user: BlockedUser) {
        // TODO: call your unblock API here, then remove locally on success:
        // BlockService.unblock(userId: user.id) { [weak self] success in ... }

        guard let index = blockedUsers.firstIndex(where: { $0.id == user.id }) else { return }
        blockedUsers.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        refreshEmptyState()
    }
}

// MARK: - UITableViewDataSource / Delegate

extension BlockedUsersListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        blockedUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BlockedUserCell.reuseIdentifier, for: indexPath) as? BlockedUserCell else {
            return UITableViewCell()
        }
        let user = blockedUsers[indexPath.row]
        cell.configure(with: user)
        cell.onUnblockTapped = { [weak self] in
            self?.handleUnblockTapped(for: user)
        }
        return cell
    }
}

// MARK: - BlockedUserCell

final class BlockedUserCell: UITableViewCell {

    static let reuseIdentifier = "BlockedUserCell"

    var onUnblockTapped: (() -> Void)?

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 26
        imageView.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        imageView.image = UIImage(systemName: "person.fill")
        imageView.tintColor = UIColor(white: 1.0, alpha: 0.3)
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(white: 1.0, alpha: 0.5)
        return label
    }()

    private lazy var unblockButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Unblock", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        button.addTarget(self, action: #selector(unblockTapped), for: .touchUpInside)
        return button
    }()

    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .black
        selectionStyle = .none
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(unblockButton)
        contentView.addSubview(separatorLine)

        [profileImageView, nameLabel, usernameLabel, unblockButton, separatorLine].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 52),
            profileImageView.heightAnchor.constraint(equalToConstant: 52),

            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: unblockButton.leadingAnchor, constant: -8),

            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: unblockButton.leadingAnchor, constant: -8),

            unblockButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unblockButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            separatorLine.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configure(with user: BlockedUser) {
        nameLabel.text = user.name
        usernameLabel.text = "@\(user.username)"

        // TODO: plug into your image loading utility (SDWebImage / Kingfisher / custom)
        // if let url = user.imageURL {
        //     profileImageView.loadImage(from: url)
        // }
    }

    @objc private func unblockTapped() {
        onUnblockTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onUnblockTapped = nil
        profileImageView.image = UIImage(systemName: "person.fill")
    }
}

// MARK: - Usage Example
//
// let blockedVC = BlockedUsersListViewController()
// navigationController?.pushViewController(blockedVC, animated: true)
