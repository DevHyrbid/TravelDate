

//
//  GetVerifiedVc.swift
//  TravelDate
//

import UIKit

// MARK: - GetVerifiedVc

class GetVerifiedVc: BaseClassVc {

    // MARK: - Properties

    var frontImage: UIImage?
    var backImage:  UIImage?
    var selfieImage: UIImage?

    var frontImageName  = ""
    var backImageName   = ""
    var selfieImageName = ""

    private var dashLayersAdded = false

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#111111")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // --- Profile ---
    private lazy var profileCard: UIView        = makeCard()
    private lazy var progressRingView           = CircularProgressView()
    private lazy var imgProfile: UIImageView    = {
        let iv = UIImageView()
        iv.contentMode    = .scaleAspectFill
        iv.clipsToBounds  = true
        iv.backgroundColor = UIColor(hex: "#2A2A2A")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private lazy var lblProgressPercent: UILabel = {
        let l = makeLabel("0%", font: .bold, size: 11, color: .white)
        l.textAlignment       = .center
        l.backgroundColor     = UIColor(hex: "#FF6B35")
        l.layer.cornerRadius  = 10
        l.clipsToBounds       = true
        return l
    }()
    private lazy var lblName: UILabel     = makeLabel("", font: .bold,    size: 20, color: .white,                  align: .center)
    private lazy var lblUsername: UILabel = makeLabel("", font: .regular, size: 14, color: UIColor(hex: "#9B9B9B"), align: .center)

    // --- Why Get Verified ---
    private lazy var whySectionView: UIView = UIView()

    // --- Verification Steps ---
    private lazy var stepsSectionView: UIView   = UIView()
    private lazy var stepsProgressLabel: UILabel = makeLabel("0/2 Complete", font: .regular, size: 13, color: UIColor(hex: "#9B9B9B"), align: .right)
    private lazy var stepsProgressBar: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = UIColor(hex: "#FF6B35")
        pv.trackTintColor    = UIColor(hex: "#2A2A2A")
        pv.layer.cornerRadius = 3
        pv.clipsToBounds      = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    // --- Gov ID Card ---
    private lazy var govIDCard: UIView       = makeCard()
    private lazy var govIDUploadArea: UIView = UIView()
    private lazy var govIDUploadIcon: UIImageView  = makeUploadIcon("photo.badge.plus")
    private lazy var govIDUploadLabel: UILabel     = makeUploadLabel("Upload JPG, PNG file")
    private lazy var frontPreviewImage: UIImageView = makePreview()
    private lazy var backPreviewImage: UIImageView  = makePreview()
    private lazy var govIDPreviewStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [frontPreviewImage, backPreviewImage])
        sv.axis         = .horizontal
        sv.spacing      = 8
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isHidden = true
        return sv
    }()

    // --- Selfie Card ---
    private lazy var selfieCard: UIView       = makeCard()
    private lazy var selfieUploadArea: UIView = UIView()
    private lazy var selfieUploadIcon: UIImageView = makeUploadIcon("person.crop.artframe")
    private lazy var selfieUploadLabel: UILabel    = makeUploadLabel("Quick selfie to confirm it's really you")
    private lazy var selfiePreviewImage: UIImageView = {
        let iv = makePreview()
        iv.isHidden = true
        return iv
    }()

    // --- Bottom ---
    private lazy var continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Continue Verification", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.setFont(.bold, size: 17)
        b.backgroundColor        = UIColor(hex: "#FF6B35")
        b.layer.cornerRadius     = 28
        b.clipsToBounds          = true
        b.alpha                  = 0.5
        b.isUserInteractionEnabled = false
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(btnContinueTapped), for: .touchUpInside)
        return b
    }()

    private lazy var privacyLabel: UILabel = {
        let l = makeLabel("Your information is encrypted and never shared publicly",
                          font: .regular, size: 12,
                          color: UIColor(hex: "#9B9B9B"), align: .center)
        l.numberOfLines = 2
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#111111")
        buildLayout()
        loadUserProfile()
        updateProgressUI()
        
       
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.hideTabBar()
    }
    
    private func loadUploadedImagesIfAvailable() {

        if let front = User.curentUser?.front, !front.isEmpty {
            frontImageName = front
            request.front = front
            loadImage(frontPreviewImage, url: URL(string: front)!)
        }

        if let back = User.curentUser?.back, !back.isEmpty {
            backImageName = back
            request.back = back
            loadImage(backPreviewImage, url: URL(string: back)!)
        }

        if let selfie = User.curentUser?.selfie, !selfie.isEmpty {
            selfieImageName = selfie
            request.selfie = selfie
            loadImage(selfiePreviewImage, url: URL(string: selfie)!)
        }

        // Update UI
        govIDPreviewStack.isHidden = frontImageName.isEmpty && backImageName.isEmpty
        frontPreviewImage.isHidden = frontImageName.isEmpty
        backPreviewImage.isHidden = backImageName.isEmpty

        selfiePreviewImage.isHidden = selfieImageName.isEmpty

        govIDUploadIcon.isHidden = !frontImageName.isEmpty || !backImageName.isEmpty
        selfieUploadIcon.isHidden = !selfieImageName.isEmpty

        if !frontImageName.isEmpty || !backImageName.isEmpty {
            govIDUploadLabel.text = "ID Uploaded ✓ Tap to replace"
        }

        if !selfieImageName.isEmpty {
            selfieUploadLabel.text = "Selfie Uploaded ✓ Tap to replace"
        }

        // This will automatically enable the button if all 3 images exist
        updateProgressUI()
        updateContinueButton()
        lockVerificationUploads()
    }
    
    private func lockVerificationUploads() {
        let hasGovID = !frontImageName.isEmpty && !backImageName.isEmpty
        let hasSelfie = !selfieImageName.isEmpty

        if hasGovID {
            govIDUploadArea.isUserInteractionEnabled = false
            govIDUploadLabel.text = "Government ID Uploaded ✓"
            govIDUploadIcon.isHidden = true
        }

        if hasSelfie {
            selfieUploadArea.isUserInteractionEnabled = false
            selfieUploadLabel.text = "Selfie Uploaded ✓"
            selfieUploadIcon.isHidden = true
        }

        updateContinueButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Round profile image
        imgProfile.layer.cornerRadius     = imgProfile.frame.height / 2
        progressRingView.layer.cornerRadius = 0 // custom draw handles it

        // Dashed borders — add once after layout
        guard !dashLayersAdded else { return }
        dashLayersAdded = true
        addDashedBorder(to: govIDUploadArea)
        addDashedBorder(to: selfieUploadArea)
        progressRingView.setNeedsDisplay()
    }

    // MARK: - Layout

    private func buildLayout() {
        buildNavBar()
        buildScrollContent()
    }

    // MARK: Nav Bar

    private func buildNavBar() {
        let nav = UIView()
        nav.backgroundColor = UIColor(hex: "#111111")
        nav.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nav)

        let btnBack = UIButton(type: .system)
        btnBack.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btnBack.tintColor = .white
        btnBack.translatesAutoresizingMaskIntoConstraints = false
        btnBack.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        let titleLbl = makeLabel("Get Verified", font: .bold, size: 20, color: .white)

        nav.addSubview(btnBack)
        nav.addSubview(titleLbl)

        NSLayoutConstraint.activate([
            nav.topAnchor.constraint(equalTo: view.topAnchor),
            nav.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nav.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nav.heightAnchor.constraint(equalToConstant: 96),

            btnBack.leadingAnchor.constraint(equalTo: nav.leadingAnchor, constant: 16),
            btnBack.bottomAnchor.constraint(equalTo: nav.bottomAnchor, constant: -12),
            btnBack.widthAnchor.constraint(equalToConstant: 32),
            btnBack.heightAnchor.constraint(equalToConstant: 32),

            titleLbl.leadingAnchor.constraint(equalTo: btnBack.trailingAnchor, constant: 8),
            titleLbl.centerYAnchor.constraint(equalTo: btnBack.centerYAnchor),
        ])

        // ScrollView below nav
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: nav.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    // MARK: Scroll Content

    private func buildScrollContent() {
        let profileSection  = buildProfileCard()
        let whySection      = buildWhySection()
        let stepsSection    = buildStepsSection()
        let govSection      = buildGovIDCard()
        let selfieSection   = buildSelfieCard()

        [profileSection, whySection, stepsSection,
         stepsProgressBar, govSection, selfieSection,
         continueButton, privacyLabel].forEach {
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // Profile card
            profileSection.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            profileSection.heightAnchor.constraint(equalToConstant: 190),

            // Why section
            whySection.topAnchor.constraint(equalTo: profileSection.bottomAnchor, constant: 24),
            whySection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            whySection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Steps section
            stepsSection.topAnchor.constraint(equalTo: whySection.bottomAnchor, constant: 24),
            stepsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stepsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stepsSection.heightAnchor.constraint(equalToConstant: 30),

            // Progress bar
            stepsProgressBar.topAnchor.constraint(equalTo: stepsSection.bottomAnchor, constant: 10),
            stepsProgressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stepsProgressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stepsProgressBar.heightAnchor.constraint(equalToConstant: 6),

            // Gov ID card
            govSection.topAnchor.constraint(equalTo: stepsProgressBar.bottomAnchor, constant: 16),
            govSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            govSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Selfie card
            selfieSection.topAnchor.constraint(equalTo: govSection.bottomAnchor, constant: 16),
            selfieSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            selfieSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Continue button
            continueButton.topAnchor.constraint(equalTo: selfieSection.bottomAnchor, constant: 28),
            continueButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 56),

            // Privacy label
            privacyLabel.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 12),
            privacyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            privacyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            privacyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
    }

    // MARK: - Section Builders

    private func buildProfileCard() -> UIView {
        profileCard.translatesAutoresizingMaskIntoConstraints = false

        // Progress ring (behind image)
        progressRingView.backgroundColor    = .clear
        progressRingView.progress           = 0.4
        progressRingView.translatesAutoresizingMaskIntoConstraints = false

        // Percent badge
        lblProgressPercent.translatesAutoresizingMaskIntoConstraints = false
        lblProgressPercent.text = "40%"

        [progressRingView, imgProfile, lblProgressPercent, lblName, lblUsername]
            .forEach { profileCard.addSubview($0) }

        NSLayoutConstraint.activate([
            // Ring — centred horizontally, top padding
            progressRingView.centerXAnchor.constraint(equalTo: profileCard.centerXAnchor),
            progressRingView.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 20),
            progressRingView.widthAnchor.constraint(equalToConstant: 96),
            progressRingView.heightAnchor.constraint(equalToConstant: 96),

            // Profile image — centred inside ring
            imgProfile.centerXAnchor.constraint(equalTo: progressRingView.centerXAnchor),
            imgProfile.centerYAnchor.constraint(equalTo: progressRingView.centerYAnchor),
            imgProfile.widthAnchor.constraint(equalToConstant: 80),
            imgProfile.heightAnchor.constraint(equalToConstant: 80),

            // Badge — bottom-right of ring
            lblProgressPercent.centerXAnchor.constraint(equalTo: progressRingView.trailingAnchor, constant: -4),
            lblProgressPercent.centerYAnchor.constraint(equalTo: progressRingView.bottomAnchor, constant: -4),
            lblProgressPercent.widthAnchor.constraint(equalToConstant: 36),
            lblProgressPercent.heightAnchor.constraint(equalToConstant: 20),

            // Name
            lblName.topAnchor.constraint(equalTo: progressRingView.bottomAnchor, constant: 10),
            lblName.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            lblName.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),

            // Username
            lblUsername.topAnchor.constraint(equalTo: lblName.bottomAnchor, constant: 4),
            lblUsername.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            lblUsername.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),
            lblUsername.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -16),
        ])

        return profileCard
    }

    private func buildWhySection() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let header     = makeSectionHeader("Why Get Verified?")
        let cardView   = makeCard()
        cardView.translatesAutoresizingMaskIntoConstraints = false

        let b1 = makeBenefitRow(icon: "checkmark.shield.fill",  title: "Build Trust",          sub: "Verified profiles get 3x more matches with quality travel groups")
        let b2 = makeBenefitRow(icon: "location.circle.fill",   title: "Priority Visibility",  sub: "Your profile appears first in discovery and gets a verified badge")
        let b3 = makeBenefitRow(icon: "shield.lefthalf.filled", title: "Safe Community",       sub: "Travel with confidence knowing everyone is verified")

        let stack = UIStackView(arrangedSubviews: [b1, b2, b3])
        stack.axis      = .vertical
        stack.spacing   = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
        ])

        container.addSubview(header)
        container.addSubview(cardView)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: container.topAnchor),
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 30),

            cardView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            cardView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    private func buildStepsSection() -> UIView {
        let header = makeSectionHeader("Verification Steps")
        header.translatesAutoresizingMaskIntoConstraints = false

        stepsProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stepsProgressLabel)
        NSLayoutConstraint.activate([
            stepsProgressLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            stepsProgressLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            stepsProgressLabel.widthAnchor.constraint(equalToConstant: 100),
        ])

        return header
    }

    private func buildGovIDCard() -> UIView {
        govIDCard.translatesAutoresizingMaskIntoConstraints = false

        let iconBg  = makeIconBg("creditcard.fill")
        let title   = makeLabel("Government ID",                     font: .semibold, size: 15, color: .white)
        let subtitle = makeLabel("Verify your identity (private & secure)", font: .regular, size: 12, color: UIColor(hex: "#9B9B9B"))

        govIDUploadArea.translatesAutoresizingMaskIntoConstraints = false
        govIDUploadArea.backgroundColor  = UIColor(hex: "#1A1A1A")
        govIDUploadArea.layer.cornerRadius = 12
        govIDUploadArea.isUserInteractionEnabled = true
        govIDUploadArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedGovIDUpload)))

        govIDUploadIcon.translatesAutoresizingMaskIntoConstraints = false
        govIDUploadLabel.translatesAutoresizingMaskIntoConstraints = false
        govIDUploadLabel.numberOfLines = 2

        govIDUploadArea.addSubview(govIDUploadIcon)
        govIDUploadArea.addSubview(govIDUploadLabel)

        govIDPreviewStack.translatesAutoresizingMaskIntoConstraints = false

        [iconBg, title, subtitle, govIDUploadArea, govIDPreviewStack]
            .forEach { govIDCard.addSubview($0) }

        NSLayoutConstraint.activate([
            iconBg.topAnchor.constraint(equalTo: govIDCard.topAnchor, constant: 16),
            iconBg.leadingAnchor.constraint(equalTo: govIDCard.leadingAnchor, constant: 16),
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),

            title.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: govIDCard.trailingAnchor, constant: -16),
            title.topAnchor.constraint(equalTo: iconBg.topAnchor),

            subtitle.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            subtitle.trailingAnchor.constraint(equalTo: govIDCard.trailingAnchor, constant: -16),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),

            govIDUploadArea.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 12),
            govIDUploadArea.leadingAnchor.constraint(equalTo: govIDCard.leadingAnchor, constant: 16),
            govIDUploadArea.trailingAnchor.constraint(equalTo: govIDCard.trailingAnchor, constant: -16),
            govIDUploadArea.heightAnchor.constraint(equalToConstant: 100),

            govIDUploadIcon.centerXAnchor.constraint(equalTo: govIDUploadArea.centerXAnchor),
            govIDUploadIcon.topAnchor.constraint(equalTo: govIDUploadArea.topAnchor, constant: 18),
            govIDUploadIcon.widthAnchor.constraint(equalToConstant: 36),
            govIDUploadIcon.heightAnchor.constraint(equalToConstant: 32),

            govIDUploadLabel.topAnchor.constraint(equalTo: govIDUploadIcon.bottomAnchor, constant: 8),
            govIDUploadLabel.leadingAnchor.constraint(equalTo: govIDUploadArea.leadingAnchor, constant: 12),
            govIDUploadLabel.trailingAnchor.constraint(equalTo: govIDUploadArea.trailingAnchor, constant: -12),

            govIDPreviewStack.topAnchor.constraint(equalTo: govIDUploadArea.bottomAnchor, constant: 10),
            govIDPreviewStack.leadingAnchor.constraint(equalTo: govIDCard.leadingAnchor, constant: 16),
            govIDPreviewStack.trailingAnchor.constraint(equalTo: govIDCard.trailingAnchor, constant: -16),
            govIDPreviewStack.heightAnchor.constraint(equalToConstant: 60),
            govIDPreviewStack.bottomAnchor.constraint(equalTo: govIDCard.bottomAnchor, constant: -16),
        ])

        return govIDCard
    }

    private func buildSelfieCard() -> UIView {
        selfieCard.translatesAutoresizingMaskIntoConstraints = false

        let iconBg   = makeIconBg("person.crop.circle.badge.checkmark")
        let title    = makeLabel("Upload Selfie",                          font: .semibold, size: 15, color: .white)
        let subtitle = makeLabel("Quick selfie to confirm it's really you", font: .regular,  size: 12, color: UIColor(hex: "#9B9B9B"))

        selfieUploadArea.translatesAutoresizingMaskIntoConstraints = false
        selfieUploadArea.backgroundColor   = UIColor(hex: "#1A1A1A")
        selfieUploadArea.layer.cornerRadius = 12
        selfieUploadArea.isUserInteractionEnabled = true
        selfieUploadArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedSelfieUpload)))

        selfieUploadIcon.translatesAutoresizingMaskIntoConstraints = false
        selfieUploadLabel.translatesAutoresizingMaskIntoConstraints = false
        selfieUploadLabel.numberOfLines = 2
        selfiePreviewImage.translatesAutoresizingMaskIntoConstraints = false
        selfiePreviewImage.layer.cornerRadius = 8

        selfieUploadArea.addSubview(selfieUploadIcon)
        selfieUploadArea.addSubview(selfieUploadLabel)
        selfieUploadArea.addSubview(selfiePreviewImage)

        [iconBg, title, subtitle, selfieUploadArea]
            .forEach { selfieCard.addSubview($0) }

        NSLayoutConstraint.activate([
            iconBg.topAnchor.constraint(equalTo: selfieCard.topAnchor, constant: 16),
            iconBg.leadingAnchor.constraint(equalTo: selfieCard.leadingAnchor, constant: 16),
            iconBg.widthAnchor.constraint(equalToConstant: 44),
            iconBg.heightAnchor.constraint(equalToConstant: 44),

            title.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: selfieCard.trailingAnchor, constant: -16),
            title.topAnchor.constraint(equalTo: iconBg.topAnchor),

            subtitle.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            subtitle.trailingAnchor.constraint(equalTo: selfieCard.trailingAnchor, constant: -16),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),

            selfieUploadArea.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 12),
            selfieUploadArea.leadingAnchor.constraint(equalTo: selfieCard.leadingAnchor, constant: 16),
            selfieUploadArea.trailingAnchor.constraint(equalTo: selfieCard.trailingAnchor, constant: -16),
            selfieUploadArea.heightAnchor.constraint(equalToConstant: 110),
            selfieUploadArea.bottomAnchor.constraint(equalTo: selfieCard.bottomAnchor, constant: -16),

            selfieUploadIcon.centerXAnchor.constraint(equalTo: selfieUploadArea.centerXAnchor),
            selfieUploadIcon.topAnchor.constraint(equalTo: selfieUploadArea.topAnchor, constant: 18),
            selfieUploadIcon.widthAnchor.constraint(equalToConstant: 36),
            selfieUploadIcon.heightAnchor.constraint(equalToConstant: 32),

            selfieUploadLabel.topAnchor.constraint(equalTo: selfieUploadIcon.bottomAnchor, constant: 8),
            selfieUploadLabel.leadingAnchor.constraint(equalTo: selfieUploadArea.leadingAnchor, constant: 12),
            selfieUploadLabel.trailingAnchor.constraint(equalTo: selfieUploadArea.trailingAnchor, constant: -12),

            selfiePreviewImage.centerXAnchor.constraint(equalTo: selfieUploadArea.centerXAnchor),
            selfiePreviewImage.centerYAnchor.constraint(equalTo: selfieUploadArea.centerYAnchor),
            selfiePreviewImage.widthAnchor.constraint(equalToConstant: 140),
            selfiePreviewImage.heightAnchor.constraint(equalToConstant: 90),
        ])

        return selfieCard
    }

    // MARK: - Upload Logic

    @objc private func tappedGovIDUpload() {
        let hasExisting = !frontImageName.isEmpty
        let title = hasExisting ? "Replace Government ID" : "Upload Government ID"
        let sheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: "Take Photo",    style: .default) { _ in self.pickGovID(camera: false) })
        sheet.addAction(UIAlertAction(title: "Choose Photo",  style: .default) { _ in self.pickGovID(camera: false) })
        sheet.addAction(UIAlertAction(title: "Cancel",        style: .cancel))

        sheet.popoverPresentationController?.sourceView = govIDUploadArea
        present(sheet, animated: true)
    }

    private func pickGovID(camera: Bool) {
        imagePicker.showImagePicker(allowCamera: camera,allowonlyCamera:false) { [weak self] img in
            guard let self else { return }
            self.frontImage = img
            guard let data = img.jpegData(compressionQuality: 0.7) else { return }

            self.uploadImg(data) { [weak self] name in
                guard let self else { return }
                self.frontImageName = name ?? ""
                request.front = name

                DispatchQueue.main.async {
                    self.frontPreviewImage.image = img
                    self.govIDPreviewStack.isHidden = false
                    self.updateProgressUI()
                    self.askForBackSide()
                }
            }
        }
    }

    private func askForBackSide() {
        let alert = UIAlertController(
            title: "Upload Back Side",
            message: "Now upload the back of your Government ID",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Take Photo",   style: .default) { _ in self.pickBackID(camera: true) })
        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default) { _ in self.pickBackID(camera: false) })
        alert.addAction(UIAlertAction(title: "Skip",         style: .cancel))
        present(alert, animated: true)
    }

    private func pickBackID(camera: Bool) {
        imagePicker.showImagePicker(allowCamera: camera,allowonlyCamera:false) { [weak self] img in
            guard let self else { return }
            self.backImage = img
            guard let data = img.jpegData(compressionQuality: 0.7) else { return }

            self.uploadImg(data) { [weak self] name in
                guard let self else { return }
                self.backImageName = name ?? ""
                request.back = name

                DispatchQueue.main.async {
                    self.backPreviewImage.image = img
                    self.govIDUploadLabel.text = "ID Uploaded ✓  Tap to replace"
                    self.updateProgressUI()
                    self.updateContinueButton()
                }
            }
        }
    }

    @objc private func tappedSelfieUpload() {
//        let sourceType: UIImagePickerController.SourceType =
//            UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary

        imagePicker.showImagePicker(allowCamera:true,allowonlyCamera:true) { [weak self] img in
            guard let self else { return }
            self.selfieImage = img
            guard let data = img.jpegData(compressionQuality: 0.7) else { return }

            self.uploadImg(data) { [weak self] name in
                guard let self else { return }
                self.selfieImageName = name ?? ""
                request.selfie = name

                DispatchQueue.main.async {
                    self.selfiePreviewImage.image  = img
                    self.selfiePreviewImage.isHidden = false
                    self.selfieUploadLabel.text    = "Selfie Uploaded ✓  Tap to replace"
                    self.selfieUploadIcon.isHidden = true
                    self.updateProgressUI()
                    self.updateContinueButton()
                }
            }
        }
    }

    // MARK: - Progress & Validation

    private func updateProgressUI() {
        let hasFront  = !frontImageName.isEmpty
        let hasBack   = !backImageName.isEmpty
        let hasSelfie = !selfieImageName.isEmpty

        var done = 0
        if hasFront && hasBack { done += 1 }
        if hasSelfie           { done += 1 }

        let fraction = Float(done) / 2.0
        stepsProgressLabel.text = "\(done)/2 Complete"
        stepsProgressBar.setProgress(fraction, animated: true)
        lblProgressPercent.text = "\(Int(fraction * 100))%"
        progressRingView.progress = CGFloat(fraction)
    }

    private func updateContinueButton() {
        let allDone = !frontImageName.isEmpty && !backImageName.isEmpty && !selfieImageName.isEmpty
        UIView.animate(withDuration: 0.25) {
            self.continueButton.alpha = allDone ? 1.0 : 0.5
        }
        continueButton.isUserInteractionEnabled = allDone
    }

    // MARK: - User Profile

    private func loadUserProfile() {
        if let url = URL(string: User.curentUser?.profile_image ?? "") {
            loadImage(imgProfile, url: url)
        }
        lblName.text     = User.curentUser?.name ?? "Alex Mercer"
        lblUsername.text = "@\(User.curentUser?.userName ?? "johndoe_travels")"
        loadUploadedImagesIfAvailable()
    }

    // MARK: - API

    @objc private func btnContinueTapped() {
        request.front  = frontImageName
        request.back   = backImageName
        request.selfie = selfieImageName

        showLoader()
        request.editProfileAPi { [weak self] msg, code in
            guard let self else { return }
            DispatchQueue.main.async {
                self.hideLoader()
                if code == 200 {
                    self.showSuccessAlert()
                } else {
                    self.showAlert(msg ?? "Something went wrong. Please try again.")
                }
            }
        }
         
    }

    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Verification Submitted ✓",
            message: "We'll review your documents shortly.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.backTapped()
        })
        present(alert, animated: true)
    }

    // MARK: - Factory Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor     = UIColor(hex: "#1A1A1A")
        v.layer.cornerRadius  = 16
        v.clipsToBounds       = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func makeLabel(_ text: String,
                            font: UIFont.Weight,
                            size: CGFloat,
                            color: UIColor,
                            align: NSTextAlignment = .left) -> UILabel {
        let l = UILabel()
        l.text          = text
        l.textColor     = color
        l.textAlignment = align
        l.setFont(font == .bold ? .bold : font == .semibold ? .semiBold : .regular, size: size)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func makeUploadIcon(_ systemName: String) -> UIImageView {
        let iv = UIImageView()
        iv.image    = UIImage(systemName: systemName)
        iv.tintColor = UIColor(hex: "#FF6B35")
        iv.contentMode = .scaleAspectFit
        return iv
    }

    private func makeUploadLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text          = text
        l.textColor     = UIColor(hex: "#FF6B35")
        l.textAlignment = .center
        l.numberOfLines = 2
        l.setFont(.regular, size: 13)
        return l
    }

    private func makePreview() -> UIImageView {
        let iv = UIImageView()
        iv.contentMode       = .scaleAspectFill
        iv.clipsToBounds     = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor   = UIColor(hex: "#2A2A2A")
        return iv
    }

    private func makeIconBg(_ systemName: String) -> UIView {
        let bg = UIView()
        bg.backgroundColor    = UIColor(hex: "#2A1A0A")
        bg.layer.cornerRadius = 10
        bg.translatesAutoresizingMaskIntoConstraints = false

        let iv = UIImageView()
        iv.image        = UIImage(systemName: systemName)
        iv.tintColor    = UIColor(hex: "#FF6B35")
        iv.contentMode  = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(iv)

        NSLayoutConstraint.activate([
            iv.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 22),
            iv.heightAnchor.constraint(equalToConstant: 22),
        ])
        return bg
    }

    private func makeSectionHeader(_ title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false

        let bar = UIView()
        bar.backgroundColor   = UIColor(hex: "#FF6B35")
        bar.layer.cornerRadius = 2
        bar.translatesAutoresizingMaskIntoConstraints = false

        let lbl = makeLabel(title, font: .bold, size: 18, color: .white)

        container.addSubview(bar)
        container.addSubview(lbl)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bar.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            bar.widthAnchor.constraint(equalToConstant: 4),
            bar.heightAnchor.constraint(equalToConstant: 24),

            lbl.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 10),
            lbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            lbl.heightAnchor.constraint(equalToConstant: 28),

            container.heightAnchor.constraint(equalToConstant: 30),
        ])
        return container
    }

    private func makeBenefitRow(icon: String, title: String, sub: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let iconBg = makeIconBg(icon)

        let titleLbl = makeLabel(title, font: .semibold, size: 14, color: .white)
        let subLbl   = makeLabel(sub,   font: .regular,  size: 12, color: UIColor(hex: "#9B9B9B"))
        subLbl.numberOfLines = 2

        row.addSubview(iconBg)
        row.addSubview(titleLbl)
        row.addSubview(subLbl)

        NSLayoutConstraint.activate([
            iconBg.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            iconBg.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 40),
            iconBg.heightAnchor.constraint(equalToConstant: 40),

            titleLbl.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            titleLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            titleLbl.topAnchor.constraint(equalTo: row.topAnchor),

            subLbl.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            subLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            subLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 2),
            subLbl.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        return row
    }

    private func addDashedBorder(to view: UIView) {
        let dash = CAShapeLayer()
        dash.strokeColor    = UIColor(hex: "#FF6B35").cgColor
        dash.lineDashPattern = [6, 4]
        dash.lineWidth      = 1.5
        dash.fillColor      = UIColor.clear.cgColor
        dash.frame          = view.bounds
        dash.path           = UIBezierPath(roundedRect: view.bounds, cornerRadius: 12).cgPath
        view.layer.addSublayer(dash)
    }
}


class CircularProgressView: UIView {

    var progress: CGFloat = 0.0 {
        didSet { setNeedsDisplay() }
    }

    var progressColor: UIColor = UIColor(hex: "#FF6B35")
    var trackColor: UIColor    = UIColor(hex: "#2A2A2A")
    var lineWidth: CGFloat     = 4.5

    override func draw(_ rect: CGRect) {
        let center    = CGPoint(x: rect.midX, y: rect.midY)
        let radius    = (min(rect.width, rect.height) / 2) - lineWidth / 2
        let startAngle: CGFloat = -.pi / 2
        let fullEnd:  CGFloat   = startAngle + 2 * .pi

        // track
        let track = UIBezierPath(arcCenter: center, radius: radius,
                                 startAngle: startAngle, endAngle: fullEnd,
                                 clockwise: true)
        track.lineWidth = lineWidth
        trackColor.setStroke()
        track.stroke()

        // progress
        let end = startAngle + 2 * .pi * progress
        let prog = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: startAngle, endAngle: end,
                                clockwise: true)
        prog.lineWidth      = lineWidth
        prog.lineCapStyle   = .round
        progressColor.setStroke()
        prog.stroke()
    }
}
