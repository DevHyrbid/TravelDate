//
//  ChatGalleryViewController.swift
//  TravelDate
//
//  UIKit only. All loading / grouping / upload logic lives in ChatGalleryPresenter.
//  This file builds the UI and forwards user actions to the presenter.
//
//  Usage (e.g. from ChatMessageVc's header):
//      let vc = ChatGalleryViewController(roomId: roomId, roomTitle: roomTitle)
//      navigationController?.pushViewController(vc, animated: true)
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import Kingfisher

// MARK: - Theme

private enum GalleryTheme {
    static let background = UIColor(hex: "#0B0D0D")
    static let surface    = UIColor(hex: "#161A1D")
    static let accent     = UIColor(hex: "#FF7A00")
    static let secondaryText = UIColor.white.withAlphaComponent(0.6)
    static let gridSpacing: CGFloat = 3
    static let columns = 3
}

// MARK: - Gallery View Controller

@MainActor
final class ChatGalleryViewController: UIViewController {

    // MARK: - Presenter

    private lazy var presenter = ChatGalleryPresenter(roomId: roomId, view: self)
    private let roomId: String
    private let roomTitle: String

    // MARK: - UI

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let filterBar = FilterPillBar(filters: GalleryFilter.allCases)

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let emptyView = GalleryEmptyView()
    private let addButton = UIButton(type: .system)

    private typealias DataSource = UICollectionViewDiffableDataSource<String, String>
    private var dataSource: DataSource!

    // MARK: - Init

    init(roomId: String, roomTitle: String) {
        self.roomId = roomId
        self.roomTitle = roomTitle
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        presenter.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}

// MARK: - Setup

private extension ChatGalleryViewController {

    func setupUI() {
        view.backgroundColor = GalleryTheme.background

        // Header
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        backButton.layer.cornerRadius = 18
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        titleLabel.text = "Memories"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white

        summaryLabel.text = roomTitle
        summaryLabel.font = .systemFont(ofSize: 14, weight: .medium)
        summaryLabel.textColor = GalleryTheme.secondaryText

        filterBar.onSelect = { [weak self] filter in
            UISelectionFeedbackGenerator().selectionChanged()
            self?.presenter.setFilter(filter)
        }

        // Grid
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset.bottom = 100     // room for the add button
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.reuseId)
        collectionView.register(GallerySectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: GallerySectionHeader.reuseId)
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true

        emptyView.isHidden = true
        emptyView.onAdd = { [weak self] in self?.addTapped() }

        // Floating add button
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold))
        config.baseBackgroundColor = GalleryTheme.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        addButton.configuration = config
        addButton.accessibilityLabel = "Add photos or videos"
        addButton.layer.shadowColor = GalleryTheme.accent.cgColor
        addButton.layer.shadowOpacity = 0.45
        addButton.layer.shadowRadius = 14
        addButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        [backButton, titleStack, filterBar, collectionView, loadingIndicator, emptyView, addButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            titleStack.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 14),
            titleStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            filterBar.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 16),
            filterBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            filterBar.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            filterBar.heightAnchor.constraint(equalToConstant: 36),

            collectionView.topAnchor.constraint(equalTo: filterBar.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),

            emptyView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -30),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 58),
            addButton.heightAnchor.constraint(equalToConstant: 58),
        ])
    }

    /// 3-column square grid, grouped by month with a header per section.
    func makeLayout() -> UICollectionViewLayout {
        let spacing = GalleryTheme.gridSpacing
        let fraction = 1.0 / CGFloat(GalleryTheme.columns)

        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .fractionalWidth(fraction),
            heightDimension: .fractionalWidth(fraction)))
        item.contentInsets = .init(top: spacing / 2, leading: spacing / 2,
                                   bottom: spacing / 2, trailing: spacing / 2)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .fractionalWidth(fraction)),
            subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 12, bottom: 18, trailing: 12)

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(40)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)
        section.boundarySupplementaryItems = [header]

        return UICollectionViewCompositionalLayout(section: section)
    }

    func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, id in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.reuseId,
                                                          for: indexPath) as? GalleryCell
            if let item = self?.presenter.item(id: id) {
                cell?.configure(with: item)
            }
            return cell ?? UICollectionViewCell()
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind, withReuseIdentifier: GallerySectionHeader.reuseId, for: indexPath) as? GallerySectionHeader
            if let section = self?.presenter.sections[safe: indexPath.section] {
                header?.configure(title: section.title, count: section.items.count)
            }
            return header
        }
    }
}

