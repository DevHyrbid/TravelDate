

//
//  CreateGroupViewController.swift
//  TravelDate
//
//  Complete single file version matching Figma styles
//

import UIKit

// MARK: - THEME

//enum Theme {
//    static let bg = UIColor(hex: "#0E0E0E")
//    static let card = UIColor(hex: "#1A1A1A")
//    static let orange = UIColor(hex: "#FF6B00")
//    static let textPrimary = UIColor(hex: "#FFFFFF")
//    static let textSecondary = UIColor(hex: "#9E9E9E")
//    static let border = UIColor(hex: "#2A2A2A")
//    static let placeholder = UIColor(hex: "#6F6F6F")
//}

    /*
//
//  CreateGroupViewController.swift
//  TravelDate
//
//  Complete single file version matching Figma styles
//

import UIKit

// MARK: - THEME


// MARK: - CREATE GROUP VC

class CreateGroupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let scroll = UIScrollView()
    private let content = UIView()
    private let coverImageView = UIImageView()
    private let coverIcon = UIImageView()
    private let coverLabel = UILabel()
    private var startDateValue: Date?
    private var endDateValue: Date?

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = .white
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Create a Group"
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return l
    }()

    private let coverCard = UIView()
    private let dashedView = UIView()

    private let groupTitle = SectionLabel("Group Title")
    private let groupField = InputField("Enter your group name")

    private let destinationTitle = SectionLabel("Destination")
    private let destinationField = InputField("Where are you going?")

    private let startDate = SectionLabel("Start Date")
    private let startField = InputField("Select date")

    private let endDate = SectionLabel("End Date")
    private let endField = InputField("Select date")

    private let sizeTitle = SectionLabel("Maximum Group Size")
    private let sizeContainer = UIView()

    private let minus = UIButton()
    private let plus = UIButton()
    private let sizeLabel = UILabel()

    private let travelTitle = SectionLabel("Travel Style")
    private let stack = UIStackView()
    private var groupSize = 4
    private var selectedIndex = 0
    private var styleViews: [StyleButton] = []

    private let continueBtn: UIButton = {
        let b = UIButton()
        b.setTitle("Continue", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = Theme.orange
        b.layer.cornerRadius = 28
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bg
        setupUI()
        layout()
    }

    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(scroll)
        scroll.addSubview(content)

        coverIcon.image = UIImage(systemName: "photo.on.rectangle")
        coverIcon.tintColor = Theme.orange

        coverLabel.text = "Upload Cover Photo"
        coverLabel.textColor = .white
        coverLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        [coverIcon, coverLabel, coverImageView].forEach {
            dashedView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 16
        coverImageView.isHidden = true

        [titleLabel, coverCard, groupTitle, groupField,
         destinationTitle, destinationField,
         startDate, startField, endDate, endField,
         sizeTitle, sizeContainer,
         travelTitle, stack].forEach { content.addSubview($0) }

        view.addSubview(continueBtn)

        coverCard.backgroundColor = Theme.card
        coverCard.layer.cornerRadius = 20

        dashedView.layer.cornerRadius = 16
        coverCard.addSubview(dashedView)

        minus.setTitle("−", for: .normal)
        minus.backgroundColor = Theme.card
        minus.layer.cornerRadius = 12

        plus.setTitle("+", for: .normal)
        plus.backgroundColor = Theme.orange
        plus.layer.cornerRadius = 12

        sizeLabel.text = "4 travelers"
        sizeLabel.textColor = .white

        [minus, plus, sizeLabel].forEach { sizeContainer.addSubview($0) }

        stack.axis = .vertical
        stack.spacing = 10

        ["Partygoers", "Adventure travelers", "Cultural travelers", "Leisure travelers"].enumerated().forEach { index, title in
            let v = StyleButton(title)
            v.isSelectedStyle = index == 0
            v.tag = index
            stack.addArrangedSubview(v)
            styleViews.append(v)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addDashedBorder()
    }

    private func addDashedBorder() {
        dashedView.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })
        let shape = CAShapeLayer()
        shape.strokeColor = Theme.orange.cgColor
        shape.lineWidth = 1.2
        shape.lineDashPattern = [10, 6]
        shape.fillColor = UIColor.clear.cgColor
        shape.path = UIBezierPath(roundedRect: dashedView.bounds, cornerRadius: 16).cgPath
        dashedView.layer.addSublayer(shape)
    }

    private func layout() {
        [scroll, content, titleLabel, coverCard, dashedView,
         groupTitle, groupField, destinationTitle, destinationField,
         startDate, startField, endDate, endField,
         sizeTitle, sizeContainer, minus, plus, sizeLabel,
         travelTitle, stack, continueBtn].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor),

            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            coverCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            coverCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            coverCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            coverCard.heightAnchor.constraint(equalToConstant: 150),

            dashedView.topAnchor.constraint(equalTo: coverCard.topAnchor, constant: 16),
            dashedView.bottomAnchor.constraint(equalTo: coverCard.bottomAnchor, constant: -16),
            dashedView.leadingAnchor.constraint(equalTo: coverCard.leadingAnchor, constant: 16),
            dashedView.trailingAnchor.constraint(equalTo: coverCard.trailingAnchor, constant: -16),

            groupTitle.topAnchor.constraint(equalTo: coverCard.bottomAnchor, constant: 20),
            groupTitle.leadingAnchor.constraint(equalTo: coverCard.leadingAnchor),

            groupField.topAnchor.constraint(equalTo: groupTitle.bottomAnchor, constant: 8),
            groupField.leadingAnchor.constraint(equalTo: coverCard.leadingAnchor),
            groupField.trailingAnchor.constraint(equalTo: coverCard.trailingAnchor),
            groupField.heightAnchor.constraint(equalToConstant: 50),

            destinationTitle.topAnchor.constraint(equalTo: groupField.bottomAnchor, constant: 16),
            destinationTitle.leadingAnchor.constraint(equalTo: groupTitle.leadingAnchor),

            destinationField.topAnchor.constraint(equalTo: destinationTitle.bottomAnchor, constant: 8),
            destinationField.leadingAnchor.constraint(equalTo: groupField.leadingAnchor),
            destinationField.trailingAnchor.constraint(equalTo: groupField.trailingAnchor),
            destinationField.heightAnchor.constraint(equalToConstant: 50),

            startDate.topAnchor.constraint(equalTo: destinationField.bottomAnchor, constant: 16),
            startDate.leadingAnchor.constraint(equalTo: groupTitle.leadingAnchor),

            startField.topAnchor.constraint(equalTo: startDate.bottomAnchor, constant: 8),
            startField.leadingAnchor.constraint(equalTo: groupField.leadingAnchor),
            startField.widthAnchor.constraint(equalTo: content.widthAnchor, multiplier: 0.44),
            startField.heightAnchor.constraint(equalToConstant: 50),

            endDate.topAnchor.constraint(equalTo: destinationField.bottomAnchor, constant: 16),
            endDate.trailingAnchor.constraint(equalTo: groupField.trailingAnchor),

            endField.topAnchor.constraint(equalTo: endDate.bottomAnchor, constant: 8),
            endField.trailingAnchor.constraint(equalTo: groupField.trailingAnchor),
            endField.widthAnchor.constraint(equalTo: content.widthAnchor, multiplier: 0.44),
            endField.heightAnchor.constraint(equalToConstant: 50),

            sizeTitle.topAnchor.constraint(equalTo: startField.bottomAnchor, constant: 16),
            sizeTitle.leadingAnchor.constraint(equalTo: groupTitle.leadingAnchor),

            sizeContainer.topAnchor.constraint(equalTo: sizeTitle.bottomAnchor, constant: 8),
            sizeContainer.leadingAnchor.constraint(equalTo: groupField.leadingAnchor),
            sizeContainer.trailingAnchor.constraint(equalTo: groupField.trailingAnchor),
            sizeContainer.heightAnchor.constraint(equalToConstant: 50),

            minus.leadingAnchor.constraint(equalTo: sizeContainer.leadingAnchor, constant: 12),
            minus.centerYAnchor.constraint(equalTo: sizeContainer.centerYAnchor),
            minus.widthAnchor.constraint(equalToConstant: 36),
            minus.heightAnchor.constraint(equalToConstant: 36),

            plus.trailingAnchor.constraint(equalTo: sizeContainer.trailingAnchor, constant: -12),
            plus.centerYAnchor.constraint(equalTo: sizeContainer.centerYAnchor),
            plus.widthAnchor.constraint(equalToConstant: 36),
            plus.heightAnchor.constraint(equalToConstant: 36),

            sizeLabel.centerXAnchor.constraint(equalTo: sizeContainer.centerXAnchor),
            sizeLabel.centerYAnchor.constraint(equalTo: sizeContainer.centerYAnchor),

            travelTitle.topAnchor.constraint(equalTo: sizeContainer.bottomAnchor, constant: 16),
            travelTitle.leadingAnchor.constraint(equalTo: groupTitle.leadingAnchor),

            stack.topAnchor.constraint(equalTo: travelTitle.bottomAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: groupField.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: groupField.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -100),

            continueBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueBtn.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
}

*/
//
//  CreateGroupView.swift
//  Pixel‑Perfect Figma Match
//

