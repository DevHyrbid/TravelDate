//
//  TravelListViewController.swift
//  TravelDate
//

import UIKit
final class TravelListViewController: BaseClassVc {

    // MARK: - Views

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        } else {
            button.setTitle("<", for: .normal)
        }

        button.tintColor = .white
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Travel History"
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .white
        return label
    }()

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.showsVerticalScrollIndicator = false
        table.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)
        return table
    }()

    // MARK: - Data

    private var data: [TravelItem] = []

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 22/255, green: 13/255, blue: 13/255, alpha: 1)

        setupUI()

        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            TravelCell.self,
            forCellReuseIdentifier: TravelCell.identifier
        )

        getHistoryTrips()
    }

    // MARK: - UI

    private func setupUI() {

        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        view.addSubview(tableView)

        backButton.addTarget(self,
                             action: #selector(backTapped),
                             for: .touchUpInside)

        NSLayoutConstraint.activate([

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    // MARK: - API

    private func getHistoryTrips() {

        request.getHistoryTrips { [weak self] model, err, code in

            guard let self = self else { return }
            guard code == 200 else { return }

            self.data.removeAll()

            model?.forEach { item in

                self.data.append(
                    TravelItem(
                        title: item.title ?? "",
                        month: "May 2026",
                        icon: item.coverImage,
                        status: item.status ?? ""
                    )
                )
            }

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - UITableView

extension TravelListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let item = data[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: TravelCell.identifier,
            for: indexPath
        ) as! TravelCell

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        cell.configure(
            title: item.title,
            month: item.month,
            icon: item.icon,
            status: item.status
        )

        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116
    }
}
