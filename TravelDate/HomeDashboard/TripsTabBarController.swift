//
//  TripsTabBarController.swift
//  TravelDate
//
//  Created by Dev CodingZone
//

import UIKit
import SwiftUI

// MARK: - Tab Item Model

struct TripsTabItem {
    let icon: String
    let selectedIcon: String
    let tag: Int
}

// MARK: - Custom Tab Bar Controller

class TripsTabBarController: UIViewController {

    private var tabBarHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Tab Items Config
    private let tabItems: [TripsTabItem] = [
        TripsTabItem(icon: "imgHome",           selectedIcon: "imgHome",         tag: 0),
        TripsTabItem(icon: "imgGroup",        selectedIcon: "imgGroup",       tag: 1),
        TripsTabItem(icon: "imgMatch",           selectedIcon: "imgMatch",          tag: 2),
        TripsTabItem(icon: "imgChat2",     selectedIcon: "imgChat2",    tag: 3),
        TripsTabItem(icon: "imgprofile",          selectedIcon: "imgprofile",         tag: 4)
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
        v.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        v.layer.cornerRadius = 30
        v.layer.masksToBounds = false

        // Shadow (floating effect)
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.3
        v.layer.shadowOffset = CGSize(width: 0, height: 10)
        v.layer.shadowRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var tabButtons: [UIButton] = []
    private var selectedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupContainer()
        setupTabBar()
        switchTo(index: 0)
    }

    private var blurAdded = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !blurAdded else {
            // Just update frame if already added
            if let blur = tabBarContainer.subviews.first as? UIVisualEffectView {
                blur.frame = tabBarContainer.bounds
            }
            return
        }
        blurAdded = true

        // 1. Blur (glassmorphism)
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.frame = tabBarContainer.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.layer.cornerRadius = tabBarContainer.layer.cornerRadius
        blur.clipsToBounds = true
        tabBarContainer.insertSubview(blur, at: 0)

        // 2. Border (must be done on a separate layer — masksToBounds kills shadow)
        let borderLayer = CAShapeLayer()
        let borderPath = UIBezierPath(
            roundedRect: tabBarContainer.bounds,
            cornerRadius: tabBarContainer.layer.cornerRadius
        )
        borderLayer.path = borderPath.cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.15).cgColor
        borderLayer.lineWidth = 1
        tabBarContainer.layer.addSublayer(borderLayer)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.isMovingFromParent {
            if let tabBarVC = self.parent?.parent as? TripsTabBarController {
                tabBarVC.showTabBar()
            }
        }
    }
    
    
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
    