// MARK: - Actions

private extension ChatGalleryViewController {

    @objc func backTapped() {
        if let nav = navigationController, nav.viewControllers.first !== self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc func pulledToRefresh() {
        presenter.refresh()
    }

    @objc func addTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // PHPicker needs no photo-library permission prompt.
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = ChatGalleryPresenter.maxSelection
        config.preferredAssetRepresentationMode = .compatible   // H.264 / JPEG — plays everywhere
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func openViewer(at id: String) {
        let items = presenter.flatItems
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let viewer = GalleryViewerController(items: items, startIndex: index)
        viewer.modalPresentationStyle = .fullScreen
        viewer.modalTransitionStyle = .crossDissolve
        present(viewer, animated: true)
    }

    func showFailedOptions(for id: String) {
        let sheet = UIAlertController(title: "Upload failed", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            self?.presenter.retry(id: id)
        })
        sheet.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.presenter.discardFailed(id: id)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(sheet, animated: true)
    }
}

// MARK: - ChatGalleryView

extension ChatGalleryViewController: ChatGalleryView {

    func render(sections: [GallerySection], animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        for section in sections {
            snapshot.appendSections([section.id])
            snapshot.appendItems(section.items.map(\.id), toSection: section.id)
        }
        // Headers show per-section counts, so refresh them too.
        snapshot.reloadSections(snapshot.sectionIdentifiers.filter {
            dataSource.snapshot().sectionIdentifiers.contains($0)
        })
        dataSource.apply(snapshot, animatingDifferences: animated)
        refreshControl.endRefreshing()
    }

    func reloadItem(id: String) {
        var snapshot = dataSource.snapshot()
        guard snapshot.indexOfItem(id) != nil else { return }
        snapshot.reloadItems([id])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func showLoading(_ isLoading: Bool) {
        if isLoading && !refreshControl.isRefreshing {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        if !isLoading { refreshControl.endRefreshing() }
    }

    func showEmptyState(_ isEmpty: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.emptyView.isHidden = !isEmpty
            self.emptyView.alpha = isEmpty ? 1 : 0
            self.addButton.alpha = isEmpty ? 0 : 1    // empty state has its own CTA
        }
    }

    func updateSummary(_ text: String) {
        summaryLabel.text = roomTitle.isEmpty ? text : "\(roomTitle) · \(text)"
    }

    func showError(_ message: String) {
        refreshControl.endRefreshing()
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension ChatGalleryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let item = presenter.item(id: id) else { return }
        switch item.state {
        case .uploaded:  openViewer(at: id)
        case .failed:    showFailedOptions(for: id)
        case .uploading: break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let remaining = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height
        if remaining < 600 { presenter.loadMoreIfNeeded() }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ChatGalleryViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        for result in results {
            let provider = result.itemProvider

            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                // The picker's file is deleted when this callback returns — copy it first.
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                    guard let url else { return }
                    let copy = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)
                    do {
                        try FileManager.default.copyItem(at: url, to: copy)
                    } catch {
                        return
                    }
                    DispatchQueue.main.async {
                        self?.presenter.upload(videoAt: copy)
                    }
                }
            } else if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                    guard let image = object as? UIImage else { return }
                    DispatchQueue.main.async {
                        self?.presenter.upload(photo: image)
                    }
                }
            }
        }
    }
}

// MARK: - Grid Cell

private final class GalleryCell: UICollectionViewCell {

    static let reuseId = "GalleryCell"

    private let imageView = UIImageView()
    private let videoGradient = CAGradientLayer()
    private let videoBadge = UIStackView()
    private let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
    private let durationLabel = UILabel()
    private let overlay = UIView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let failedIcon = UIImageView(image: UIImage(systemName: "exclamationmark.arrow.circlepath"))

    private var representedId: String?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true
        contentView.backgroundColor = GalleryTheme.surface

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        videoGradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
        videoGradient.locations = [0.55, 1]

