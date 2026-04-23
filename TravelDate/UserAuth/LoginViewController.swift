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
        label.text = "Log In"
        label.textColor = .white
        label.setFont(.semiBold, size: 22.0)
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
        btn.titleLabel?.setFont(.semiBold, size: 13.0)
        btn.addTarget(self, action: #selector(openForgot), for: .touchUpInside)
        return btn
    }()

    private let loginButton = CustomButton(title: "Log In", filled: true)

    private let googleButton = CustomButton(title: "Continue with Google", filled: false, hasIcon: true)

    private let signupLabel: UILabel = {
        let label = UILabel()
        
        let fullText = "Don't have an account? Sign Up"
        let attributed = NSMutableAttributedString(string: fullText)

        // Default color (white)
        attributed.addAttribute(
            .foregroundColor,
            value: UIColor.white,
            range: NSRange(location: 0, length: fullText.count)
        )

        // Highlight "Sign Up"
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

  @objc  func openForgot(){
        let vcForgot : ForgotPasswordViewController  = AppStoryBoard.Main.instance.instantiateViewController()
        self.navigationController?.pushViewController(vcForgot, animated: true)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSignupTap))
        signupLabel.addGestureRecognizer(tap)
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        loginButton.setFont(.semiBold, size: 18)
        googleButton.setFont(.semiBold, size: 18)
        googleButton.addTarget(self, action: #selector(handleGoogleTap), for: .touchUpInside)
      

        appleButton.addTarget(self, action: #selector(handleAppleLogin), for: .touchUpInside)
//        self.pushVC(TripsTabBarController.self, from: .Home)
    }
    
    @objc private func handleSignupTap() {
        self.pushVC(SignUpViewController.self, from: .Main)
        
//        let hostingVC = UIHostingController(rootView: SignUpView())
//        navigationController?.pushViewController(hostingVC, animated: true)
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
            let socialId = user.userID ?? ""   // 👈 IMPORTANT
            
            self.request.email =  email
            self.request.name =  name
            self.request.profile_image =  profileImage
            self.request.deviceToken = Constants.device_Config.deviceToken
            self.request.deviceType = Constants.device_Config.deviceToken
            self.request.social_type = "google"
            self.request.social_id = socialId
            
            self.request.socialLogin { loginUser, errMsg, errCode in
                
            }
        }
    }
    
    @objc private func handleLogin() {

        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Validation
        if email.isEmpty {
            showAlert(message: "Please enter email")
            return
        }

        if !isValidEmail(email) {
            showAlert(message: "Please enter valid email")
            return
        }

        if password.isEmpty {
            showAlert(message: "Please enter password")
            return
        }

        if password.count < 6 {
            showAlert(message: "Password must be at least 6 characters")
            return
        }

        // API Call or Navigation
        print("Login Success with email: \(email)")

        
        self.loginAPI(email: email, password: password)
    }
    
    
    func loginAPI(email: String, password: String) {
        
        request.email = email
        request.password = password
        request.deviceType = Constants.device_Config.deviceType
        request.deviceToken = Constants.device_Config.deviceToken
        
        request.loginAPi { loginUser, errMsg, errCode in
            
            if errCode == 200 {
                DispatchQueue.main.async {
                    self.pushVC(TripsTabBarController.self, from: .Home)
                    
                }
            }  else {
                self.showAlert(errMsg)
            }
            
        }
        
        
    }
    
    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black
        addGradient()
        view.addSubview(titleBox)
        view.addSubview(emailTitle)
        view.addSubview(passwordTitle)
        titleBox.addSubview(titleLabel)
        view.addSubview(loginLabel)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(forgotButton)
        view.addSubview(loginButton)
        view.addSubview(googleButton)
        view.addSubview(signupLabel)
        view.addSubview(appleButton)
        appleButton.translatesAutoresizingMaskIntoConstraints = false
        layout()
    }

    private func layout() {

        // MARK: - Disable autoresizing masks
        [
            titleBox, titleLabel, loginLabel,
            emailTitle, emailField,
            passwordTitle, passwordField,
            forgotButton, loginButton,
            googleButton,appleButton, signupLabel
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        // MARK: - Constraints
        NSLayoutConstraint.activate([

            // Logo Box
            titleBox.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            titleBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleBox.widthAnchor.constraint(equalToConstant: 100),
            titleBox.heightAnchor.constraint(equalToConstant: 100),

            titleLabel.centerXAnchor.constraint(equalTo: titleBox.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleBox.centerYAnchor),

            // Screen Title
            loginLabel.topAnchor.constraint(equalTo: titleBox.bottomAnchor, constant: 24),
            loginLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Email title
            emailTitle.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 24),
            emailTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            // Email field
            emailField.topAnchor.constraint(equalTo: emailTitle.bottomAnchor, constant: 6),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
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
            appleButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 14),
            appleButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            appleButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            appleButton.heightAnchor.constraint(equalToConstant: 50),
            // Bottom Label
            signupLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            signupLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
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

    // MARK: - Gradient

    private func addGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.cgColor,
            UIColor(red: 0.2, green: 0.1, blue: 0.1, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }
}


extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {

            let userId = credential.user
            let email = credential.email ?? UserDefaults.standard.string(forKey: "apple_email") ?? ""
            
            let fullName = credential.fullName
            let name = "\(fullName?.givenName ?? "") \(fullName?.familyName ?? "")"

            // Save for next login (Apple gives only once)
            if let email = credential.email {
                UserDefaults.standard.set(email, forKey: "apple_email")
            }

            let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Apple User" : name

            self.request.email =  email
            self.request.name =  finalName
            self.request.profile_image =  ""
            self.request.deviceToken = Constants.device_Config.deviceToken
            self.request.deviceType = Constants.device_Config.deviceToken
            self.request.social_type = "apple"
            self.request.social_id = userId
            
            self.request.socialLogin { loginUser, errMsg, errCode in
                
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        Toast.show(message: error.localizedDescription, view: self.view)
    }
    
    
}
