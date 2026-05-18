//
//  TripsTabBarController.swift
//  TravelDate
//

import UIKit

// MARK: - Tab Item Model
struct TripsTabItem {
    let icon: String
    let selectedIcon: String
    let tag: Int
}

// MARK: - Custom Tab Bar Controller
class TripsTabBarController: UIViewController {

    // MARK: - Properties
    private var tabBarHeightConstraint: NSLayoutConstraint!
    private var blurAdded = false

    // MARK: - Tab Items Config
    private let tabItems: [TripsTabItem] = [
        TripsTabItem(icon: "imgHome",    selectedIcon: "imgHome",    tag: 0),
        TripsTabItem(icon: "imgGroup",   selectedIcon: "imgGroup",   tag: 1),
        TripsTabItem(icon: "imgMatch",   selectedIcon: "imgMatch",   tag: 2),
        TripsTabItem(icon: "imgChat2",   selectedIcon: "imgChat2",   tag: 3),
        TripsTabItem(icon: "imgprofile", selectedIcon: "imgprofile", tag: 4),
    ]

    // MARK: - ViewControllers
    private lazy var viewControllers: [UIViewController] = [
        UINavigationController(rootViewController: Self.instantiateHomeVC()),
        UINavigationController(rootViewController: Self.instantiateGroupVC()),
        UINavigationController(rootViewController: Self.instantiateSwipeVC()),
        UINavigationController(rootViewController: Self.instantiateChatVC()),
        UINavigationController(rootViewController: Self.instantiateProfileVC()),
    ]

    // MARK: - UI
    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let tabBarContainer: UIView = {
        let v = UIView()
        // MUST be clear — blur view is the actual background
        v.backgroundColor      = .clear
        v.layer.cornerRadius   = 40
        v.layer.masksToBounds  = false
        v.layer.shadowColor    = UIColor.black.cgColor
        v.layer.shadowOpacity  = 0.5
        v.layer.shadowOffset   = CGSize(width: 0, height: 8)
        v.layer.shadowRadius   = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var tabButtons: [UIButton] = []
    var selectedIndex: Int = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupContainer()
        setupTabBar()
        switchTo(index: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update blur frame on every layout pass
        if let blur = tabBarContainer.subviews
            .first(where: { $0 is UIVisualEffectView }) as? UIVisualEffectView {
            blur.frame = tabBarContainer.bounds
            // Update border layer frame too
            if let border = tabBarContainer.layer.sublayers?
                .first(where: { $0 is CAShapeLayer }) as? CAShapeLayer {
                border.path = UIBezierPath(
                    roundedRect: tabBarContainer.bounds,
                    cornerRadius: tabBarContainer.layer.cornerRadius
                ).cgPath
            }
            return
        }

        guard !blurAdded else { return }
        blurAdded = true

        // 1. Blur view — frosted glass effect
        let blur = UIVisualEffectView(
            effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.frame            = tabBarContainer.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.layer.cornerRadius = tabBarContainer.layer.cornerRadius
        blur.clipsToBounds    = true

        // Frosted tint on top of blur
        let tintView = UIView(frame: blur.bounds)
        tintView.backgroundColor  = UIColor.white.withAlphaComponent(0.06)
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.contentView.addSubview(tintView)

        // Insert blur BEHIND all other subviews
        tabBarContainer.insertSubview(blur, at: 0)

        // 2. Border on separate CAShapeLayer
        // (masksToBounds must stay false for shadow — so border goes on sublayer)
        let border = CAShapeLayer()
        border.path = UIBezierPath(
            roundedRect: tabBarContainer.bounds,
            cornerRadius: tabBarContainer.layer.cornerRadius
        ).cgPath
        border.fillColor   = UIColor.clear.cgColor
        border.strokeColor = UIColor.white.withAlphaComponent(0.15).cgColor
        border.lineWidth   = 1
        tabBarContainer.layer.addSublayer(border)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            if let tabBarVC = parent?.parent as? TripsTabBarController {
                tabBarVC.showTabBar()
            }
        }
    }

    // MARK: - Show / Hide Tab Bar
    func hideTabBar() {
        tabBarHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.tabBarContainer.alpha = 0
            self.view.layoutIfNeeded()
        }
    }

