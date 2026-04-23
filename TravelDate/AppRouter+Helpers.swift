//
//  AppRouter.swift
//  TravelDate
//
//  Created by Dev CodingZone
//
//  Central navigation router for the Trips app.
//  All VC transitions go through here for consistency.
//

import UIKit

// MARK: - App Router

final class AppRouter {

    static let shared = AppRouter()
    private init() {}

    // MARK: - Root Setup

    /// Call from SceneDelegate/AppDelegate to set initial root
    func setRoot(in window: UIWindow?) {
        let vc = OnboardingViewController.fromStoryboard()
        let nav = UINavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }

    // MARK: - Auth Flow

    func goToLogin(from nav: UINavigationController?) {
        let vc = LoginViewController()
        nav?.pushViewController(vc, animated: true)
    }

    func goToSignUp(from nav: UINavigationController?) {
//        let vc = SignUpViewController()
//        nav?.pushViewController(vc, animated: true)
    }

    func goToForgotPassword(from nav: UINavigationController?) {
        let vc = ForgotPasswordViewController()
        nav?.pushViewController(vc, animated: true)
    }

    func goToEmailVerification(email: String, from nav: UINavigationController?) {
        let vc = EmailVerificationViewController()
        vc.email = email
        nav?.pushViewController(vc, animated: true)
    }

    func goToOTPVerification(from nav: UINavigationController?) {
        let vc = OTPVc()
        nav?.pushViewController(vc, animated: true)
    }

    // MARK: - Main App Flow

    func goToWelcome(from nav: UINavigationController?) {
        let vc = WelcomeViewController()
        nav?.pushViewController(vc, animated: true)
    }

    func goToCreateGroup(from nav: UINavigationController?) {
//        let vc = CreateGroupViewController()
//        nav?.pushViewController(vc, animated: true)
    }

    func goToInviteFriends(from nav: UINavigationController?) {
//        let vc = InviteFriendsViewController()
//        nav?.pushViewController(vc, animated: true)
    }

    // MARK: - Pop / Dismiss

    func goBack(from nav: UINavigationController?) {
        nav?.popViewController(animated: true)
    }

    func goToRoot(from nav: UINavigationController?) {
        nav?.popToRootViewController(animated: true)
    }
}

// MARK: - OnboardingViewController Storyboard Init

extension OnboardingViewController {
    static func fromStoryboard() -> OnboardingViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "OnboardingViewController") as! OnboardingViewController
    }
}


// ============================================================
// MARK: - TripsTheme
// ============================================================

struct TripsTheme {

    // MARK: - Colors
    struct Color {
        static let primary     = UIColor.orange
        static let background  = UIColor.black
        static let cardBG      = UIColor(white: 0.1, alpha: 1)
        static let fieldBG     = UIColor.white.withAlphaComponent(0.06)
        static let textPrimary = UIColor.white
        static let textMuted   = UIColor.white.withAlphaComponent(0.5)
        static let border      = UIColor.white.withAlphaComponent(0.15)
        static let divider     = UIColor.white.withAlphaComponent(0.12)
        static let gradient    = [UIColor.black.cgColor,
                                  UIColor(red: 0.12, green: 0.04, blue: 0.01, alpha: 1).cgColor]
    }

    // MARK: - Fonts (use .montserrat extensions)
    struct Font {
        static func heading(_ size: CGFloat = 22) -> UIFont { .montserrat(size, weight: .bold) }
        static func subheading(_ size: CGFloat = 18) -> UIFont { .montserrat(size, weight: .semiBold) }
        static func body(_ size: CGFloat = 14) -> UIFont { .montserrat(size) }
        static func caption(_ size: CGFloat = 12) -> UIFont { .montserrat(size) }
        static func button(_ size: CGFloat = 16) -> UIFont { .montserrat(size, weight: .semiBold) }
    }

