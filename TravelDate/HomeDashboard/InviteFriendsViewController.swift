////
////  InviteFriendsViewController.swift
////  TravelDate
////
////  Created by Dev CodingZone
////
//
//import UIKit
//
//// MARK: - Friend Model
//
//struct TripFriend {
//    let name: String
//    let username: String
//    let avatar: String? // system image name for placeholder
//    var isInvited: Bool = false
//}
//import UIKit
//
//class InviteFriendsViewController: UIViewController {
//
//    private let tableView = UITableView()
//
//    private let headerView = UIView()
//    private let titleLabel = UILabel()
//    private let subtitleLabel = UILabel()
//
//    private let searchBar = UIView()
//    private let searchField = UITextField()
//
//    private let shareCard = UIView()
//    private let copyButton = UIButton()
//
//    private let skipLabel = UILabel()
//
//    private var data: [(name: String, username: String)] = [
//        ("Sarah Johnson","@sarahj"),
//        ("Mike Chen","@mikechan"),
//        ("Emma Davis","@emmad"),
//        ("Olivia Brown","@olivab"),
//        ("Noah Martinez","@noahm"),
//        ("Liam Wilson","@liamw")
//    ]
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .black
//        setupUI()
//        self.navigationController?.navigationBar.isHidden = true
//    }
//
//    private func setupUI() {
//
//        // NAV
//        let back = UIButton()
//        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
//        back.tintColor = .white
//        back.addTarget(self, action: #selector(backTap), for: .touchUpInside)
//
//        titleLabel.text = "Invite Friends"
//        titleLabel.textColor = .white
//        titleLabel.setFont(.semiBold, size: 22)
//
//        subtitleLabel.text = "Build your travel crew"
//        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
//        subtitleLabel.setFont(.regular, size: 14)
//
//        [back, titleLabel, subtitleLabel].forEach {
//            view.addSubview($0)
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//
//        // SEARCH
//        searchBar.backgroundColor = UIColor.white.withAlphaComponent(0.05)
//        searchBar.layer.cornerRadius = 20
//
//        searchField.attributedPlaceholder = NSAttributedString(
//            string: "Search friends...",
//            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
//        )
//        searchField.textColor = .white
//
//        searchBar.addSubview(searchField)
//        view.addSubview(searchBar)
//
//        searchField.translatesAutoresizingMaskIntoConstraints = false
//        searchBar.translatesAutoresizingMaskIntoConstraints = false
//
//        // SHARE CARD
//        shareCard.backgroundColor = UIColor.white.withAlphaComponent(0.05)
//        shareCard.layer.cornerRadius = 20
//
//        let shareTitle = UILabel()
//        shareTitle.text = "Share Invite Link"
//        shareTitle.textColor = .white
//        shareTitle.setFont(.semiBold, size: 16)
//
//        let shareDesc = UILabel()
//        shareDesc.text = "Anyone with this link can join your group"
//        shareDesc.textColor = UIColor.white.withAlphaComponent(0.5)
//        shareDesc.setFont(.regular, size: 13)
//
//        let linkLabel = UILabel()
//        linkLabel.text = "https://tripsapp.com/join/..."
//        linkLabel.textColor = UIColor.white.withAlphaComponent(0.5)
//        linkLabel.setFont(.regular, size: 13)
//
//        copyButton.setTitle("Copy", for: .normal)
//        copyButton.backgroundColor = UIColor.orange
//        copyButton.layer.cornerRadius = 16
//
//        [shareTitle, shareDesc, linkLabel, copyButton].forEach {
//            shareCard.addSubview($0)
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//
//        view.addSubview(shareCard)
//        shareCard.translatesAutoresizingMaskIntoConstraints = false
//
//        // TABLE
//        tableView.backgroundColor = .clear
//        tableView.separatorStyle = .none
//        tableView.register(FriendCell.self, forCellReuseIdentifier: "cell")
//        tableView.dataSource = self
//
//        view.addSubview(tableView)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//
//        // SKIP
//        skipLabel.text = "Skip"
//        skipLabel.textColor = UIColor.white.withAlphaComponent(0.6)
//        skipLabel.textAlignment = .center
//
//        view.addSubview(skipLabel)
//        skipLabel.translatesAutoresizingMaskIntoConstraints = false
//        skipLabel.isUserInteractionEnabled = true
//
//        let tap = UITapGestureRecognizer(target: self, action: #selector(skipTapped))
//        skipLabel.addGestureRecognizer(tap)
//        // CONSTRAINTS
//        NSLayoutConstraint.activate([
//
//            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
//            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//
//            titleLabel.topAnchor.constraint(equalTo: back.topAnchor),
//            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
//            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            searchBar.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
//            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            searchBar.heightAnchor.constraint(equalToConstant: 50),
//
//            searchField.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 16),
//            searchField.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
//
//            shareCard.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
//            shareCard.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
//            shareCard.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor),
//
//            shareTitle.topAnchor.constraint(equalTo: shareCard.topAnchor, constant: 16),
//            shareTitle.leadingAnchor.constraint(equalTo: shareCard.leadingAnchor, constant: 16),
//
//            shareDesc.topAnchor.constraint(equalTo: shareTitle.bottomAnchor, constant: 4),
//            shareDesc.leadingAnchor.constraint(equalTo: shareTitle.leadingAnchor),
//
//            linkLabel.topAnchor.constraint(equalTo: shareDesc.bottomAnchor, constant: 8),
//            linkLabel.leadingAnchor.constraint(equalTo: shareTitle.leadingAnchor),
//
//            copyButton.trailingAnchor.constraint(equalTo: shareCard.trailingAnchor, constant: -16),
//            copyButton.centerYAnchor.constraint(equalTo: shareTitle.centerYAnchor),
//            copyButton.widthAnchor.constraint(equalToConstant: 70),
//            copyButton.heightAnchor.constraint(equalToConstant: 36),
//
//            shareCard.bottomAnchor.constraint(equalTo: linkLabel.bottomAnchor, constant: 16),
//
//            tableView.topAnchor.constraint(equalTo: shareCard.bottomAnchor, constant: 20),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//
//            skipLabel.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 10),
//            skipLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            skipLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
//        ])
//    }
//
//    @objc private func backTap() {
//        navigationController?.popViewController(animated: true)
//    }
//    
//    @objc private func skipTapped() {
//        self.pushVC(TripsTabBarController.self, from: .Home)
//    }
//}
//
//extension InviteFriendsViewController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        data.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendCell
//        let item = data[indexPath.row]
//        cell.configure(name: item.name, username: item.username)
//        return cell
//    }
//}
//
//class FriendCell: UITableViewCell {
//
//    private let avatar = UIView()
//    private let nameLabel = UILabel()
//    private let usernameLabel = UILabel()
//    private let inviteButton = UIButton()
//
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        backgroundColor = .clear
//
//        avatar.backgroundColor = UIColor.orange.withAlphaComponent(0.3)
//        avatar.layer.cornerRadius = 25
//
//        nameLabel.textColor = .white
//        nameLabel.setFont(.medium, size: 16)
//
//        usernameLabel.textColor = UIColor.white.withAlphaComponent(0.5)
//        usernameLabel.setFont(.regular, size: 13)
//
//        inviteButton.setTitle("Invite", for: .normal)
//        inviteButton.setTitleColor(.white, for: .normal)
//        inviteButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
//        inviteButton.layer.cornerRadius = 16
//
//        [avatar, nameLabel, usernameLabel, inviteButton].forEach {
//            contentView.addSubview($0)
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//
//        NSLayoutConstraint.activate([
//            avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            avatar.widthAnchor.constraint(equalToConstant: 50),
//            avatar.heightAnchor.constraint(equalToConstant: 50),
//
//            nameLabel.topAnchor.constraint(equalTo: avatar.topAnchor),
//            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
//
//            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
//            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
//
//            inviteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            inviteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            inviteButton.widthAnchor.constraint(equalToConstant: 80),
//            inviteButton.heightAnchor.constraint(equalToConstant: 36),
//
//            contentView.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 12)
//        ])
//    }
//
//    required init?(coder: NSCoder) { fatalError() }
//
//    func configure(name: String, username: String) {
//        nameLabel.text = name
//        usernameLabel.text = username
//    }
//}


