
//
//  CreateGroupView.swift
//  Pixel‑Perfect Figma Match
//

import UIKit
import CountryKit
import MapKit
// MARK: - CreateGroupViewController
class CreateGroupViewController: BaseClassVc {

    // State
    private var groupSize   = 4
    private var selectedStyle = 0
    private let styles      = ["Partygoers", "Adventure travelers", "Cultural travelers", "Leisure travelers"]

    // UI
    private let scrollView  = UIScrollView()
    private let contentView = UIView()

    private let groupNameField   = PaddedTextField()
    private let destinationField = UIView()
    let destinationTF = UITextField()

    private let sizeLabel        = UILabel()
    private var styleRows        = [UIView]()

    var selectedImage: UIImage?
    private var startDate: String = ""
    private var endDate: String = ""

    private let startDateLabel = UILabel()
    private let endDateLabel = UILabel()
   
    var locationView: LocationSearchView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBg
        
        setupScrollView()
        buildUI()
        locationView = LocationSearchView()
        locationView.isHidden = true
        locationView.attach(to: destinationTF)
        locationView.onLocationSelected = { [weak self] address, coordinate in
            self?.destinationTF.text = address
            self?.locationView.isHidden = true
        }

        view.addSubview(locationView)

        locationView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            locationView.topAnchor.constraint(equalTo: destinationTF.bottomAnchor, constant: 8),
            locationView.leadingAnchor.constraint(equalTo: destinationTF.leadingAnchor),
            locationView.trailingAnchor.constraint(equalTo: destinationTF.trailingAnchor),
            locationView.heightAnchor.constraint(equalToConstant: 250)
        ])
        destinationTF.addTarget(self, action: #selector(openSearch), for: .editingDidBegin)

       
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        locationView.isHidden = true
    }
    
    @objc func openSearch() {
        locationView.isHidden = false
        view.bringSubviewToFront(locationView)
    }
    // MARK: - ScrollView
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -88),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Build UI
    private func buildUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        stack.addArrangedSubview(makeCoverSection())
        stack.addArrangedSubview(makeInputSection())
        stack.addArrangedSubview(makeSizeSection())
        stack.addArrangedSubview(makeStyleSection())

        // Continue button
        let btn = makeContinueButton()
        view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            btn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            btn.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Cover Photo Section
    private func makeCoverSection() -> UIView {
        let wrapper = UIView()

        let titleLabel = sectionLabel("Add Cover photo")
        wrapper.addSubview(titleLabel)

        let card = UIView()
        card.backgroundColor = .appCard
        card.layer.cornerRadius = 20
        card.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(card)

        // Dashed border layer
        let dashedLayer = CAShapeLayer()
        dashedLayer.strokeColor = UIColor.appOrange.cgColor
        dashedLayer.fillColor   = UIColor.clear.cgColor
        dashedLayer.lineWidth   = 1.2
        dashedLayer.lineDashPattern = [10, 6]
        card.layer.addSublayer(dashedLayer)

        // Layout dashed border after layout
        card.layoutIfNeeded()
        DispatchQueue.main.async {
            let inset: CGFloat = 12
            let rect = card.bounds.insetBy(dx: inset, dy: inset)
            dashedLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: 10).cgPath
            dashedLayer.frame = card.bounds
        }

        let innerStack = UIStackView()
        innerStack.axis = .vertical
        innerStack.alignment = .center
        innerStack.spacing = 6
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(innerStack)

        let imgView = UIImageView(image: UIImage(systemName: "photo.on.rectangle"))
        imgView.tintColor = .appOrange
        imgView.contentMode = .scaleAspectFit
        imgView.widthAnchor.constraint(equalToConstant: 28).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        imgView.tag = 1001

        let uploadTitle = UILabel()
        uploadTitle.text = "Upload Cover Photo"
        uploadTitle.textColor = .white
        uploadTitle.font = .systemFont(ofSize: 14, weight: .semibold)

        let uploadSub = UILabel()
        uploadSub.text = "JPG, PNG (Max 5MB)"
        uploadSub.textColor = .appGrayText
        uploadSub.font = .systemFont(ofSize: 12)

        innerStack.addArrangedSubview(imgView)
        innerStack.addArrangedSubview(uploadTitle)
        innerStack.addArrangedSubview(uploadSub)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: wrapper.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            card.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            card.heightAnchor.constraint(equalToConstant: 150),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

            innerStack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            innerStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        // Update dashed border path after layout
        card.tag = 999
        let tap = UITapGestureRecognizer(target: self, action: #selector(pickImageTapped))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        return wrapper
    }
    
    @objc private func pickImageTapped() {
        
        imagePicker.showImagePicker(allowCamera: true) { [weak self] img in
            guard let self = self else { return }

            self.selectedImage = img

            // Find imageView
            if let card = self.contentView.viewWithTag(999),
               let imgView = card.subviews
                    .compactMap({ $0 as? UIStackView })
                    .first?.arrangedSubviews
                    .compactMap({ $0 as? UIImageView })
                    .first {

                imgView.image = img
                imgView.contentMode = .scaleAspectFill
            }
        }
    }

    // MARK: - Input Section
    private func makeInputSection() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20

        // Group Title
        stack.addArrangedSubview(labeledField(title: "Group Title", placeholder: "Enter your group name", textField: groupNameField))

        // Destination
        let destWrapper = UIView()
        let destLabel = sectionLabel("Destination")
        let destBox = UIView()
        destBox.backgroundColor = .appCard
        destBox.layer.cornerRadius = 14
        destBox.layer.borderWidth  = 1
        destBox.layer.borderColor  = UIColor.appBorder.cgColor

        destinationTF.placeholder = "Where are you going?"
        destinationTF.attributedPlaceholder = NSAttributedString(
            string: "Where are you going?",
            attributes: [.foregroundColor: UIColor.appPlaceholder]
        )
        destinationTF.textColor = .white
        destinationTF.font = .systemFont(ofSize: 14)
        destinationTF.translatesAutoresizingMaskIntoConstraints = false

        let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
        plusIcon.tintColor = .white
        plusIcon.translatesAutoresizingMaskIntoConstraints = false
        plusIcon.widthAnchor.constraint(equalToConstant: 18).isActive = true

        destBox.addSubview(destinationTF)
        destBox.addSubview(plusIcon)
        destBox.translatesAutoresizingMaskIntoConstraints = false
        destLabel.translatesAutoresizingMaskIntoConstraints = false
        destWrapper.addSubview(destLabel)
        destWrapper.addSubview(destBox)

        NSLayoutConstraint.activate([
            destLabel.topAnchor.constraint(equalTo: destWrapper.topAnchor),
            destLabel.leadingAnchor.constraint(equalTo: destWrapper.leadingAnchor),

            destBox.topAnchor.constraint(equalTo: destLabel.bottomAnchor, constant: 8),
            destBox.leadingAnchor.constraint(equalTo: destWrapper.leadingAnchor),
            destBox.trailingAnchor.constraint(equalTo: destWrapper.trailingAnchor),
            destBox.heightAnchor.constraint(equalToConstant: 52),
            destBox.bottomAnchor.constraint(equalTo: destWrapper.bottomAnchor),

            destinationTF.leadingAnchor.constraint(equalTo: destBox.leadingAnchor, constant: 16),
            destinationTF.centerYAnchor.constraint(equalTo: destBox.centerYAnchor),
            destinationTF.trailingAnchor.constraint(equalTo: plusIcon.leadingAnchor, constant: -8),

            plusIcon.trailingAnchor.constraint(equalTo: destBox.trailingAnchor, constant: -16),
            plusIcon.centerYAnchor.constraint(equalTo: destBox.centerYAnchor)
        ])
        stack.addArrangedSubview(destWrapper)

        // Dates
        let dateRow = UIStackView()
        dateRow.axis = .horizontal
        dateRow.spacing = 12
        dateRow.distribution = .fillEqually
        dateRow.addArrangedSubview(makeDateField(title: "Start Date", isStart: true))
        dateRow.addArrangedSubview(makeDateField(title: "End Date", isStart: false))
        stack.addArrangedSubview(dateRow)

        return stack
    }
    
    
    @objc private func startDateTapped() {
        showDatePicker(isStart: true)
    }

    @objc private func endDateTapped() {
        showDatePicker(isStart: false)
    }

    private func showDatePicker(isStart: Bool) {
        let alert = UIAlertController(title: "Select Date", message: "\n\n\n\n\n\n", preferredStyle: .actionSheet)

        let picker = UIDatePicker()
        picker.datePickerMode = .date

        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }

        let today = Date()

        if isStart {
            // ✅ Start date cannot be in past
            picker.minimumDate = today
        } else {
            // ✅ End date must be after start date
            if !self.startDate.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"

                if let start = formatter.date(from: self.startDate) {
                    picker.minimumDate = start
                    picker.date = start.addingTimeInterval(86400) // +1 day
                }
            } else {
                // ❌ Prevent opening end date before start
                print("Select start date first")
                return
            }
        }

        picker.frame = CGRect(x: 0, y: 20, width: alert.view.bounds.width - 20, height: 160)
        alert.view.addSubview(picker)

        let done = UIAlertAction(title: "Done", style: .default) { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd MMM yyyy"

            let selected = picker.date

            if isStart {
                self.startDate = formatter.string(from: selected)
                self.startDateLabel.text = displayFormatter.string(from: selected)
                self.startDateLabel.textColor = .white

                // ✅ Auto reset end date if invalid
                if !self.endDate.isEmpty {
                    let end = formatter.date(from: self.endDate)!
                    if end < selected {
                        self.endDate = ""
                        self.endDateLabel.text = "Select date"
                        self.endDateLabel.textColor = .appPlaceholder
                    }
                }

            } else {
                self.endDate = formatter.string(from: selected)
                self.endDateLabel.text = displayFormatter.string(from: selected)
                self.endDateLabel.textColor = .white
            }
        }

        alert.addAction(done)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func makeDateField(title: String, isStart: Bool) -> UIView {
        let wrapper = UIView()
        let lbl = sectionLabel(title)

        let box = UIView()
        box.backgroundColor = .appCard
        box.layer.cornerRadius = 14
        box.layer.borderWidth = 1
        box.layer.borderColor = UIColor.appBorder.cgColor

        let dateLabel = isStart ? startDateLabel : endDateLabel
        dateLabel.text = "Select date"
        dateLabel.textColor = .appPlaceholder
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        let cal = UIImageView(image: UIImage(systemName: "calendar"))
        cal.tintColor = .white
        cal.translatesAutoresizingMaskIntoConstraints = false
        cal.widthAnchor.constraint(equalToConstant: 18).isActive = true

        box.addSubview(dateLabel)
        box.addSubview(cal)

        lbl.translatesAutoresizingMaskIntoConstraints = false
        box.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(lbl)
        wrapper.addSubview(box)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            box.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 8),
            box.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            box.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            box.heightAnchor.constraint(equalToConstant: 52),
            box.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

            dateLabel.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            dateLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),

            cal.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
            cal.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])

        // Tap Gesture
        let tap = UITapGestureRecognizer(target: self, action: isStart ? #selector(startDateTapped) : #selector(endDateTapped))
        box.addGestureRecognizer(tap)
        box.isUserInteractionEnabled = true

        return wrapper
    }
    
    private func makeDateField(title: String) -> UIView {
        let wrapper = UIView()
        let lbl = sectionLabel(title)
        let box = UIView()
        box.backgroundColor = .appCard
        box.layer.cornerRadius = 14
        box.layer.borderWidth = 1
        box.layer.borderColor = UIColor.appBorder.cgColor

        let placeholder = UILabel()
        placeholder.text = "Select date"
        placeholder.textColor = .appPlaceholder
        placeholder.font = .systemFont(ofSize: 13)
        placeholder.translatesAutoresizingMaskIntoConstraints = false

        let cal = UIImageView(image: UIImage(systemName: "calendar"))
        cal.tintColor = .white
        cal.translatesAutoresizingMaskIntoConstraints = false
        cal.widthAnchor.constraint(equalToConstant: 18).isActive = true

        box.addSubview(placeholder)
        box.addSubview(cal)

        lbl.translatesAutoresizingMaskIntoConstraints = false
        box.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(lbl)
        wrapper.addSubview(box)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            box.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 8),
            box.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            box.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            box.heightAnchor.constraint(equalToConstant: 52),
            box.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

            placeholder.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            placeholder.centerYAnchor.constraint(equalTo: box.centerYAnchor),

            cal.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
            cal.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])
        return wrapper
    }

    // MARK: - Size Section
    private func makeSizeSection() -> UIView {
        let wrapper = UIView()
        let lbl = sectionLabel("Maximum Group Size")

        let card = UIView()
        card.backgroundColor = .appCard
        card.layer.cornerRadius = 14

        let minusBtn = makeRoundBtn(icon: "minus", orange: false)
        minusBtn.addTarget(self, action: #selector(decrease), for: .touchUpInside)

        let plusBtn = makeRoundBtn(icon: "plus", orange: true)
        plusBtn.addTarget(self, action: #selector(increase), for: .touchUpInside)

        let personIcon = UIImageView(image: UIImage(systemName: "person.2.fill"))
        personIcon.tintColor = .appOrange
        personIcon.translatesAutoresizingMaskIntoConstraints = false
        personIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true

        sizeLabel.text = "\(groupSize) travelers"
        sizeLabel.textColor = .white
        sizeLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        let centerStack = UIStackView(arrangedSubviews: [personIcon, sizeLabel])
        centerStack.axis = .horizontal
        centerStack.spacing = 6
        centerStack.alignment = .center

        let row = UIStackView(arrangedSubviews: [minusBtn, centerStack, plusBtn])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        lbl.translatesAutoresizingMaskIntoConstraints = false
        card.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(lbl)
        wrapper.addSubview(card)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            card.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            card.heightAnchor.constraint(equalToConstant: 64),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return wrapper
    }

    // MARK: - Travel Style Section
    private func makeStyleSection() -> UIView {
        let wrapper = UIView()
        let lbl = sectionLabel("Travel Style")

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        for (i, style) in styles.enumerated() {
            let row = makeStyleRow(title: style, index: i)
            styleRows.append(row)
            stack.addArrangedSubview(row)
        }

        lbl.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(lbl)
        wrapper.addSubview(stack)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            stack.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        return wrapper
    }

    private func makeStyleRow(title: String, index: Int) -> UIView {
        let row = UIView()
        row.tag = index
        row.backgroundColor = .appCard
        row.layer.cornerRadius = 16
        row.layer.borderWidth = index == 0 ? 1.5 : 1
        row.layer.borderColor = index == 0 ? UIColor.appOrange.cgColor : UIColor.appBorder.cgColor
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let label = UILabel()
        label.text = title
        label.textColor = index == 0 ? .appOrange : .appGrayText
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false

        let radioImg = index == 0
            ? UIImage(systemName: "largecircle.fill.circle")
            : UIImage(systemName: "circle")
        let radio = UIImageView(image: radioImg)
        radio.tintColor = index == 0 ? .appOrange : .appGrayText
        radio.translatesAutoresizingMaskIntoConstraints = false
        radio.widthAnchor.constraint(equalToConstant: 22).isActive = true
        radio.heightAnchor.constraint(equalToConstant: 22).isActive = true

        row.addSubview(label)
        row.addSubview(radio)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: radio.leadingAnchor, constant: -8),

            radio.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            radio.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(styleTapped(_:)))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        return row
    }

    // MARK: - Continue Button
    private func makeContinueButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("Continue", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = .appOrange
        btn.layer.cornerRadius = 28
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return btn
    }

    // MARK: - Helpers
    private func sectionLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 14, weight: .semibold)
        return lbl
    }

    private func labeledField(title: String, placeholder: String, textField: PaddedTextField) -> UIView {
        let wrapper = UIView()
        let lbl = sectionLabel(title)

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.appPlaceholder]
        )
        textField.textColor = .white
        textField.font = .systemFont(ofSize: 14)
        textField.backgroundColor = .appCard
        textField.layer.cornerRadius = 14
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.appBorder.cgColor
        textField.padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        lbl.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(lbl)
        wrapper.addSubview(textField)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            textField.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 52),
            textField.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        return wrapper
    }

    private func makeRoundBtn(icon: String, orange: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: icon), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = orange ? .appOrange : .appCard
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 36).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return btn
    }

  

    @objc  func decrease() {
        if groupSize > 2 {
            groupSize -= 1
            sizeLabel.text = "\(groupSize) travelers"
        }
    }

    @objc  func increase() {
        if groupSize < 50 {
            groupSize += 1
            sizeLabel.text = "\(groupSize) travelers"
        }
    }

    @objc private func styleTapped(_ gesture: UITapGestureRecognizer) {
        guard let tapped = gesture.view else { return }
        let newIndex = tapped.tag
        guard newIndex != selectedStyle else { return }

        // Deselect old
        let old = styleRows[selectedStyle]
        old.layer.borderColor = UIColor.appBorder.cgColor
        old.layer.borderWidth = 1
        (old.subviews.first(where: { $0 is UILabel }) as? UILabel)?.textColor = .appGrayText
        (old.subviews.first(where: { $0 is UIImageView }) as? UIImageView)?.image = UIImage(systemName: "circle")
        (old.subviews.first(where: { $0 is UIImageView }) as? UIImageView)?.tintColor = .appGrayText

        // Select new
        selectedStyle = newIndex
        let newRow = styleRows[selectedStyle]
        newRow.layer.borderColor = UIColor.appOrange.cgColor
        newRow.layer.borderWidth = 1.5
        (newRow.subviews.first(where: { $0 is UILabel }) as? UILabel)?.textColor = .appOrange
        (newRow.subviews.first(where: { $0 is UIImageView }) as? UIImageView)?.image = UIImage(systemName: "largecircle.fill.circle")
        (newRow.subviews.first(where: { $0 is UIImageView }) as? UIImageView)?.tintColor = .appOrange
    }

    @objc private func continueTapped() {
        
        // Validate image
        guard let image = selectedImage,
              let data = image.jpegData(compressionQuality: 0.7) else {
            print("Please select image")
            return
        }

        // Validate required fields
        guard let groupTitle = groupNameField.text, !groupTitle.isEmpty else {
            print("Enter group title")
            return
        }

        guard let destination = destinationTF.text, !destination.isEmpty else {
            print("Enter destination")
            return
        }

        AppLoader.show()

        // Upload image
        uploadImg(data) { [weak self] imageName in
            guard let self = self else { return }

            // ✅ Correct values mapping
            self.request.coverImage = imageName
            self.request.groupTitle = groupTitle
            self.request.destination = destination
            
            // ⚠️ You need to implement date selection (currently missing)
            self.request.startDate = self.startDate
            self.request.endDate = self.endDate
            
            // ✅ Correct group size
            self.request.maxGroupSize = self.groupSize
            
            // ✅ Correct travel style
            self.request.travelStyle = self.styles[self.selectedStyle]
            
            self.request.isActive = true

            // API call
            self.request.createGroupAPi {code, errMsg, errCode in
                AppLoader.hide()

                DispatchQueue.main.async {
                    
                    
                    if errCode == 200 {
                        self.pushVC(InviteVc.self, from: .Home) { vc in
                            
                            vc.joinCode = code ?? ""
                        }
                    } else {
                        print(errMsg)
                    }
                }
            }
        }
    }

    // MARK: - Dashed border layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let card = contentView.viewWithTag(999) {
            if let dash = card.layer.sublayers?.first(where: { $0 is CAShapeLayer }) as? CAShapeLayer {
                let rect = card.bounds.insetBy(dx: 12, dy: 12)
                dash.path  = UIBezierPath(roundedRect: rect, cornerRadius: 10).cgPath
                dash.frame = card.bounds
            }
        }
    }
}

// MARK: - PaddedTextField
final class PaddedTextField: UITextField {
    var padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }
}

extension CreateGroupViewController {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
}