    // MARK: - Radius
    struct Radius {
        static let button: CGFloat  = 28
        static let field: CGFloat   = 14
        static let card: CGFloat    = 18
        static let small: CGFloat   = 10
        static let logo: CGFloat    = 18
    }

    // MARK: - Spacing
    struct Spacing {
        static let screenH: CGFloat = 24
        static let itemV: CGFloat   = 16
        static let sectionV: CGFloat = 28
    }

    // MARK: - Shared gradient layer
    static func makeGradientLayer(for view: UIView) -> CAGradientLayer {
        let g = CAGradientLayer()
        g.colors = Color.gradient
        g.locations = [0.0, 1.0]
        g.frame = view.bounds
        return g
    }
}


// ============================================================
// MARK: - UIViewController Extensions (Trips-specific)
// ============================================================

extension UIViewController {

    // MARK: - Gradient Helper
    func addTripsGradient() {
        let g = TripsTheme.makeGradientLayer(for: view)
        view.layer.insertSublayer(g, at: 0)
    }

    // MARK: - Trips Logo Box
    func makeTripsLogoBox(size: CGFloat = 90) -> (container: UIView, label: UILabel) {
        let box = UIView()
        box.layer.cornerRadius = TripsTheme.Radius.logo
        box.layer.borderWidth = 1
        box.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        box.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = "Trips"
        lbl.textColor = .orange
        lbl.font = .montserrat(size * 0.28, weight: .bold)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(lbl)

        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: box.centerYAnchor)
        ])

        return (box, lbl)
    }

    // MARK: - Trips Primary Button
    func makePrimaryOrangeButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = TripsTheme.Font.button()
        b.backgroundColor = TripsTheme.Color.primary
        b.layer.cornerRadius = TripsTheme.Radius.button
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    // MARK: - Nav Title Label
    func makeTripsNavTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = .white
        l.font = TripsTheme.Font.subheading()
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    // MARK: - Trips Back Button
    func makeTripsBackButton(target: Any?, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(target, action: action, for: .touchUpInside)
        return b
    }

    // MARK: - Keyboard Dismiss
    func hideKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(view.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Keyboard Avoidance
    func registerKeyboardObservers(scrollView: UIScrollView) {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                               object: nil, queue: .main) { note in
            if let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                scrollView.contentInset.bottom = frame.height + 20
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                               object: nil, queue: .main) { _ in
            scrollView.contentInset.bottom = 0
        }
    }

    // MARK: - Loading Indicator
    private static var loadingOverlay: UIView?

    func showLoader() {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.tag = 9999

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .orange
        spinner.center = overlay.center
        spinner.startAnimating()
        overlay.addSubview(spinner)

        view.addSubview(overlay)
    }

    func hideLoader() {
        view.viewWithTag(9999)?.removeFromSuperview()
    }

    // MARK: - Toast
    func showToast(_ message: String, duration: Double = 2.5) {
        let toast = PaddingLabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = UIColor(white: 0.15, alpha: 0.95)
        toast.font = .montserrat(13)
        toast.layer.cornerRadius = 12
        toast.clipsToBounds = true
        toast.textAlignment = .center
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])

        toast.alpha = 0
        UIView.animate(withDuration: 0.3, animations: { toast.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    // MARK: - Input Validation Shake
    func shake(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        view.layer.add(animation, forKey: "shake")
    }

    // MARK: - Highlighted attributed text builder
    func makeAttributedText(full: String, highlight: String,
                             normalColor: UIColor = .white,
                             highlightColor: UIColor = .orange,
                             font: UIFont = .montserrat(13)) -> NSAttributedString {
        let attr = NSMutableAttributedString(
            string: full,
            attributes: [.foregroundColor: normalColor, .font: font]
        )
        let range = (full as NSString).range(of: highlight)
        attr.addAttribute(.foregroundColor, value: highlightColor, range: range)
        return attr
    }
}


// ============================================================
// MARK: - String Validation Extensions
// ============================================================

extension String {
    var isNotEmpty: Bool { !isEmpty }

    func isValidPassword() -> Bool {
        // Minimum 8 chars, at least 1 letter and 1 number
        let regex = "^(?=.*[A-Za-z])(?=.*\\d).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }

    func trimmed() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


// ============================================================
// MARK: - UIView Helpers
// ============================================================

extension UIView {

    // Add dashed border as a sublayer
    func addDashedBorder(color: UIColor = .orange, dashPattern: [NSNumber] = [6, 4], cornerRadius: CGFloat = 14) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.withAlphaComponent(0.6).cgColor
        shapeLayer.lineDashPattern = dashPattern
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 1.5
        shapeLayer.frame = bounds
        shapeLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        layer.addSublayer(shapeLayer)
    }

    // Round only specific corners
    func roundCorners(_ corners: CACornerMask, radius: CGFloat) {
        layer.cornerRadius = radius
        layer.maskedCorners = corners
    }

    // Pulse animation (for buttons)
    func pulse(scale: CGFloat = 0.96, duration: Double = 0.1) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { _ in
            UIView.animate(withDuration: duration) {
                self.transform = .identity
            }
        }
    }

    // Gradient overlay (e.g., image bottom fade)
    func addBottomGradientOverlay(from: UIColor = .clear, to: UIColor = .black) {
        let gradient = CAGradientLayer()
        gradient.colors = [from.cgColor, to.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.frame = bounds
        layer.addSublayer(gradient)
    }
}


// ============================================================
// MARK: - UIImageView Circle Clip
// ============================================================

extension UIImageView {
    func makeCircle() {
        layer.cornerRadius = bounds.width / 2
        clipsToBounds = true
    }
}


// ============================================================
// MARK: - Date Helpers
// ============================================================

extension Date {
    func formatted(_ format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: self)
    }

    var displayDate: String { formatted("MMM dd, yyyy") }
    var displayDateTime: String { formatted("MMM dd, yyyy HH:mm") }
    var apiFormat: String { formatted("yyyy-MM-dd") }

    func isBefore(_ other: Date) -> Bool { self < other }
    func isAfter(_ other: Date) -> Bool { self > other }
}


// ============================================================
// MARK: - UserDefaults Simple Keys
// ============================================================

enum AppStorageKey: String {
    case isOnboarded       = "app_is_onboarded"
    case isLoggedIn        = "app_is_logged_in"
    case authToken         = "app_auth_token"
    case currentUserID     = "app_current_user_id"
    case currentUserEmail  = "app_current_user_email"
    case currentUserName   = "app_current_user_name"
}

extension UserDefaults {

    static func set(_ value: Any?, for key: AppStorageKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static func get(_ key: AppStorageKey) -> Any? {
        return UserDefaults.standard.value(forKey: key.rawValue)
    }

    static func getString(_ key: AppStorageKey) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }

    static func getBool(_ key: AppStorageKey) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

    static func remove(_ key: AppStorageKey) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }

    static func clearAll() {
        AppStorageKey.allCases.forEach { remove($0) }
    }
}

extension AppStorageKey: CaseIterable {}


// ============================================================
// MARK: - TripInputValidator
// ============================================================

struct TripInputValidator {

    static func validateEmail(_ email: String?) -> String? {
        guard let email = email?.trimmed(), !email.isEmpty else {
            return Constants.Validation.emailEmpty
        }
        guard email.isValidEmail() else {
            return Constants.Validation.emailInvalid
        }
        return nil
    }

    static func validatePassword(_ password: String?) -> String? {
        guard let pass = password?.trimmed(), !pass.isEmpty else {
            return Constants.Validation.password
        }
        return nil
    }

    static func validateName(_ name: String?) -> String? {
        guard let name = name?.trimmed(), !name.isEmpty else {
            return Constants.Validation.name
        }
        return nil
    }

    static func validatePasswordMatch(_ pass: String?, confirm: String?) -> String? {
        guard pass == confirm else { return Constants.Validation.passwordMatch }
        return nil
    }
}