    func showTabBar() {
        tabBarHeightConstraint.constant = 80
        UIView.animate(withDuration: 0.3) {
            self.tabBarContainer.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - VC Factory
    private static func instantiateHomeVC() -> HomeViewController {
        let sb = UIStoryboard(name: "Home", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "HomeViewController") as? HomeViewController
        else { fatalError("HomeViewController not found") }
        return vc
    }

    private static func instantiateGroupVC() -> NewMatchVc {
        let sb = UIStoryboard(name: "Home", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "NewMatchVc") as? NewMatchVc
        else { fatalError("NewMatchVc not found") }
        return vc
    }

    private static func instantiateSwipeVC() -> SwipeViewController {
        let sb = UIStoryboard(name: "Home", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "SwipeViewController") as? SwipeViewController
        else { fatalError("SwipeViewController not found") }
        return vc
    }

    private static func instantiateChatVC() -> ChatVc {
        let sb = UIStoryboard(name: "Home", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "ChatVc") as? ChatVc
        else { fatalError("ChatVc not found") }
        return vc
    }

    private static func instantiateProfileVC() -> ProfileViewController {
        let sb = UIStoryboard(name: "Settings", bundle: nil)
        guard let vc = sb.instantiateViewController(
            withIdentifier: "ProfileViewController") as? ProfileViewController
        else { fatalError("ProfileViewController not found") }
        return vc
    }

    // MARK: - Setup Container
    private func setupContainer() {
        view.addSubview(containerView)
        view.addSubview(tabBarContainer)

        tabBarHeightConstraint = tabBarContainer.heightAnchor
            .constraint(equalToConstant: 80)

        NSLayoutConstraint.activate([
            // containerView fills the ENTIRE screen
            // so content renders BEHIND the tab bar — required for blur
            containerView.topAnchor.constraint(
                equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor),

            // Tab bar floats above content
            tabBarContainer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            tabBarContainer.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),
            tabBarContainer.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            tabBarHeightConstraint,
        ])
    }

    // MARK: - Setup Tab Bar
    private func setupTabBar() {
        let stack = UIStackView()
        stack.axis         = .horizontal
        stack.distribution = .fillEqually
        stack.alignment    = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        tabBarContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(
                equalTo: tabBarContainer.topAnchor),
            stack.bottomAnchor.constraint(
                equalTo: tabBarContainer.bottomAnchor),
            stack.leadingAnchor.constraint(
                equalTo: tabBarContainer.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(
                equalTo: tabBarContainer.trailingAnchor, constant: -8),
        ])

        for item in tabItems {
            let btn = makeTabButton(item: item)
            stack.addArrangedSubview(btn)
            tabButtons.append(btn)
        }
    }

    private func makeTabButton(item: TripsTabItem) -> UIButton {
        let btn = UIButton(type: .system)
        btn.tag       = item.tag
        btn.tintColor = UIColor.white.withAlphaComponent(0.4)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .regular),
            forImageIn: .normal)
        btn.setImage(
            UIImage(named: item.icon)?.withRenderingMode(.alwaysTemplate),
            for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - Tab Switch
    @objc private func tabTapped(_ sender: UIButton) {
        switchTo(index: sender.tag)
    }

    private func switchTo(index: Int) {
        // Remove current child
        if let current = children.first {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        // Update button states
        for (i, btn) in tabButtons.enumerated() {
            let isSelected = i == index

            // Icon
            let iconName = isSelected ? tabItems[i].selectedIcon : tabItems[i].icon
            btn.setImage(
                UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate),
                for: .normal)
            btn.tintColor = isSelected ? .white : UIColor.white.withAlphaComponent(0.4)

            // Remove old highlight circle
            btn.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }

            // Add orange circle for selected tab
            if isSelected {
                let size: CGFloat = 52
                let circle = UIView()
                circle.tag                = 999
                circle.backgroundColor    = UIColor.themeOrange
                circle.layer.cornerRadius = size / 2
                circle.isUserInteractionEnabled = false
                circle.translatesAutoresizingMaskIntoConstraints = false
                btn.insertSubview(circle, at: 0)
                NSLayoutConstraint.activate([
                    circle.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
                    circle.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
                    circle.widthAnchor.constraint(equalToConstant: size),
                    circle.heightAnchor.constraint(equalToConstant: size),
                ])
            }
        }

        // Add new child VC
        selectedIndex = index
        let vc = viewControllers[index]
        addChild(vc)
        vc.view.frame            = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParent: self)
    }
}

// MARK: - UIViewController extension
extension UIViewController {
    var tripsTabBarController: TripsTabBarController? {
        var parentVC = parent
        while parentVC != nil {
            if let tab = parentVC as? TripsTabBarController { return tab }
            parentVC = parentVC?.parent
        }
        return nil
    }
}

// MARK: - Placeholder VC
class PlaceholderVC: UIViewController {
    private let tabTitle: String
    init(title: String) {
        self.tabTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let l = UILabel()
        l.text      = tabTitle
        l.textColor = .white
        l.setFont(.semiBold, size: 20.0)
        l.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(l)
        NSLayoutConstraint.activate([
            l.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            l.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
