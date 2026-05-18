
//
//  CreateGroupViewController.swift
//  TravelDate
//

import UIKit
import MapKit

class CreateGroupViewController: BaseClassVc {

    // MARK: - State
    
    private var groupSize = 4
    private let styles = ["Partygoers", "Adventure travelers", "Cultural travelers", "Leisure travelers"]
    var selectedStyles: Set<Int> = []
    var selectedImage: UIImage?
    private var startDate: String = ""
    private var endDate: String = ""

    // MARK: - UI References
    private let scrollView  = UIScrollView()
    private let contentView = UIView()
    private let formCard    = UIView()   // ← inner dark card

    private let groupNameField  = PaddedTextField()
    let destinationTF           = UITextField()
    private let sizeLabel       = UILabel()
    private var styleRows       = [UIView]()
    private let startDateLabel  = UILabel()
    private let endDateLabel    = UILabel()
    var locationView: LocationSearchView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.09, green: 0.10, blue: 0.11, alpha: 1) // outer bg
        addGradient()
        setupScrollView()
        buildFormCard()
        setupLocationView()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        locationView.isHidden = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update dashed border
        if let card = formCard.viewWithTag(999) {
            if let dash = card.layer.sublayers?
                .first(where: { $0 is CAShapeLayer }) as? CAShapeLayer {
                let rect = card.bounds.insetBy(dx: 12, dy: 12)
                dash.path  = UIBezierPath(roundedRect: rect, cornerRadius: 10).cgPath
                dash.frame = card.bounds
            }
        }
    }

    // MARK: - Header
    private func setupHeader() {
        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backBtn.tintColor       = .white
        backBtn.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        backBtn.layer.cornerRadius = 18
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        let titleLbl = UILabel()
        titleLbl.text      = "Create a Group"
        titleLbl.textColor = .white
        titleLbl.setFont(.medium, size: 18.0)

        [backBtn, titleLbl].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backBtn.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            titleLbl.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - ScrollView
    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -128),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    // MARK: - Form Card (inner container)
    private func buildFormCard() {
        // Outer card
        formCard.backgroundColor    = UIColor(red: 0.082, green: 0.090, blue: 0.094, alpha: 1) // #151718
        formCard.layer.cornerRadius = 26
        formCard.layer.borderWidth  = 1
        formCard.layer.borderColor  = UIColor(red: 0.110, green: 0.118, blue: 0.133, alpha: 1).cgColor
        formCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(formCard)

        NSLayoutConstraint.activate([
            formCard.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: 16),
            formCard.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: 16),
            formCard.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -16),
            formCard.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -16),
        ])

        // Inner stack
        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        formCard.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(
                equalTo: formCard.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(
                equalTo: formCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(
                equalTo: formCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(
                equalTo: formCard.bottomAnchor, constant: -24),
        ])

        stack.addArrangedSubview(makeCoverSection())
        stack.addArrangedSubview(makeInputSection())
        stack.addArrangedSubview(makeSizeSection())
        stack.addArrangedSubview(makeStyleSection())

        // Continue button
        let btn = makeContinueButton()
        view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            btn.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            btn.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            btn.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    // MARK: - Location View
    private func setupLocationView() {
        locationView = LocationSearchView()
        locationView.isHidden = true
        locationView.attach(to: destinationTF)
        locationView.onLocationSelected = { [weak self] address, cord in
         tuple = (address,Double(cord.latitude),Double(cord.longitude))
            self?.destinationTF.text = address
            self?.locationView.isHidden = true
        }
        view.addSubview(locationView)
        locationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationView.topAnchor.constraint(
                equalTo: destinationTF.bottomAnchor, constant: 8),
            locationView.leadingAnchor.constraint(
                equalTo: destinationTF.leadingAnchor),
            locationView.trailingAnchor.constraint(
                equalTo: destinationTF.trailingAnchor),
            locationView.heightAnchor.constraint(equalToConstant: 250),
        ])
        destinationTF.addTarget(self, action: #selector(openSearch), for: .editingDidBegin)
    }

    // MARK: - Cover Photo Section
    private func makeCoverSection() -> UIView {
        let wrapper = UIView()
        let titleLbl = sectionLabel("Add Cover Photo")

        let card = UIView()
        card.backgroundColor  = UIColor.white.withAlphaComponent(0.04)
        card.layer.cornerRadius = 20
        card.tag = 999

        // Dashed border
        let dash = CAShapeLayer()
        dash.strokeColor    = UIColor.appOrange.cgColor
        dash.fillColor      = UIColor.clear.cgColor
        dash.lineWidth      = 1.2
        dash.lineDashPattern = [10, 6]
        card.layer.addSublayer(dash)

        let imgView = UIImageView(image: UIImage(systemName: "photo.on.rectangle"))
        imgView.tintColor    = .appOrange
        imgView.contentMode  = .scaleAspectFit
        imgView.tag          = 1001

        let uploadTitle = UILabel()
        uploadTitle.text      = "Upload Cover Photo"
        uploadTitle.textColor = .white
        uploadTitle.setFont(.semiBold, size: 14.0)

        let uploadSub = UILabel()
        uploadSub.text      = "JPG, PNG (Max 5MB)"
        uploadSub.textColor = .appGrayText
        uploadSub.setFont(.regular, size: 12.0)

        let innerStack = UIStackView(
            arrangedSubviews: [imgView, uploadTitle, uploadSub])
        innerStack.axis      = .vertical
        innerStack.alignment = .center
        innerStack.spacing   = 6

        [imgView, innerStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        imgView.widthAnchor.constraint(equalToConstant: 28).isActive  = true
        imgView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        card.addSubview(innerStack)
        innerStack.translatesAutoresizingMaskIntoConstraints = false

        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.translatesAutoresizingMaskIntoConstraints     = false
        wrapper.addSubview(titleLbl)
        wrapper.addSubview(card)

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            titleLbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            card.topAnchor.constraint(
                equalTo: titleLbl.bottomAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            card.heightAnchor.constraint(equalToConstant: 150),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

            innerStack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            innerStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        card.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(pickImageTapped)))
        card.isUserInteractionEnabled = true
        return wrapper
    }

    // MARK: - Input Section
    private func makeInputSection() -> UIView {
        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 20

        // Group Title
        stack.addArrangedSubview(
            labeledField(title: "Group Title",
                         placeholder: "Enter your group name",
                         textField: groupNameField))

        // Destination
        stack.addArrangedSubview(makeDestinationField())

        // Dates
        let dateRow = UIStackView()
        dateRow.axis         = .horizontal
        dateRow.spacing      = 12
        dateRow.distribution = .fillEqually
        dateRow.addArrangedSubview(makeDateField(title: "Start Date", isStart: true))
        dateRow.addArrangedSubview(makeDateField(title: "End Date",   isStart: false))
        stack.addArrangedSubview(dateRow)

        return stack
    }

    private func makeDestinationField() -> UIView {
        let wrapper = UIView()
        let lbl  = sectionLabel("Destination")
        let box  = fieldBox()

        destinationTF.attributedPlaceholder = NSAttributedString(
            string: "Where are you going?",
            attributes: [.foregroundColor: UIColor.appPlaceholder])
        destinationTF.textColor = .white
        destinationTF.setFont(.regular, size: 14)

        let icon = UIImageView(image: UIImage(named: "loc"))
        icon.tintColor = .white

        [destinationTF, icon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview($0)
        }
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true

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

            destinationTF.leadingAnchor.constraint(
                equalTo: box.leadingAnchor, constant: 16),
            destinationTF.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            destinationTF.trailingAnchor.constraint(
                equalTo: icon.leadingAnchor, constant: -8),

            icon.trailingAnchor.constraint(
                equalTo: box.trailingAnchor, constant: -16),
            icon.centerYAnchor.constraint(equalTo: box.centerYAnchor),
        ])
        return wrapper
    }

    private func makeDateField(title: String, isStart: Bool) -> UIView {
        let wrapper  = UIView()
        let lbl      = sectionLabel(title)
        let box      = fieldBox()
        let dateLabel = isStart ? startDateLabel : endDateLabel

        dateLabel.text      = "Select date"
        dateLabel.textColor = .appPlaceholder
        dateLabel.setFont(.medium, size: 12.0)

        let cal = UIImageView(image: UIImage(systemName: "calendar"))
        cal.tintColor = .white

        [dateLabel, cal].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            box.addSubview($0)
        }
        cal.widthAnchor.constraint(equalToConstant: 18).isActive = true

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

            dateLabel.leadingAnchor.constraint(
                equalTo: box.leadingAnchor, constant: 14),
            dateLabel.centerYAnchor.constraint(equalTo: box.centerYAnchor),

            cal.trailingAnchor.constraint(
                equalTo: box.trailingAnchor, constant: -14),
            cal.centerYAnchor.constraint(equalTo: box.centerYAnchor),
        ])

        let tap = UITapGestureRecognizer(
            target: self,
            action: isStart ? #selector(startDateTapped) : #selector(endDateTapped))
        box.addGestureRecognizer(tap)
        box.isUserInteractionEnabled = true
        return wrapper
    }

    // MARK: - Size Section
    private func makeSizeSection() -> UIView {
        let wrapper = UIView()
        let lbl     = sectionLabel("Maximum Group Size")
        let card    = fieldBox()

        let minusBtn = makeRoundBtn(icon: "minus", orange: false)
        minusBtn.addTarget(self, action: #selector(decrease), for: .touchUpInside)

        let plusBtn = makeRoundBtn(icon: "plus", orange: true)
        plusBtn.addTarget(self, action: #selector(increase), for: .touchUpInside)

        let personIcon = UIImageView(image: UIImage(systemName: "person.2.fill"))
        personIcon.tintColor = .appOrange
        personIcon.translatesAutoresizingMaskIntoConstraints = false
        personIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true

        sizeLabel.text      = "\(groupSize) travelers"
        sizeLabel.textColor = .white
        sizeLabel.setFont(.medium, size: 14.0)

        let center = UIStackView(arrangedSubviews: [personIcon, sizeLabel])
        center.axis      = .horizontal
        center.spacing   = 6
        center.alignment = .center

        let row = UIStackView(arrangedSubviews: [minusBtn, center, plusBtn])
        row.axis         = .horizontal
        row.distribution = .equalSpacing
        row.alignment    = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)

        lbl.translatesAutoresizingMaskIntoConstraints  = false
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

            row.leadingAnchor.constraint(
                equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(
                equalTo: card.trailingAnchor, constant: -16),
            row.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
        return wrapper
    }

    // MARK: - Travel Style Section
    private func makeStyleSection() -> UIView {
        let wrapper = UIView()
        let lbl     = sectionLabel("Travel Style")

        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 8

        for (i, style) in styles.enumerated() {
            let row = makeStyleRow(title: style, index: i)
            styleRows.append(row)
            stack.addArrangedSubview(row)
        }

        lbl.translatesAutoresizingMaskIntoConstraints   = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(lbl)
        wrapper.addSubview(stack)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            stack.topAnchor.constraint(
                equalTo: lbl.bottomAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
        return wrapper
    }

    private func makeStyleRow(title: String, index: Int) -> UIView {
        let selected = index == 0
        let row = UIView()
        row.tag               = index
        row.backgroundColor   = .appCard
        row.layer.cornerRadius = 16
        row.layer.borderWidth  = selected ? 1.5 : 1
        row.layer.borderColor  = selected
            ? UIColor.appOrange.cgColor
            : UIColor.appBorder.cgColor
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 54).isActive = true

        let label = UILabel()
        label.text      = title
        label.textColor = selected ? .appOrange : .appGrayText
        label.setFont(.medium, size: 13.0)

        let radio = UIImageView(image: UIImage(systemName:
            selected ? "largecircle.fill.circle" : "circle"))
        radio.tintColor = selected ? .appOrange : .appGrayText

        [label, radio].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview($0)
        }
        radio.widthAnchor.constraint(equalToConstant: 22).isActive  = true
        radio.heightAnchor.constraint(equalToConstant: 22).isActive = true

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(
                equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.trailingAnchor.constraint(
                equalTo: radio.leadingAnchor, constant: -8),

            radio.trailingAnchor.constraint(
                equalTo: row.trailingAnchor, constant: -16),
            radio.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])

        row.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(styleTapped(_:))))
        row.isUserInteractionEnabled = true
        return row
    }

    // MARK: - Continue Button
    private func makeContinueButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("Continue", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.setFont(.medium, size: 16.0)
        btn.backgroundColor    = .appOrange
        btn.layer.cornerRadius = 28
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        return btn
    }

    // MARK: - Reusable Helpers

    /// Standard dark field box
    private func fieldBox() -> UIView {
        let v = UIView()
        v.backgroundColor   = .appCard
        v.layer.cornerRadius = 14
        v.layer.borderWidth  = 1
        v.layer.borderColor  = UIColor.appBorder.cgColor
        return v
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text      = text
        l.textColor = .white
        l.setFont(.semiBold, size: 14.0)
        return l
    }

    private func labeledField(title: String,
                               placeholder: String,
                               textField: PaddedTextField) -> UIView {
        let wrapper = UIView()
        let lbl     = sectionLabel(title)

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.appPlaceholder])
        textField.textColor          = .white
        textField.setFont(.regular, size: 14)
        textField.backgroundColor    = .appCard
        textField.layer.cornerRadius = 14
        textField.layer.borderWidth  = 1
        textField.layer.borderColor  = UIColor.appBorder.cgColor
        textField.padding            = UIEdgeInsets(
            top: 0, left: 16, bottom: 0, right: 16)

        lbl.translatesAutoresizingMaskIntoConstraints       = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(lbl)
        wrapper.addSubview(textField)

        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: wrapper.topAnchor),
            lbl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),

            textField.topAnchor.constraint(
                equalTo: lbl.bottomAnchor, constant: 8),
            textField.leadingAnchor.constraint(
                equalTo: wrapper.leadingAnchor),
            textField.trailingAnchor.constraint(
                equalTo: wrapper.trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 52),
            textField.bottomAnchor.constraint(
                equalTo: wrapper.bottomAnchor),
        ])
        return wrapper
    }

    private func makeRoundBtn(icon: String, orange: Bool) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(
            UIImage(named: icon)?.withRenderingMode(.alwaysOriginal),
            for: .normal)
        btn.backgroundColor    = orange ? .appOrange : .appCard
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 36).isActive  = true
        btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return btn
    }

    // MARK: - Actions
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc func openSearch() {
        locationView.isHidden = false
        view.bringSubviewToFront(locationView)
    }

    @objc private func pickImageTapped() {
        imagePicker.showImagePicker(allowCamera: true) { [weak self] img in
            guard let self else { return }
            self.selectedImage = img
            if let card   = self.formCard.viewWithTag(999),
               let stack  = card.subviews.compactMap({ $0 as? UIStackView }).first,
               let imgView = stack.arrangedSubviews
                    .compactMap({ $0 as? UIImageView }).first {
                imgView.image       = img
                imgView.contentMode = .scaleAspectFill
            }
        }
    }

    @objc private func startDateTapped() { showDatePicker(isStart: true)  }
    @objc private func endDateTapped()   { showDatePicker(isStart: false) }

    private func showDatePicker(isStart: Bool) {
        let alert = UIAlertController(
            title: "Select Date", message: "\n\n\n\n\n\n",
            preferredStyle: .actionSheet)

        let picker = UIDatePicker()
        picker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }

        if isStart {
            picker.minimumDate = Date()
        } else {
            guard !startDate.isEmpty else { return }
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            if let s = fmt.date(from: startDate) {
                picker.minimumDate = s
                picker.date = s.addingTimeInterval(86400)
            }
        }

        picker.frame = CGRect(
            x: 0, y: 20,
            width: alert.view.bounds.width - 20, height: 160)
        alert.view.addSubview(picker)

        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            guard let self else { return }
            let fmt  = DateFormatter(); fmt.dateFormat  = "yyyy-MM-dd"
            let disp = DateFormatter(); disp.dateFormat = "dd MMM yyyy"
            let sel  = picker.date
            if isStart {
                self.startDate = fmt.string(from: sel)
                self.startDateLabel.text      = disp.string(from: sel)
                self.startDateLabel.textColor = .white
                if !self.endDate.isEmpty,
                   let e = fmt.date(from: self.endDate), e < sel {
                    self.endDate = ""
                    self.endDateLabel.text      = "Select date"
                    self.endDateLabel.textColor = .appPlaceholder
                }
            } else {
                self.endDate = fmt.string(from: sel)
                self.endDateLabel.text      = disp.string(from: sel)
                self.endDateLabel.textColor = .white
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = alert.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(
                x: view.bounds.midX, y: view.bounds.midY,
                width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    @objc func decrease() {
        if groupSize > 2 {
            groupSize -= 1
            sizeLabel.text = "\(groupSize) travelers"
        }
    }

    @objc func increase() {
        if groupSize < 50 {
            groupSize += 1
            sizeLabel.text = "\(groupSize) travelers"
        }
    }

    @objc private func styleTapped(_ g: UITapGestureRecognizer) {
        guard let row = g.view else { return }
        let i         = row.tag
        let label     = row.subviews.compactMap { $0 as? UILabel }.first
        let imageView = row.subviews.compactMap { $0 as? UIImageView }.first

        if selectedStyles.contains(i) {
            selectedStyles.remove(i)
            row.layer.borderColor  = UIColor.appBorder.cgColor
            row.layer.borderWidth  = 1
            label?.textColor       = .appGrayText
            imageView?.image       = UIImage(systemName: "circle")
            imageView?.tintColor   = .appGrayText
        } else {
            selectedStyles.insert(i)
            row.layer.borderColor  = UIColor.appOrange.cgColor
            row.layer.borderWidth  = 1.5
            label?.textColor       = .appOrange
            imageView?.image       = UIImage(systemName: "largecircle.fill.circle")
            imageView?.tintColor   = .appOrange
        }
    }

    @objc private func continueTapped() {
        guard let image = selectedImage,
              let data  = image.jpegData(compressionQuality: 0.7) else {
            showAlert(message: "Please select a cover photo"); return
        }
        guard let title = groupNameField.text, !title.isEmpty else {
            showAlert(message: "Enter group title"); return
        }
        guard let dest = destinationTF.text, !dest.isEmpty else {
            showAlert(message: "Enter destination"); return
        }

        AppLoader.show()
        uploadImg(data) { [weak self] imageName in
            guard let self else { return }
            self.request.coverImage   = imageName
            self.request.groupTitle   = title
            self.request.destination  = dest
            self.request.startDate    = self.startDate
            self.request.endDate      = self.endDate
            self.request.maxGroupSize = self.groupSize
            self.request.travelStyle  = self.styles
            self.request.isActive     = true
            self.request.latitude = "\(tuple?.lat ?? 0)"
            self.request.longitude = "\(tuple?.lng ?? 0)"
            self.request.location_string = tuple?.title ?? ""
            self.request.createGroupAPi { code, _, errCode in
                AppLoader.hide()
                DispatchQueue.main.async {
                    if errCode == 200 {
                        self.pushVC(InviteVc.self, from: .Home) {
                            $0.joinCode = code ?? ""
                        }
                    }
                }
            }
        }
    }
}

// MARK: - IBAction back
extension CreateGroupViewController {
    @IBAction func btnBack(_ sender: UIButton) { super.backTapped() }
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