        playIcon.tintColor = .white
        playIcon.preferredSymbolConfiguration = .init(pointSize: 10, weight: .bold)
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        durationLabel.textColor = .white
        videoBadge.axis = .horizontal
        videoBadge.spacing = 4
        videoBadge.alignment = .center
        videoBadge.addArrangedSubview(playIcon)
        videoBadge.addArrangedSubview(durationLabel)

        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        spinner.color = .white
        failedIcon.tintColor = .white
        failedIcon.contentMode = .scaleAspectFit
        failedIcon.preferredSymbolConfiguration = .init(pointSize: 22, weight: .semibold)

        [imageView, overlay].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        imageView.layer.addSublayer(videoGradient)
        [videoBadge, spinner, failedIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            videoBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 7),
            videoBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            failedIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            failedIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        videoGradient.frame = contentView.bounds
        CATransaction.commit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        representedId = nil
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }

    func configure(with item: GalleryItem) {
        representedId = item.id

        // Image
        if let preview = item.localPreview {
            imageView.image = preview
        } else if let remote = item.remoteURL {
            switch item.kind {
            case .photo:
                if let url = ChatMediaURL.resolved(remote) {
                    let size = CGSize(width: 300, height: 300)
                    imageView.kf.setImage(with: url, options: [
                        .processor(DownsamplingImageProcessor(size: size)),
                        .scaleFactor(UIScreen.main.scale),
                        .cacheOriginalImage,
                        .transition(.fade(0.2)),
                    ])
                }
            case .video:
                let id = item.id
                ChatVideoThumbnailLoader.loadRemote(remote) { [weak self] thumbnail in
                    guard let self, self.representedId == id else { return }   // cell was reused
                    UIView.transition(with: self.imageView, duration: 0.2, options: .transitionCrossDissolve) {
                        self.imageView.image = thumbnail
                    }
                }
            }
        }

        // Video badge
        let isVideo = item.kind == .video
        videoBadge.isHidden = !isVideo
        videoGradient.isHidden = !isVideo
        durationLabel.text = item.videoDuration.map(Self.format(duration:))
        durationLabel.isHidden = item.videoDuration == nil

        // Upload state
        switch item.state {
        case .uploaded:
            overlay.isHidden = true
            spinner.stopAnimating()
            failedIcon.isHidden = true
        case .uploading:
            overlay.isHidden = false
            spinner.startAnimating()
            failedIcon.isHidden = true
        case .failed:
            overlay.isHidden = false
            spinner.stopAnimating()
            failedIcon.isHidden = false
        }

        let kindText = isVideo ? "Video" : "Photo"
        let byText = item.isMine ? "by you" : (item.senderName.isEmpty ? "" : "by \(item.senderName)")
        switch item.state {
        case .uploaded:  accessibilityLabel = "\(kindText) \(byText)"
        case .uploading: accessibilityLabel = "\(kindText), uploading"
        case .failed:    accessibilityLabel = "\(kindText), upload failed. Double-tap for options."
        }
        accessibilityTraits = .button
    }

    static func format(duration seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Section Header

private final class GallerySectionHeader: UICollectionReusableView {

    static let reuseId = "GallerySectionHeader"
    private let titleLabel = UILabel()
    private let countLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        countLabel.font = .systemFont(ofSize: 13, weight: .medium)
        countLabel.textColor = GalleryTheme.secondaryText

        let stack = UIStackView(arrangedSubviews: [titleLabel, UIView(), countLabel])
        stack.alignment = .lastBaseline
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    func configure(title: String, count: Int) {
        titleLabel.text = title
        countLabel.text = "\(count)"
    }
}

// MARK: - Filter Pills

private final class FilterPillBar: UIStackView {

    var onSelect: ((GalleryFilter) -> Void)?
    private let filters: [GalleryFilter]
    private var buttons: [UIButton] = []

    init(filters: [GalleryFilter]) {
        self.filters = filters
        super.init(frame: .zero)
        axis = .horizontal
        spacing = 8

        for (index, filter) in filters.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(filter.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            button.layer.cornerRadius = 18
            button.layer.borderWidth = 1
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            addArrangedSubview(button)
            buttons.append(button)
        }
        select(index: 0)
    }

    required init(coder: NSCoder) { fatalError("init(coder:) not used") }

    @objc private func tapped(_ sender: UIButton) {
        select(index: sender.tag)
        onSelect?(filters[sender.tag])
    }

    private func select(index: Int) {
        for (i, button) in buttons.enumerated() {
            let selected = i == index
            UIView.animate(withDuration: 0.2) {
                button.backgroundColor = selected ? .white : UIColor.white.withAlphaComponent(0.06)
                button.layer.borderColor = (selected ? UIColor.white : UIColor.white.withAlphaComponent(0.12)).cgColor
            }
            button.setTitleColor(selected ? .black : .white, for: .normal)
            button.accessibilityTraits = selected ? [.button, .selected] : .button
        }
    }
}

// MARK: - Empty State

private final class GalleryEmptyView: UIView {

    var onAdd: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let iconBackground = UIView()
        iconBackground.backgroundColor = GalleryTheme.accent.withAlphaComponent(0.12)
        iconBackground.layer.cornerRadius = 40
        let icon = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
        icon.tintColor = GalleryTheme.accent
        icon.preferredSymbolConfiguration = .init(pointSize: 32, weight: .medium)
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)

        let title = UILabel()
        title.text = "No memories yet"
        title.font = .systemFont(ofSize: 20, weight: .bold)
        title.textColor = .white
        title.textAlignment = .center

        let message = UILabel()
        message.text = "Share photos and videos from your trip. Everyone in this chat will see them here."
        message.font = .systemFont(ofSize: 15)
        message.textColor = GalleryTheme.secondaryText
        message.textAlignment = .center
        message.numberOfLines = 0

        var config = UIButton.Configuration.filled()
        config.title = "Add memories"
        config.image = UIImage(systemName: "plus")
        config.imagePadding = 6
        config.baseBackgroundColor = GalleryTheme.accent
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = .init(top: 12, leading: 22, bottom: 12, trailing: 22)
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [iconBackground, title, message, button])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(20, after: iconBackground)
        stack.setCustomSpacing(24, after: message)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconBackground.widthAnchor.constraint(equalToConstant: 80),
            iconBackground.heightAnchor.constraint(equalToConstant: 80),
            icon.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),

            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    @objc private func addTapped() { onAdd?() }
}

