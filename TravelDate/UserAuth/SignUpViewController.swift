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

    private let textField = UITextField()
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
        textField.setFont(.regular, size: 16)
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




//
//  LoginVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 02/04/26.
//

import UIKit
import GoogleSignIn

class SignUpViewController: BaseClassVc {

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

    private let nameField = CustomTextField(placeholder: "Enter name", icon: "envelope")
    private let emailField = CustomTextField(placeholder: "Enter email", icon: "envelope")
    private let passwordField = CustomTextField(placeholder: "Enter your password", icon: "lock", isSecure: true)

    private lazy var nameTitle = makeFieldTitle("Full Name")
    private lazy var emailTitle = makeFieldTitle("Email")
    private lazy var passwordTitle = makeFieldTitle("Password")

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
       
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleLoginTap))
            signupLabel.addGestureRecognizer(tap)
        
        loginButton.addTarget(self, action: #selector(handleSignupTap), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(handleGoogleTap), for: .touchUpInside)
        
    }
    
    @objc private func handleLoginTap() {
        print("Log In tapped")
        self.backTapped()
    }

    @objc private func handleSignupTap() {
        print("Sign Up tapped")

        request.email =  emailField.text ?? ""
        request.name =  nameField.text ?? ""
        request.profile_image =  ""
        request.password = passwordField.text ?? ""
        request.deviceToken = Constants.device_Config.deviceToken
        request.deviceType = Constants.device_Config.deviceType
        request.signUp { loginUser, errMsg, errCode in
            if errCode == 200 {
                self.pushVC(TripsTabBarController.self, from: .Home)
            } else {
                self.showAlert(errMsg)
            }
        }
//
//        APIManager.shared.request(
//            url: "http://85.31.234.205:9800/api/v1/users/create",
//            body: params
//        ) { result in
//            
//            switch result {
//            case .success(let response):
//                print("Signup Success:", response)
//                DispatchQueue.main.async {
//                    self.handleAuthResponse(response)
//                    self.pushVC(TripsTabBarController.self, from: .Home)
//                }
//
//            case .failure(let error):
//                print("Signup Error:", error.localizedDescription)
//            }
//        }
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
    
    private func setupUI() {
        view.backgroundColor = .black
        addGradient()

        [
            titleBox, loginLabel,
            nameTitle, nameField,
            emailTitle, emailField,
            passwordTitle, passwordField,
            loginButton, googleButton,
            signupLabel
        ].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleBox.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        layout()
    }

    private func layout() {
        NSLayoutConstraint.activate([

            titleBox.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            titleBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleBox.widthAnchor.constraint(equalToConstant: 100),
            titleBox.heightAnchor.constraint(equalToConstant: 100),

            titleLabel.centerXAnchor.constraint(equalTo: titleBox.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleBox.centerYAnchor),

            loginLabel.topAnchor.constraint(equalTo: titleBox.bottomAnchor, constant: 24),
            loginLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nameTitle.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 24),
            nameTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            nameField.topAnchor.constraint(equalTo: nameTitle.bottomAnchor, constant: 6),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nameField.heightAnchor.constraint(equalToConstant: 50),

            emailTitle.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 16),
            emailTitle.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),

            emailField.topAnchor.constraint(equalTo: emailTitle.bottomAnchor, constant: 6),
            emailField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            emailField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            emailField.heightAnchor.constraint(equalToConstant: 50),

            passwordTitle.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            passwordTitle.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),

            passwordField.topAnchor.constraint(equalTo: passwordTitle.bottomAnchor, constant: 6),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 50),

            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 50),

            googleButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 14),
            googleButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            googleButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            googleButton.heightAnchor.constraint(equalToConstant: 50),

            signupLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            signupLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func addGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.cgColor,
            UIColor(red: 0.2, green: 0.1, blue: 0.1, alpha: 1).cgColor
        ]
        gradient.locations = [0, 1]
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }

   
}
