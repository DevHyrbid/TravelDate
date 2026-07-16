import UIKit
import SwiftUI

extension Font {
    static func appFont(_ name: String, size: CGFloat) -> Font {
        .custom(name, size: size)
    }
}

extension Color {
    static let appOrange = Color.orange
    static let fieldBG = Color.white.opacity(0.08)
}


class CustomTextField: UIView {

     let textField = UITextField()
    private let iconView = UIImageView()
    private let eyeButton = UIButton()

    var text: String? {
        return textField.text
    }

    init(placeholder: String, icon: String, isSecure: Bool = false) {
        super.init(frame: .zero)

        backgroundColor = UIColor.white.withAlphaComponent(0.06)
        layer.cornerRadius = 25
        layer.borderWidth = 1
        layer.borderColor = UIColor.clear.cgColor   // 👈 default no border

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        iconView.image = UIImage(systemName: icon, withConfiguration: config)
        iconView.tintColor = .lightGray
        iconView.contentMode = .scaleAspectFit

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )
        textField.textColor = .white
        textField.setFont(.regular, size: 12)
        textField.isSecureTextEntry = isSecure

        addSubview(iconView)
        addSubview(textField)

        // 👇 Track text changes
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        if isSecure {
            let eyeConfig = UIImage.SymbolConfiguration(pointSize: 18)
            eyeButton.setImage(UIImage(systemName: "eye", withConfiguration: eyeConfig), for: .normal)
            eyeButton.tintColor = .lightGray
            eyeButton.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)
            addSubview(eyeButton)
        }

        layoutUI(isSecure: isSecure)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Border change logic
    @objc private func textDidChange() {
        if let text = textField.text, !text.isEmpty {
            layer.borderColor = UIColor.orange.cgColor
        } else {
            layer.borderColor = UIColor.clear.cgColor
        }
    }

    private func layoutUI(isSecure: Bool) {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        eyeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: isSecure ? eyeButton.leadingAnchor : trailingAnchor, constant: -14),
        ])

        if isSecure {
            NSLayoutConstraint.activate([
                eyeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
                eyeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                eyeButton.widthAnchor.constraint(equalToConstant: 22),
                eyeButton.heightAnchor.constraint(equalToConstant: 22)
            ])
        }
    }

    @objc private func togglePassword() {
        textField.isSecureTextEntry.toggle()
        let iconName = textField.isSecureTextEntry ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
}
class CustomButton: UIButton {

    init(title: String, filled: Bool, hasIcon: Bool = false) {
        super.init(frame: .zero)

        setTitle(title, for: .normal)
        layer.cornerRadius = 27

        if filled {
            backgroundColor = UIColor.themeOrange
        } else {
            layer.borderWidth = 1
            layer.borderColor = UIColor.white.cgColor
        }

        if hasIcon {
            setImage(UIImage(systemName: "g.circle.fill"), for: .normal)
            tintColor = .white
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}



var tuple: (title: String, lat: Double, lng: Double)?

//
//  LoginVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 02/04/26.
//  Fixed: scroll + keyboard avoidance, confirm password field + validation
//

import UIKit
import GoogleSignIn

class SignUpViewController: BaseClassVc {

    // MARK: - Scroll

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.keyboardDismissMode = .interactive
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    // MARK: - UI Elements

    private let titleBox: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Trips"
        label.textColor = UIColor(named: "ThemeOrange") ?? .orange
        label.setFont(.bold, size: 22)
        label.textAlignment = .center
        return label
    }()

    private let loginLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign Up"
        label.textColor = .white
        label.setFont(.semiBold, size: 22)
        return label
    }()

    private let nameField = CustomTextField(placeholder: "Enter name", icon: "person")
    private let emailField = CustomTextField(placeholder: "Enter email", icon: "envelope")
    private let passwordField = CustomTextField(placeholder: "Enter your password", icon: "lock", isSecure: true)
    private let confirmPasswordField = CustomTextField(placeholder: "Re-enter your password", icon: "lock", isSecure: true)

    private let locationField = CustomTextField(placeholder: "Enter your Location", icon: "location", isSecure: false)

