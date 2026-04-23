
//
//  ForgotPasswordViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone
//

import UIKit

// MARK: - Forgot Password

class ForgotPasswordViewController: BaseClassVc {

    // MARK: - UI

    private let logoBox: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 18
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        b.tintColor = .white
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text = "Trips"
        l.textColor = .orange
        l.font = .montserrat(24, weight: .bold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Forgot Password"
        l.textColor = .white
        l.font = .montserrat(22, weight: .semiBold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Please enter your email here, you will receive a link for creating new password."
        l.textColor = UIColor.white.withAlphaComponent(0.55)
        l.font = .montserrat(13)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emailLabel: UILabel = {
        let l = UILabel()
        l.text = "Email"
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.font = .montserrat(13, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emailField = CustomTextField(placeholder: "dummy@email.com", icon: "envelope")

    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Send", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .montserrat(16, weight: .semiBold)
        b.backgroundColor = .orange
        b.layer.cornerRadius = 27
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let bottomStack: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var signupLabel: UILabel = {
        let l = UILabel()
        let fullText = "Don't have an account? Sign Up"
        let attr = NSMutableAttributedString(string: fullText)
        attr.addAttribute(.foregroundColor, value: UIColor.orange,
                          range: (fullText as NSString).range(of: "Sign Up"))
        l.attributedText = attr
        l.textColor = .white
        l.font = .montserrat(13)
        l.textAlignment = .center
        l.isUserInteractionEnabled = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }

    private func setupUI() {
        view.addSubview(backButton)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.backgroundColor = .black
        addGradient()
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(logoBox)
        logoBox.addSubview(logoLabel)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emailLabel)

        emailField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailField)
        view.addSubview(sendButton)
        view.addSubview(signupLabel)
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(goToSignUp))
        signupLabel.addGestureRecognizer(tap)
    }

    @objc private func sendTapped() {
        guard let email = emailField.textValue, !email.isEmpty, email.isValidEmail() else {
            shakeField()
            return
        }
        // Navigate to Email Verification
        let vc = EmailVerificationViewController()
        vc.email = email
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func goToSignUp() {
//        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    private func shakeField() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, 0]
        emailField.layer.add(animation, forKey: "shake")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 30),
            logoBox.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            logoBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoBox.widthAnchor.constraint(equalToConstant: 90),
            logoBox.heightAnchor.constraint(equalToConstant: 90),

            logoLabel.centerXAnchor.constraint(equalTo: logoBox.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoBox.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: logoBox.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            emailLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            emailField.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            emailField.heightAnchor.constraint(equalToConstant: 50),

            sendButton.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 28),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            sendButton.heightAnchor.constraint(equalToConstant: 54),

            signupLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            signupLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func addGradient() {
        let g = CAGradientLayer()
        g.colors = [UIColor.black.cgColor,
                    UIColor(red: 0.12, green: 0.04, blue: 0.01, alpha: 1).cgColor]
        g.frame = view.bounds
        view.layer.insertSublayer(g, at: 0)
    }
}

// MARK: - Extension for textValue on CustomTextField

extension CustomTextField {
    var textValue: String? {
        // Access via subview introspection
        return subviews.compactMap { $0 as? UITextField }.first?.text
    }
}

// MARK: - Email Verification VC

class EmailVerificationViewController: UIViewController, UITextFieldDelegate {

    var email: String = ""

    // MARK: - UI

    private let logoBox: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 18
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let logoLabel: UILabel = {
        let l = UILabel()
        l.text = "Trips"
        l.textColor = .orange
        l.font = .montserrat(24, weight: .bold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Email Verification"
        l.textColor = .white
        l.font = .montserrat(22, weight: .semiBold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "A 4-digit PIN has been sent to your mail.\nEnter the code below to continue."
        l.textColor = UIColor.white.withAlphaComponent(0.55)
        l.font = .montserrat(13)
        l.numberOfLines = 2
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - OTP Fields

    private var otpFields: [UITextField] = []

    private let otpStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 14
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Confirm Button

    private let confirmButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Confirm", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .montserrat(16, weight: .semiBold)
        b.backgroundColor = .orange
        b.layer.cornerRadius = 27
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var resendLabel: UILabel = {
        let l = UILabel()
        let fullText = "Resend Code?"
        let attr = NSMutableAttributedString(string: fullText)
        attr.addAttribute(.foregroundColor, value: UIColor.orange,
                          range: (fullText as NSString).range(of: "Resend Code?"))
        l.attributedText = attr
        l.textColor = .white
        l.font = .montserrat(13)
        l.textAlignment = .center
        l.isUserInteractionEnabled = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var loginLabel: UILabel = {
        let l = UILabel()
        let fullText = "Already have an account? Log In"
        let attr = NSMutableAttributedString(string: fullText)
        attr.addAttribute(.foregroundColor, value: UIColor.orange,
                          range: (fullText as NSString).range(of: "Log In"))
        l.attributedText = attr
        l.textColor = .white
        l.font = .montserrat(13)
        l.textAlignment = .center
        l.isUserInteractionEnabled = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }

    private func setupUI() {
        view.backgroundColor = .black
        addGradient()
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(logoBox)
        logoBox.addSubview(logoLabel)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(otpStack)
        view.addSubview(confirmButton)
        view.addSubview(resendLabel)
        view.addSubview(loginLabel)

        // Create 4 OTP fields
        for i in 0..<4 {
            let tf = UITextField()
            tf.backgroundColor = UIColor(white: 0.13, alpha: 1)
            tf.textAlignment = .center
            tf.font = .montserrat(20, weight: .semiBold)
            tf.textColor = .white
            tf.layer.cornerRadius = 16
            tf.layer.borderWidth = 1
            tf.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
            tf.keyboardType = .numberPad
            tf.delegate = self
            tf.tag = i
            tf.addTarget(self, action: #selector(otpChanged(_:)), for: .editingChanged)
            otpStack.addArrangedSubview(tf)
            otpFields.append(tf)
        }
    }

    private func setupActions() {
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        let resendTap = UITapGestureRecognizer(target: self, action: #selector(resendCode))
        resendLabel.addGestureRecognizer(resendTap)
        let loginTap = UITapGestureRecognizer(target: self, action: #selector(goToLogin))
        loginLabel.addGestureRecognizer(loginTap)
    }

    @objc private func otpChanged(_ tf: UITextField) {
        if tf.text?.count == 1 {
            let next = tf.tag + 1
            if next < otpFields.count {
                otpFields[next].becomeFirstResponder()
            } else {
                tf.resignFirstResponder()
            }
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            textField.text = ""
            let prev = textField.tag - 1
            if prev >= 0 { otpFields[prev].becomeFirstResponder() }
            return false
        }
        return textField.text?.isEmpty ?? true
    }

    @objc private func confirmTapped() {
        let otp = otpFields.compactMap { $0.text }.joined()
        if otp.count == 4 {
            print("Verified OTP: \(otp)")
            // Navigate to main app or reset password
        } else {
            shakeOTP()
        }
    }

    @objc private func resendCode() {
        otpFields.forEach { $0.text = "" }
        otpFields.first?.becomeFirstResponder()
        print("Resending code to \(email)")
    }

    @objc private func goToLogin() {
        navigationController?.popToRootViewController(animated: true)
    }

    private func shakeOTP() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, 0]
        otpStack.layer.add(animation, forKey: "shake")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoBox.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            logoBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoBox.widthAnchor.constraint(equalToConstant: 90),
            logoBox.heightAnchor.constraint(equalToConstant: 90),

            logoLabel.centerXAnchor.constraint(equalTo: logoBox.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoBox.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: logoBox.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            otpStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 36),
            otpStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            otpStack.heightAnchor.constraint(equalToConstant: 58),
            otpStack.widthAnchor.constraint(equalToConstant: 260),

            confirmButton.topAnchor.constraint(equalTo: otpStack.bottomAnchor, constant: 36),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            confirmButton.heightAnchor.constraint(equalToConstant: 54),

            resendLabel.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 18),
            resendLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            loginLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            loginLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func addGradient() {
        let g = CAGradientLayer()
        g.colors = [UIColor.black.cgColor,
                    UIColor(red: 0.12, green: 0.04, blue: 0.01, alpha: 1).cgColor]
        g.frame = view.bounds
        view.layer.insertSublayer(g, at: 0)
    }
}