import SwiftUI

// MARK: - Theme
struct AppColors {
    static let bg = Color(hex: "#0E0E0E")
    static let card = Color(hex: "#1A1A1A")
    static let orange = Color(hex: "#FF6B00")
    static let white = Color(hex: "#FFFFFF")
    static let grayText = Color(hex: "#9E9E9E")
    static let placeholder = Color(hex: "#6F6F6F")
    static let border = Color(hex: "#2A2A2A")
}

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(.sRGB,
                  red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255,
                  opacity: 1)
    }
}

// MARK: - Main Screen
struct CreateGroupView: View {
    @State private var groupName = ""
    @State private var destination = ""
    @State private var groupSize = 4
    @State private var selectedStyle = 0

    let styles = ["Partygoers","Adventure travelers","Cultural travelers","Leisure travelers"]

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        coverSection
                        inputSection
                        sizeSection
                        travelSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
                continueButton
            }
        }
    }

    // MARK: Header
    private var header: some View {
        HStack {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
            Spacer()
            Text("Create a Group")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
            Spacer()
            Color.clear.frame(width: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: Cover Photo
    private var coverSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add Cover photo")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.card)

                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [10,6]))
                    .foregroundColor(AppColors.orange)
                    .padding(16)

                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(AppColors.orange)
                    Text("Upload Cover Photo")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                    Text("JPG, PNG (Max 5MB)")
                        .foregroundColor(AppColors.grayText)
                        .font(.system(size: 12))
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: Inputs
    private var inputSection: some View {
        VStack(spacing: 20) {
            inputField(title: "Group Title", placeholder: "Enter your group name", text: $groupName)
            destinationField

            HStack(spacing: 12) {
                dateField(title: "Start Date")
                dateField(title: "End Date")
            }
        }
    }

    private func inputField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).foregroundColor(.white).font(.system(size: 14, weight: .semibold))
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(AppColors.placeholder))
                .padding()
                .foregroundColor(.white)
                .background(AppColors.card)
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border))
        }
    }

    private var destinationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Destination").foregroundColor(.white).font(.system(size: 14, weight: .semibold))
            HStack {
                TextField("", text: $destination, prompt: Text("Where are you going?").foregroundColor(AppColors.placeholder))
                    .foregroundColor(.white)
                Image(systemName: "plus")
                    .foregroundColor(.white)
            }
            .padding()
            .background(AppColors.card)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border))
        }
    }

    private func dateField(title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).foregroundColor(.white).font(.system(size: 14, weight: .semibold))
            HStack {
                Text("Select date").foregroundColor(AppColors.placeholder)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(.white)
            }
            .padding()
            .background(AppColors.card)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border))
        }
    }

    // MARK: Size Section
    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Maximum Group Size").foregroundColor(.white).font(.system(size: 14, weight: .semibold))
            HStack {
                Button(action: { if groupSize > 2 { groupSize -= 1 } }) {
                    Image(systemName: "minus").foregroundColor(.white).frame(width: 36, height: 36)
                }
                .background(AppColors.card)
                .cornerRadius(12)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill").foregroundColor(AppColors.orange)
                    Text("\(groupSize) travelers").foregroundColor(.white).font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                Button(action: { if groupSize < 50 { groupSize += 1 } }) {
                    Image(systemName: "plus").foregroundColor(.white).frame(width: 36, height: 36)
                }
                .background(AppColors.orange)
                .cornerRadius(12)
            }
            .padding()
            .background(AppColors.card)
            .cornerRadius(14)
        }
    }

    // MARK: Travel Style
    private var travelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Travel Style").foregroundColor(.white).font(.system(size: 14, weight: .semibold))
            ForEach(styles.indices, id: \.self) { i in
                HStack {
                    Text(styles[i])
                        .foregroundColor(selectedStyle == i ? AppColors.orange : AppColors.grayText)
                    Spacer()
                    Image(systemName: selectedStyle == i ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(selectedStyle == i ? AppColors.orange : AppColors.grayText)
                }
                .padding()
                .background(AppColors.card)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(selectedStyle == i ? AppColors.orange : AppColors.border, lineWidth: selectedStyle == i ? 1.5 : 1))
                .onTapGesture { selectedStyle = i }
            }
        }
    }

    // MARK: Continue Button
    private var continueButton: some View {
        Button("Continue") {}
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.orange)
            .cornerRadius(28)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
    }
}