// MARK: - Full-screen Viewer

/// Swipe between memories, pinch to zoom photos, tap play for videos, share.
private final class GalleryViewerController: UIViewController {

    private let items: [GalleryItem]
    private var currentIndex: Int

    private lazy var pager: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .black
        cv.contentInsetAdjustmentBehavior = .never
        cv.dataSource = self
        cv.delegate = self
        cv.register(ViewerCell.self, forCellWithReuseIdentifier: ViewerCell.reuseId)
        return cv
    }()

    private let topBar = UIView()
    private let closeButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let senderLabel = UILabel()
    private let dateLabel = UILabel()
    private var didScrollToStart = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    init(items: [GalleryItem], startIndex: Int) {
        self.items = items
        self.currentIndex = startIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.black.withAlphaComponent(0.7).cgColor, UIColor.clear.cgColor]
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 130)
        topBar.layer.addSublayer(gradient)
        topBar.isUserInteractionEnabled = true

        for (button, symbol, label) in [(closeButton, "xmark", "Close"),
                                        (shareButton, "square.and.arrow.up", "Share")] {
            button.setImage(UIImage(systemName: symbol), for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            button.layer.cornerRadius = 18
            button.accessibilityLabel = label
        }
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        senderLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        senderLabel.textColor = .white
        senderLabel.textAlignment = .center
        dateLabel.font = .systemFont(ofSize: 12, weight: .medium)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        dateLabel.textAlignment = .center
        let infoStack = UIStackView(arrangedSubviews: [senderLabel, dateLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2

        [pager, topBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        [closeButton, shareButton, infoStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            topBar.addSubview($0)
        }

        NSLayoutConstraint.activate([
            pager.topAnchor.constraint(equalTo: view.topAnchor),
            pager.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pager.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pager.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 130),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            shareButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            shareButton.widthAnchor.constraint(equalToConstant: 36),
            shareButton.heightAnchor.constraint(equalToConstant: 36),

            infoStack.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            infoStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoStack.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 12),
        ])

        // Tap to show/hide the top bar; swipe down to close.
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleChrome))
        pager.addGestureRecognizer(tap)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(closeTapped))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)

        updateInfo()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        (pager.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = view.bounds.size
        if !didScrollToStart, items.indices.contains(currentIndex) {
            didScrollToStart = true
            pager.layoutIfNeeded()
            pager.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

    private func updateInfo() {
        guard items.indices.contains(currentIndex) else { return }
        let item = items[currentIndex]
        senderLabel.text = item.isMine ? "You" : (item.senderName.isEmpty ? "Traveler" : item.senderName)
        dateLabel.text = "\(dateFormatter.string(from: item.createdAt)) · \(currentIndex + 1) of \(items.count)"
    }

    @objc private func toggleChrome() {
        UIView.animate(withDuration: 0.2) { self.topBar.alpha = self.topBar.alpha > 0 ? 0 : 1 }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func shareTapped() {
        guard items.indices.contains(currentIndex) else { return }
        let item = items[currentIndex]
        var shareItems: [Any] = []

        if item.kind == .photo,
           let cell = pager.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? ViewerCell,
           let image = cell.currentImage {
            shareItems = [image]                    // lets the user "Save Image" too
        } else if let remote = item.remoteURL, let url = ChatMediaURL.resolved(remote) {
            shareItems = [url]
        }
        guard !shareItems.isEmpty else { return }

        let activity = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = shareButton
        present(activity, animated: true)
    }
}

extension GalleryViewerController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewerCell.reuseId, for: indexPath)
        if let viewerCell = cell as? ViewerCell {
            viewerCell.configure(with: items[indexPath.item])
            viewerCell.onPlay = { [weak self] item in
                guard let self, let remote = item.remoteURL else { return }
                ChatVideoPlayerPresenter.present(remoteURLString: remote, from: self)
            }
        }
        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === pager, scrollView.bounds.width > 0 else { return }
        currentIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        updateInfo()
    }
}