import SwiftUI

struct InviteFriendsView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {

                // Header
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Invite Friends")
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .bold))

                        Text("Build your travel crew")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }

                    Spacer()
                }
                .padding(.horizontal)

                // Search Field
                HStack {
                    TextField("Search friends...", text: .constant(""))
                        .foregroundColor(.white)

                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(14)
                .padding(.horizontal)

                // Invite Link Card
                VStack(alignment: .leading, spacing: 14) {

                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.orange)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Share Invite Link")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))

                            Text("Anyone with this link can join your group")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                        }
                    }

                    HStack {
                        Text("https://travelapp.com/join/bali-crew-...")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                            .lineLimit(1)

                        Spacer()

                        Button {
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.orange)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(18)
                .padding(.horizontal)

                // Suggested Friends Header
                HStack {
                    Text("Suggested Friends")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Text("6 friends")
                        .foregroundColor(.gray)
                        .font(.system(size: 13))
                }
                .padding(.horizontal)

                // Friends List
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(0..<6) { _ in
                            HStack {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 45, height: 45)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Sarah Johnson")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))

                                    Text("@sarahj")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 13))
                                }

                                Spacer()

                                Button {
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperplane")
                                        Text("Invite")
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.orange, lineWidth: 1)
                                    )
                                    .foregroundColor(.orange)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(18)
                        }
                    }
                    .padding(.horizontal)
                }

                // Skip Button
                Button {
                } label: {
                    Text("Skip")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(22)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    InviteFriendsView()
}
