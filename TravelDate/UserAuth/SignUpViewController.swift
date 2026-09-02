import UIKit
import SwiftUI
import GoogleSignIn
import AuthenticationServices
var tuple: (title: String, lat: Double, lng: Double)?


extension Font {
    static func appFont(_ name: String, size: CGFloat) -> Font {
        .custom(name, size: size)
    }
}

extension Color {
    static let appOrange = Color.orange
    static let fieldBG = Color.white.opacity(0.08)
}



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

    private let appleButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        button.cornerRadius = 25
        return button
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


    
    private let termsCheckBox: UIButton = {
        let button = UIButton(type: .custom)

        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
        button.backgroundColor = .clear

        button.setTitle("✓", for: .selected)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)

        button.isSelected = false

        return button
    }()
    
    private let termsLabel: UILabel = {
        let label = UILabel()
        
        let fullText = "I agree to the Terms of Use and EULA"
        let attributed = NSMutableAttributedString(string: fullText)
        
        attributed.addAttribute(
            .foregroundColor,
            value: UIColor.appOrange,
            range: NSRange(location: 0, length: fullText.count)
        )
        
        label.attributedText = attributed
        label.setFont(.regular, size: 13)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.textAlignment = .left
        
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
        appleButton.addTarget(self, action: #selector(handleAppleLogin), for: .touchUpInside)

        setuplocationVw()
        setupKeyboardHandling()
        setupDismissKeyboardOnTap()
        registerActiveFieldTracking()
        termsCheckBox.addTarget(
            self,
            action: #selector(handleTermsCheckbox),
            for: .touchUpInside
        )
    }

    @objc private func handleTermsCheckbox() {
        termsCheckBox.isSelected.toggle()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Keyboard handling

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

    // MARK: - Validation

    private func validateForm() -> String? {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        let confirmPassword = confirmPasswordField.text ?? ""
        let location = locationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if name.isEmpty { return "Please enter your name" }
        if email.isEmpty { return "Please enter your email" }
        if !isValidEmail(email) { return "Please enter a valid email address" }
        if location.isEmpty { return "Please select your location" }
        if password.isEmpty { return "Please enter a password" }
        if password.count < 6 { return "Password must be at least 6 characters" }
        if confirmPassword.isEmpty { return "Please confirm your password" }
        if password != confirmPassword { return "Passwords do not match" }
        if !termsCheckBox.isSelected {
            return "Please accept the Terms of Use and EULA"
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
                // self.showAlert(errMsg)
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
            self.request.deviceType = Constants.device_Config.deviceType
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

    // MARK: - Apple Sign In

    @objc private func handleAppleLogin() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
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
            termsCheckBox,
            termsLabel,
            loginButton, googleButton, appleButton,
            signupLabel
        ].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleBox.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let termsTap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTermsTap)
        )

        termsLabel.addGestureRecognizer(termsTap)
        layout()
    }

    @objc private func handleTermsTap() {
        let legalVC = LegalViewController()
        
        let nav = UINavigationController(
            rootViewController: legalVC
        )
        
        present(nav, animated: true)
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

            termsCheckBox.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 14),
            termsCheckBox.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            termsCheckBox.widthAnchor.constraint(equalToConstant: 20),
            termsCheckBox.heightAnchor.constraint(equalToConstant: 20),

            termsLabel.centerYAnchor.constraint(equalTo: termsCheckBox.centerYAnchor),
            termsLabel.leadingAnchor.constraint(equalTo: termsCheckBox.trailingAnchor, constant: 8),
            termsLabel.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),

            loginButton.topAnchor.constraint(equalTo: termsLabel.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            googleButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 14),
            googleButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            googleButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            googleButton.heightAnchor.constraint(equalToConstant: 50),

            appleButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 14),
            appleButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            appleButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            appleButton.heightAnchor.constraint(equalToConstant: 50),

            signupLabel.topAnchor.constraint(equalTo: appleButton.bottomAnchor, constant: 20),
            signupLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            signupLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    
}

extension SignUpViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {

            let userId = credential.user
            let savedEmail = UserDefaults.standard.string(forKey: "apple_email")

            let safeUserId = userId
                .replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)

            let email = credential.email
                ?? savedEmail
                ?? "\(safeUserId)@privaterelay.appleid.com"

            let fullName = credential.fullName
            let name = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")"

            if let email = credential.email {
                UserDefaults.standard.set(email, forKey: "apple_email")
            }

            let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Apple User" : name

            self.request.email = email
            self.request.name = finalName
            self.request.profile_image = ""
            self.request.deviceToken = Constants.device_Config.deviceToken
            self.request.deviceType = Constants.device_Config.deviceType
            self.request.social_type = "apple"
            self.request.social_id = userId

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

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Toast.show(message: error.localizedDescription, view: self.view)
    }
}