// MARK: - Viewer Cell (zoomable photo / video poster)

private final class ViewerCell: UICollectionViewCell, UIScrollViewDelegate {

    static let reuseId = "ViewerCell"
    var onPlay: ((GalleryItem) -> Void)?

    private let zoomView = UIScrollView()
    private let imageView = UIImageView()
    private let playButton = UIButton(type: .system)
    private var item: GalleryItem?

    var currentImage: UIImage? { imageView.image }

    override init(frame: CGRect) {
        super.init(frame: frame)

        zoomView.minimumZoomScale = 1
        zoomView.maximumZoomScale = 4
        zoomView.delegate = self
        zoomView.showsVerticalScrollIndicator = false
        zoomView.showsHorizontalScrollIndicator = false
        zoomView.contentInsetAdjustmentBehavior = .never

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "play.fill",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .bold))
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.2)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        playButton.configuration = config
        playButton.accessibilityLabel = "Play video"
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        zoomView.addGestureRecognizer(doubleTap)

        [zoomView, playButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        zoomView.addSubview(imageView)

        NSLayoutConstraint.activate([
            zoomView.topAnchor.constraint(equalTo: contentView.topAnchor),
            zoomView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            zoomView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            zoomView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            playButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 72),
            playButton.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomView.zoomScale == 1 {
            imageView.frame = zoomView.bounds
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        zoomView.setZoomScale(1, animated: false)
        item = nil
    }

    func configure(with item: GalleryItem) {
        self.item = item
        let isVideo = item.kind == .video
        playButton.isHidden = !isVideo
        zoomView.isScrollEnabled = !isVideo
        zoomView.maximumZoomScale = isVideo ? 1 : 4

        if let preview = item.localPreview {
            imageView.image = preview
            return
        }
        guard let remote = item.remoteURL else { return }

        switch item.kind {
        case .photo:
            if let url = ChatMediaURL.resolved(remote) {
                imageView.kf.indicatorType = .activity
                imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
            }
        case .video:
            let id = item.id
            ChatVideoThumbnailLoader.loadRemote(remote) { [weak self] thumbnail in
                guard let self, self.item?.id == id else { return }
                self.imageView.image = thumbnail
            }
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        item?.kind == .photo ? imageView : nil
    }

    @objc private func doubleTapped(_ gesture: UITapGestureRecognizer) {
        guard item?.kind == .photo else { return }
        if zoomView.zoomScale > 1 {
            zoomView.setZoomScale(1, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let size = CGSize(width: zoomView.bounds.width / 2.5, height: zoomView.bounds.height / 2.5)
            zoomView.zoom(to: CGRect(origin: CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2),
                                     size: size), animated: true)
        }
    }

    @objc private func playTapped() {
        guard let item else { return }
        onPlay?(item)
    }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
