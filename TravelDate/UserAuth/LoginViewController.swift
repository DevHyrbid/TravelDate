//
//  LoginVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 02/04/26.
//
import SwiftUI
import UIKit
import GoogleSignIn
import AuthenticationServices

class LoginViewController: BaseClassVc {

    // MARK: - Scroll Container

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .clear
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // MARK: - UI Elements

    private let titleBox: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let tripsImg: UIImageView = {
        let img = UIImageView()
        img.image = UIImage(named: "trips")
        return img
    }()

    private let loginLabel: UILabel = {
        let label = UILabel()
        label.text = "Log In"
        label.textColor = .white
        label.setFont(.bold, size: 20.0)
        return label
    }()

    private let appleButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        button.cornerRadius = 25
        return button
    }()

    private lazy var emailTitle = makeFieldTitle("Email")
    private lazy var passwordTitle = makeFieldTitle("Password")

    private let emailField = CustomTextField(placeholder: "Enter email", icon: "envelope")

    private let passwordField = CustomTextField(placeholder: "Enter your password", icon: "lock", isSecure: true)

    private let forgotButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Forgot Password?", for: .normal)
        btn.setTitleColor(UIColor(named: "ThemeOrange") ?? .orange, for: .normal)
        btn.titleLabel?.setFont(.semiBold, size: 12.0)
        btn.addTarget(self, action: #selector(openForgot), for: .touchUpInside)
        return btn
    }()

    private let loginButton = CustomButton(title: "Log In", filled: true)

    private let googleButton = CustomButton(title: "Continue with Google", filled: false, hasIcon: true)

    private let signupLabel: UILabel = {
        let label = UILabel()

        let fullText = "Don't have an account? Sign Up"
        let attributed = NSMutableAttributedString(string: fullText)

        attributed.addAttribute(
            .foregroundColor,
            value: UIColor.white,
            range: NSRange(location: 0, length: fullText.count)
        )

        let range = (fullText as NSString).range(of: "Sign Up")
        attributed.addAttribute(
            .foregroundColor,
            value: UIColor(named: "ThemeOrange") ?? .orange,
            range: range
        )

        label.attributedText = attributed
        label.setFont(.semiBold, size: 14.0)
        label.isUserInteractionEnabled = true
        label.textAlignment = .center

        return label
    }()

    @objc func openForgot() {
        let vcForgot: ForgotPasswordViewController = AppStoryBoard.Main.instance.instantiateViewController()
        self.navigationController?.pushViewController(vcForgot, animated: true)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSignupTap))
        signupLabel.addGestureRecognizer(tap)

        // Tap anywhere outside fields to dismiss keyboard
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(dismissTap)

        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)

        loginButton.setFont(.semiBold, size: 18)
        googleButton.setFont(.semiBold, size: 18)
        googleButton.addTarget(self, action: #selector(handleGoogleTap), for: .touchUpInside)

        appleButton.addTarget(self, action: #selector(handleAppleLogin), for: .touchUpInside)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func handleSignupTap() {
        self.pushVC(SignUpViewController.self, from: .Main)
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
            self.request.deviceType = Constants.device_Config.deviceType
            self.request.deviceToken = Constants.device_Config.deviceToken
            self.request.social_type = "google"
            self.request.social_id = socialId

            self.request.socialLogin { loginUser, errMsg, errCode in
                DispatchQueue.main.async {
                    if errCode == 200 {
                        AppData.shared.justAuthenticated = true
                        self.pushVC(TripsTabBarController.self, from: .Home)
                    } else {
                        self.showAlert(errMsg)
                    }
                }
            }
        }
    }

    @objc private func handleLogin() {
        view.endEditing(true)

        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if email.isEmpty {
            showAlert("Please enter email")
            return
        }

        if !isValidEmail(email) {
            showAlert("Please enter valid email")
            return
        }

        if password.isEmpty {
            showAlert("Please enter password")
            return
        }

        if password.count < 6 {
            showAlert("Password must be at least 6 characters")
            return
        }

        self.loginAPI(email: email, password: password)
    }

    func loginAPI(email: String, password: String) {

        request.email = email
        request.password = password
        request.deviceType = Constants.device_Config.deviceType
        request.deviceToken = Constants.device_Config.deviceToken

        request.loginAPi { loginUser, errMsg, errCode in
            DispatchQueue.main.async {
                if errCode == 200 {
                    AppData.shared.justAuthenticated = true
                    self.pushVC(TripsTabBarController.self, from: .Home)
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
        scrollView.addSubview(contentView)

        [
            titleBox, loginLabel,
            emailTitle, emailField,
            passwordTitle, passwordField,
            forgotButton, loginButton,
            googleButton, appleButton,
            signupLabel
        ].forEach { contentView.addSubview($0) }

        titleBox.addSubview(tripsImg)

        layout()
    }

    private func layout() {

        [
            scrollView, contentView,
            titleBox, tripsImg, loginLabel,
            emailTitle, emailField,
            passwordTitle, passwordField,
            forgotButton, loginButton,
            googleButton, appleButton, signupLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let frameGuide = scrollView.frameLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide

        // Content fills at least the visible screen, so Sign Up stays at the bottom on big phones
        let minHeight = contentView.heightAnchor.constraint(greaterThanOrEqualTo: frameGuide.heightAnchor)

        NSLayoutConstraint.activate([

            // MARK: Scroll View — bottom follows keyboard automatically
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            // MARK: Content View
            contentView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            minHeight,

            // Logo Box
            titleBox.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            titleBox.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleBox.widthAnchor.constraint(equalToConstant: 100),
            titleBox.heightAnchor.constraint(equalToConstant: 100),

            tripsImg.centerXAnchor.constraint(equalTo: titleBox.centerXAnchor),
            tripsImg.centerYAnchor.constraint(equalTo: titleBox.centerYAnchor),

            // Screen Title
            loginLabel.topAnchor.constraint(equalTo: titleBox.bottomAnchor, constant: 24),
            loginLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Email title
            emailTitle.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 24),
            emailTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            // Email field
            emailField.topAnchor.constraint(equalTo: emailTitle.bottomAnchor, constant: 6),
            emailField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            emailField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            emailField.heightAnchor.constraint(equalToConstant: 50),

            // Password title
            passwordTitle.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            passwordTitle.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),

            // Password field
            passwordField.topAnchor.constraint(equalTo: passwordTitle.bottomAnchor, constant: 6),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 50),

            // Forgot Password
            forgotButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 6),
            forgotButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),

            // Login Button
            loginButton.topAnchor.constraint(equalTo: forgotButton.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 50),

            // Google Button
            googleButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 14),
            googleButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            googleButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            googleButton.heightAnchor.constraint(equalToConstant: 50),

            // Apple Button
            appleButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 14),
            appleButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            appleButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            appleButton.heightAnchor.constraint(equalToConstant: 50),

            // Bottom Label — never overlaps Apple button, pinned to bottom of content
            signupLabel.topAnchor.constraint(greaterThanOrEqualTo: appleButton.bottomAnchor, constant: 24),
            signupLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            signupLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }

    @objc private func handleAppleLogin() {

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - Apple Sign In

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

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
                DispatchQueue.main.async {
                    if errCode == 200 {
                        AppData.shared.justAuthenticated = true
                        self.pushVC(TripsTabBarController.self, from: .Home)
                    } else {
                        self.showAlert(errMsg)
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In error:", error.localizedDescription)
    }
}
