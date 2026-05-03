



import UIKit
import MapKit

final class FloatingDropdownTextField: UITextField {

    // MARK: - UI
    private let containerView = UIView()
    private let tableView = UITableView()

    // MARK: - Data
    private let completer = MKLocalSearchCompleter()
    private var results: [MKLocalSearchCompletion] = []

    private var tableHeightConstraint: NSLayoutConstraint!

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup
    private func setup() {
        self.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        // Apple search
        completer.delegate = self
        completer.resultTypes = [.address]

        setupDropdownUI()
    }

    private func getTopView() -> UIView? {
        var view = self.superview
        while view != nil {
            if let vc = view?.next as? UIViewController {
                return vc.view
            }
            view = view?.superview
        }
        return nil
    }
    
    private func setupDropdownUI() {
        guard let parent = getTopView() else { return }

        containerView.backgroundColor = .black
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.25
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        containerView.layer.shadowRadius = 10
        containerView.alpha = 0

        tableView.frame = containerView.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear

        containerView.addSubview(tableView)
        parent.addSubview(containerView)
    }
    
    private func updateFrame() {
        guard let parent = containerView.superview else { return }

        let frame = self.convert(self.bounds, to: parent)

        containerView.frame = CGRect(
            x: frame.minX,
            y: frame.maxY + 8,
            width: frame.width,
            height: containerView.frame.height
        )

        parent.bringSubviewToFront(containerView)
    }

    // MARK: - Search
    @objc private func textChanged() {
        guard let text = self.text, !text.isEmpty else {
            hideDropdown()
            return
        }

        completer.queryFragment = text
    }

    // MARK: - Show / Hide
    private func showDropdown() {
        updateFrame()

        let height = min(CGFloat(results.count * 60), 250)

        UIView.animate(withDuration: 0.25) {
            self.containerView.frame.size.height = height
            self.containerView.alpha = 1
        }
    }
   
    private func hideDropdown() {
        UIView.animate(withDuration: 0.2) {
            self.containerView.alpha = 0
            self.containerView.frame.size.height = 0
        }
    }
}

// MARK: - TableView
extension FloatingDropdownTextField: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        let result = results[indexPath.row]

        cell.textLabel?.text = result.title
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)

        cell.detailTextLabel?.text = result.subtitle
        cell.detailTextLabel?.textColor = .lightGray
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = results[indexPath.row]

        self.text = "\(result.title), \(result.subtitle)"
        hideDropdown()
        self.resignFirstResponder()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupDropdownUI()
    }
}

// MARK: - Apple Search Delegate
extension FloatingDropdownTextField: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // ✅ Safety check
            guard self.tableView.superview != nil else { return }

            self.results = completer.results
            self.tableView.reloadData()

            if self.results.isEmpty {
                self.hideDropdown()
            } else {
                self.showDropdown()
            }
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search error:", error.localizedDescription)
    }
}


class OverlappingAvatarsView: UIView {

    var imageViews: [UIImageView] = []
    let overlap: CGFloat = 16
    let size: CGFloat = 32

    func configure(images: [UIImage], extraCount: Int = 0) {
        // Clear old
        subviews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()

        for (index, image) in images.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(
                x: CGFloat(index) * (size - overlap),
                y: 0,
                width: size,
                height: size
            )

            imageView.layer.cornerRadius = size / 2
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 2
            imageView.layer.borderColor = UIColor.black.cgColor

            addSubview(imageView)
            imageViews.append(imageView)
        }

        // "+2 more"
        if extraCount > 0 {
            let label = UILabel()
            label.text = "+\(extraCount)"
            label.textColor = .white
            label.font = .systemFont(ofSize: 12, weight: .medium)

            let bgView = UIView(frame: CGRect(
                x: CGFloat(images.count) * (size - overlap),
                y: 0,
                width: size,
                height: size
            ))

            bgView.backgroundColor = .darkGray
            bgView.layer.cornerRadius = size / 2

            label.sizeToFit()
            label.center = CGPoint(x: size / 2, y: size / 2)

            bgView.addSubview(label)
            addSubview(bgView)
        }
    }

    override var intrinsicContentSize: CGSize {
        let count = subviews.count
        let width = CGFloat(count) * (size - overlap) + overlap
        return CGSize(width: width, height: size)
    }
}
