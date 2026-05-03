//
//  TravelPickStyles.swift
//  TravelDate
//
//  Created by Dev CodingZone on 23/04/26.
//

import UIKit

// MARK: - TravelStyle Model
enum TravelStyle: Int, CaseIterable {
    case partygoers
    case adventureTravelers
    case culturalTravelers
    case leisureTravelers

    var title: String {
        switch self {
        case .partygoers:          return "Partygoers"
        case .adventureTravelers:  return "Adventure travelers"
        case .culturalTravelers:   return "Cultural travelers"
        case .leisureTravelers:    return "Leisure travelers"
        }
    }

    var icon: String {
        switch self {
        case .partygoers:          return ""
        case .adventureTravelers:  return ""
        case .culturalTravelers:   return ""
        case .leisureTravelers:    return ""
        }
    }
}

// MARK: - Delegate
protocol TravelStylePickerDelegate: AnyObject {
    func travelStylePicker(_ picker: TravelStylePickerView, didSelect style: TravelStyle)
}

// MARK: - TravelStylePickerView
final class TravelStylePickerView: UIView {

    // MARK: - Public
    weak var delegate: TravelStylePickerDelegate?
    private(set) var selectedStyle: TravelStyle = .partygoers

    // MARK: - UI
    private let dimView        = UIView()
    private let sheetView      = UIView()
    private let titleLabel     = UILabel()
    private let subtitleLabel  = UILabel()
    private let stackView      = UIStackView()
    private let confirmButton  = UIButton(type: .system)
    private let dragHandle     = UIView()

    private var styleRows: [TravelStyleRow] = []
    private var sheetBottomConstraint: NSLayoutConstraint!

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDimView()
        setupSheet()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup Dim
    private func setupDimView() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        dimView.addGestureRecognizer(tap)
    }

    // MARK: - Setup Sheet
    private func setupSheet() {
        sheetView.backgroundColor    = UIColor(hex: "#161616")
        sheetView.layer.cornerRadius = 28
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sheetView)
        sheetView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 100)
        sheetBottomConstraint = sheetView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 600)
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sheetBottomConstraint
        ])

        setupSheetContent()

        // Swipe down to dismiss
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissTapped))
        swipe.direction = .down
        sheetView.addGestureRecognizer(swipe)
    }

    private func setupSheetContent() {
        // Drag handle
        dragHandle.backgroundColor    = UIColor(hex: "#3A3A3A")
        dragHandle.layer.cornerRadius = 3
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(dragHandle)

        // Title
        titleLabel.text      = "Travel Style"
        titleLabel.textColor = .white
        titleLabel.font      = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        subtitleLabel.text          = "How do you like to travel?"
        subtitleLabel.textColor     = .appGrayText
        subtitleLabel.font          = .systemFont(ofSize: 13)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        sheetView.addSubview(titleLabel)
        sheetView.addSubview(subtitleLabel)

        // Style rows stack
        stackView.axis         = .vertical
        stackView.spacing      = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(stackView)

        for style in TravelStyle.allCases {
            let row = TravelStyleRow(style: style, isSelected: style == selectedStyle)
            row.onTap = { [weak self] in self?.selectStyle(style) }
            styleRows.append(row)
            stackView.addArrangedSubview(row)
        }

        
        // Confirm button
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmButton.backgroundColor  = .appOrange
        confirmButton.layer.cornerRadius = 28
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        sheetView.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            dragHandle.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 12),
            dragHandle.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 40),
            dragHandle.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -20),

            confirmButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 24),
            confirmButton.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -20),
            confirmButton.heightAnchor.constraint(equalToConstant: 56),
            confirmButton.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor, constant: -36)
        ])
    }

    // MARK: - Select Style
    private func selectStyle(_ style: TravelStyle) {
        selectedStyle = style
        for row in styleRows {
            row.setSelected(row.style == style)
        }
    }

    // MARK: - Present / Dismiss
    func present(in viewController: UIViewController) {
        guard let window = UIApplication.shared
            .connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first else { return }

        frame = window.bounds
        window.addSubview(self)

        // Animate in
        dimView.alpha = 0
        layoutIfNeeded()

        sheetBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.38, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.5) {
            self.dimView.alpha = 1
            self.layoutIfNeeded()
        }
    }

    @objc func dismissTapped() {
        sheetBottomConstraint.constant = 600
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.dimView.alpha = 0
            self.layoutIfNeeded()
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    @objc private func confirmTapped() {
        delegate?.travelStylePicker(self, didSelect: selectedStyle)
        dismissTapped()
    }
}

// MARK: - TravelStyleRow
final class TravelStyleRow: UIView {

    let style: TravelStyle
    var onTap: (() -> Void)?

    private let titleLabel  = UILabel()
    private let radioView   = UIImageView()

    init(style: TravelStyle, isSelected: Bool) {
        self.style = style
        super.init(frame: .zero)
        setupRow()
        setSelected(isSelected)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupRow() {
        backgroundColor = UIColor(hex: "#1A1A1A")
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 58).isActive = true

        // Title
        titleLabel.text = style.title
        titleLabel.setFont(.medium, size: 14.0)
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Radio
        radioView.contentMode = .scaleAspectFit
        radioView.translatesAutoresizingMaskIntoConstraints = false
        radioView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        radioView.heightAnchor.constraint(equalToConstant: 22).isActive = true

        addSubview(titleLabel)
        addSubview(radioView)

        NSLayoutConstraint.activate([
            // Title - FIXED LEFT
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Radio - FIXED RIGHT
            radioView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            radioView.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Prevent overlap
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: radioView.leadingAnchor, constant: -12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    func setSelected(_ selected: Bool) {
        layer.borderWidth = selected ? 1.5 : 1
        layer.borderColor = selected ? UIColor.appOrange.cgColor : UIColor.appBorder.cgColor

        titleLabel.textColor = selected ? .appOrange : .appGrayText

        radioView.image = UIImage(systemName: selected ? "largecircle.fill.circle" : "circle")
        radioView.tintColor = selected ? .appOrange : .appGrayText
    }

    @objc private func tapped() {
        onTap?()
    }
}