//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        // Round top corners of tab bar
//        tabBarContainer.roundCorners([.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: 24)
//    }
    
   
    
    private static func instantiateHomeVC() -> HomeViewController {
        let storyboard = UIStoryboard(name: "Home", bundle: nil) // change if different
        guard let vc = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else {
            fatalError("HomeViewController not found in storyboard")
        }
        return vc
    }
    
    private static func instantiateGroupVC() -> MyGroupViewController {
        let storyboard = UIStoryboard(name: "Home", bundle: nil) // change if different
        guard let vc = storyboard.instantiateViewController(withIdentifier: "MyGroupViewController") as? MyGroupViewController else {
            fatalError("HomeViewController not found in storyboard")
        }
        return vc
    }
    private static func instantiateChatVC() -> ChatVc {
        let storyboard = UIStoryboard(name: "Home", bundle: nil) // change if different
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ChatVc") as? ChatVc else {
            fatalError("HomeViewController not found in storyboard")
        }
        return vc
    }
    private static func instantiateSwipeVC() -> SwipeViewController {
        let storyboard = UIStoryboard(name: "Home", bundle: nil) // change if different
        guard let vc = storyboard.instantiateViewController(withIdentifier: "SwipeViewController") as? SwipeViewController else {
            fatalError("HomeViewController not found in storyboard")
        }
        return vc
    }
    
    private static func instantiateProfileVC() -> ProfileViewController {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil) // change if different
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController else {
            fatalError("HomeViewController not found in storyboard")
        }
        return vc
    }
    

    // MARK: - Setup Container
    private func setupContainer() {
        view.addSubview(containerView)
        view.addSubview(tabBarContainer)

        tabBarHeightConstraint = tabBarContainer.heightAnchor.constraint(equalToConstant: 80)

        NSLayoutConstraint.activate([
            tabBarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tabBarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tabBarContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            tabBarHeightConstraint,

            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Shape
        tabBarContainer.layer.cornerRadius = 40
        tabBarContainer.backgroundColor = UIColor.white.withAlphaComponent(0.05)

        // ⚠️ masksToBounds MUST be false for shadow to show
        tabBarContainer.layer.masksToBounds = false

        // Shadow (floating effect)
        tabBarContainer.layer.shadowColor = UIColor.black.cgColor
        tabBarContainer.layer.shadowOpacity = 0.5
        tabBarContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        tabBarContainer.layer.shadowRadius = 20
    }
    
 
    // MARK: - Setup Tab Bar
    private func setupTabBar() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        tabBarContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: tabBarContainer.topAnchor),
            stack.bottomAnchor.constraint(equalTo: tabBarContainer.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: tabBarContainer.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: tabBarContainer.trailingAnchor, constant: -8),
        ])

        for item in tabItems {
            let btn = makeTabButton(item: item)
            stack.addArrangedSubview(btn)
            tabButtons.append(btn)
        }
    }

    private func makeTabButton(item: TripsTabItem) -> UIButton {
        let btn = UIButton(type: .system)
        btn.tag = item.tag
        btn.tintColor = UIColor.white.withAlphaComponent(0.4)
        btn.imageView?.contentMode = .scaleAspectFit

        // Constrain the image to ~24pt so it fits cleanly inside the circle
        btn.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 22, weight: .regular),
            forImageIn: .normal
        )
        btn.setImage(UIImage(named: item.icon)?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func tabTapped(_ sender: UIButton) {
        switchTo(index: sender.tag)
    }

    // MARK: - Switch Tab

    // MARK: - Switch Tab

    private func switchTo(index: Int) {
        // Remove current child
        if let current = children.first {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        // Update button states
        for (i, btn) in tabButtons.enumerated() {
            let item = tabItems[i]
            let isSelected = i == index

            let iconName = isSelected ? item.selectedIcon : item.icon
            let image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
            btn.setImage(image, for: .normal)
            btn.tintColor = isSelected ? .white : UIColor.white.withAlphaComponent(0.4)

            // Remove old highlight circle
            btn.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }

            if isSelected {
                let circleSize: CGFloat = 52
                let circle = UIView()
                circle.tag = 999
                circle.backgroundColor = UIColor.themeOrange
                circle.layer.cornerRadius = circleSize / 2
                circle.isUserInteractionEnabled = false
                circle.translatesAutoresizingMaskIntoConstraints = false
                btn.insertSubview(circle, at: 0)
                NSLayoutConstraint.activate([
                    circle.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
                    circle.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
                    circle.widthAnchor.constraint(equalToConstant: circleSize),
                    circle.heightAnchor.constraint(equalToConstant: circleSize)
                ])
            }
        }

        // Add new child
        selectedIndex = index
        let vc = viewControllers[index]
        addChild(vc)
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParent: self)
    }
}

// MARK: - Placeholder VC for unbuilt tabs

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
        l.text = tabTitle
        l.textColor = .white
        l.font = .montserrat(20, weight: .semiBold)
        l.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(l)
        NSLayoutConstraint.activate([
            l.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            l.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
//    func makeNav(_ screen: AppScreen) -> UINavigationController {
//        return UINavigationController(rootViewController: ViewControllerFactory.make(screen))
//    }
}

extension UIViewController {
    var tripsTabBarController: TripsTabBarController? {
        var parentVC = self.parent
        while parentVC != nil {
            if let tab = parentVC as? TripsTabBarController {
                return tab
            }
            parentVC = parentVC?.parent
        }
        return nil
    }
}