    private lazy var nameTitle = makeFieldTitle("Full Name")
    private lazy var emailTitle = makeFieldTitle("Email")
    private lazy var passwordTitle = makeFieldTitle("Password")
    private lazy var confirmPasswordTitle = makeFieldTitle("Confirm Password")
    private lazy var locationTitle = makeFieldTitle("Location")

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.setFont(.regular, size: 12)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let loginButton = CustomButton(title: "Sign Up", filled: true)
    private let googleButton = CustomButton(title: "Continue with Google", filled: false, hasIcon: true)

    private let signupLabel: UILabel = {
        let label = UILabel()
        let fullText = "Already have an account? Log In"
        let attributed = NSMutableAttributedString(string: fullText)
        attributed.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: fullText.count))
        let range = (fullText as NSString).range(of: "Log In")
        attributed.addAttribute(.foregroundColor, value: UIColor.orange, range: range)
        label.attributedText = attributed
        label.setFont(.semiBold, size: 13)
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        return label
    }()

    var locationView: LocationSearchView!

    // Track bottom-most active field for keyboard scroll math
    private weak var activeTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLoginTap))
        signupLabel.addGestureRecognizer(tap)

        loginButton.addTarget(self, action: #selector(handleSignupTap), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(handleGoogleTap), for: .touchUpInside)

        setuplocationVw()
        setupKeyboardHandling()
        setupDismissKeyboardOnTap()
        registerActiveFieldTracking()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Keyboard handling (fixes "keyboard blocking everything")

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    private func setupDismissKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func registerActiveFieldTracking() {
        [nameField, emailField, passwordField, confirmPasswordField, locationField].forEach {
            $0.textField.addTarget(self, action: #selector(fieldDidBeginEditing(_:)), for: .editingDidBegin)
        }
    }

    @objc private func fieldDidBeginEditing(_ sender: UITextField) {
        activeTextField = sender
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardHeight = keyboardFrame.cgRectValue.height
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom + 16

        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset

        // Scroll the active field just above the keyboard
        if let field = activeTextField {
            let fieldFrameInScroll = field.convert(field.bounds, to: scrollView)
            let visibleRect = fieldFrameInScroll.insetBy(dx: 0, dy: -60)
            scrollView.scrollRectToVisible(visibleRect, animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - Location

    func setuplocationVw() {
        locationView = LocationSearchView()
        locationView.isHidden = true
        locationView.attach(to: locationField.textField)
        locationView.onLocationSelected = { [weak self] address, coordinate in
            tuple = (address, Double(coordinate.latitude), Double(coordinate.longitude))
            self?.locationField.textField.text = address
            self?.locationView.isHidden = true
        }

        contentView.addSubview(locationView)
        locationView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            locationView.topAnchor.constraint(equalTo: locationField.bottomAnchor, constant: 8),
            locationView.leadingAnchor.constraint(equalTo: locationField.leadingAnchor),
            locationView.trailingAnchor.constraint(equalTo: locationField.trailingAnchor),
            locationView.heightAnchor.constraint(equalToConstant: 250)
        ])
    }

    @objc private func handleLoginTap() {
        self.backTapped()
    }

    // MARK: - Validation (fixes "add confirm password validation and fields")

    private func validateForm() -> String? {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        let confirmPassword = confirmPasswordField.text ?? ""
        let location = locationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if name.isEmpty {
            return "Please enter your name"
        }
        if email.isEmpty {
            return "Please enter your email"
        }
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        if location.isEmpty {
            return "Please select your location"
        }
        if password.isEmpty {
            return "Please enter a password"
        }
        if password.count < 6 {
            return "Password must be at least 6 characters"
        }
        if confirmPassword.isEmpty {
            return "Please confirm your password"
        }
        if password != confirmPassword {
            return "Passwords do not match"
        }
        return nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func showFieldError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    private func clearFieldError() {
        errorLabel.isHidden = true
        errorLabel.text = nil
    }

    @objc private func handleSignupTap() {
        clearFieldError()

        if let errorMessage = validateForm() {
            showFieldError(errorMessage)
//            showAlert(errorMessage)
            return
        }

        request.email = emailField.text ?? ""
        request.name = nameField.text ?? ""
        request.profile_image = ""
        request.password = passwordField.text ?? ""
        request.deviceToken = Constants.device_Config.deviceToken
        request.deviceType = Constants.device_Config.deviceType
        request.latitude = tuple?.lat ?? 0.0
        request.longitude = tuple?.lng ?? 0.0
        request.location_string = "\(String(describing: tuple?.title ?? ""))"

        request.signUp { loginUser, errMsg, errCode in
            if errCode == 200 {
                LocalNotificationManager.shared.scheduleNotification(
                    id: "welcome_user",
                    title: "Hey \(self.nameField.text ?? "") Welcome to Trips ✈️",
                    body: "You're all set! Let's find your perfect travel group.",
                    timeInterval: 4
                )

                UserDefaults.standard.set(self.locationField.text, forKey: "user_loc")
                self.pushVC(TripsTabBarController.self, from: .Home)
            } else {
//                self.showAlert(errMsg)
            }
        }
    }

    @objc private func handleGoogleTap() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                print("Google Sign-In error:", error.localizedDescription)
                return
            }

            guard let user = result?.user else { return }

            let email = user.profile?.email ?? ""
            let name = user.profile?.name ?? ""
            let profileImage = user.profile?.imageURL(withDimension: 200)?.absoluteString ?? ""
            let socialId = user.userID ?? ""

            self.request.email = email
            self.request.name = name
            self.request.profile_image = profileImage
            self.request.deviceToken = Constants.device_Config.deviceToken
            self.request.deviceType = Constants.device_Config.deviceToken
            self.request.social_type = "google"
            self.request.social_id = socialId

            self.request.socialLogin { loginUser, errMsg, errCode in
                if errCode == 200 {
                    DispatchQueue.main.async {
                        self.pushVC(TripsTabBarController.self, from: .Home)
                    }
                } else {
                    self.showAlert(errMsg)
                }
            }
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black
        addGradient()

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            // pins content width to scroll view width so vertical-only scrolling works
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        [
            titleBox, loginLabel,
            nameTitle, nameField,
            emailTitle, emailField,
            locationTitle, locationField,
            passwordTitle, passwordField,
            confirmPasswordTitle, confirmPasswordField,
            errorLabel,
            loginButton, googleButton,
            signupLabel
        ].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleBox.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        layout()
    }

    private func layout() {
        NSLayoutConstraint.activate([

            titleBox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            titleBox.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleBox.widthAnchor.constraint(equalToConstant: 100),
            titleBox.heightAnchor.constraint(equalToConstant: 100),

            titleLabel.centerXAnchor.constraint(equalTo: titleBox.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleBox.centerYAnchor),

            loginLabel.topAnchor.constraint(equalTo: titleBox.bottomAnchor, constant: 24),
            loginLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            nameTitle.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 24),
            nameTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            nameField.topAnchor.constraint(equalTo: nameTitle.bottomAnchor, constant: 6),
            nameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            nameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            nameField.heightAnchor.constraint(equalToConstant: 50),

            emailTitle.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
            emailTitle.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),

            emailField.topAnchor.constraint(equalTo: emailTitle.bottomAnchor, constant: 6),
            emailField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            emailField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            emailField.heightAnchor.constraint(equalToConstant: 50),

            locationTitle.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            locationTitle.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),

            locationField.topAnchor.constraint(equalTo: locationTitle.bottomAnchor, constant: 6),
            locationField.leadingAnchor.constraint(equalTo: locationTitle.leadingAnchor),
            locationField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            locationField.heightAnchor.constraint(equalToConstant: 50),

            passwordTitle.topAnchor.constraint(equalTo: locationField.bottomAnchor, constant: 16),
            passwordTitle.leadingAnchor.constraint(equalTo: locationField.leadingAnchor),

            passwordField.topAnchor.constraint(equalTo: passwordTitle.bottomAnchor, constant: 6),
            passwordField.leadingAnchor.constraint(equalTo: passwordTitle.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 50),

            confirmPasswordTitle.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 16),
            confirmPasswordTitle.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor),

            confirmPasswordField.topAnchor.constraint(equalTo: confirmPasswordTitle.bottomAnchor, constant: 6),
            confirmPasswordField.leadingAnchor.constraint(equalTo: confirmPasswordTitle.leadingAnchor),
            confirmPasswordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            confirmPasswordField.heightAnchor.constraint(equalToConstant: 50),

            errorLabel.topAnchor.constraint(equalTo: confirmPasswordField.bottomAnchor, constant: 10),
            errorLabel.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),

            loginButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 14),
            loginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 50),

            googleButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 14),
            googleButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            googleButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            googleButton.heightAnchor.constraint(equalToConstant: 50),

            signupLabel.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 20),
            signupLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            signupLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
}
