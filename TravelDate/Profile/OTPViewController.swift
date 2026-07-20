//
//  OTPBottomSheetVC.swift
//  TravelDate
//
//  Created by Dev CodingZone on 19/07/26.
//

import UIKit

final class OTPBottomSheetVC: UIViewController {

    // MARK: - Callbacks
    var onVerify: ((String) -> Void)?
    var onResend: (() -> Void)?

    // MARK: - Config
    private let otpLength = 6
    private let resendDuration = 60

    // MARK: - Colors
    private let bgColor        = UIColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1.0) // #17171A
    private let fieldBg        = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
    private let orange         = UIColor(red: 1.00, green: 0.42, blue: 0.21, alpha: 1.0) // accent orange
    private let subtitleGray   = UIColor(white: 0.65, alpha: 1.0)

    // MARK: - UI
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let otpStack = UIStackView()
    private var otpFields: [UITextField] = []

    private let timerLabel = UILabel()
    private let resendButton = UIButton(type: .system)

    private let verifyButton = UIButton(type: .system)

    // MARK: - State
    private var secondsRemaining = 0
    private var countdownTimer: Timer?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = bgColor

        setupUI()
        setupOTPFields()
        startTimer()
    }

    deinit {
        countdownTimer?.invalidate()
    }

    // MARK: - Setup UI
    private func setupUI() {

        // Title
        titleLabel.text = "Verify Phone Number"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        // Subtitle
        subTitleLabel.text = "Enter the 6-digit verification code sent to your phone number."
        subTitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subTitleLabel.textColor = subtitleGray
        subTitleLabel.textAlignment = .center
        subTitleLabel.numberOfLines = 0

        // OTP Stack
        otpStack.axis = .horizontal
        otpStack.alignment = .fill
        otpStack.distribution = .fillEqually
        otpStack.spacing = 10

        // Timer label
        timerLabel.font = .systemFont(ofSize: 14, weight: .medium)
        timerLabel.textColor = subtitleGray
        timerLabel.textAlignment = .center

        // Resend button
        resendButton.setTitle("Resend OTP", for: .normal)
        resendButton.setTitleColor(orange, for: .normal)
        resendButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        resendButton.isHidden = true
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)

        // Verify button
        verifyButton.setTitle("Verify", for: .normal)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        verifyButton.backgroundColor = orange.withAlphaComponent(0.35)
        verifyButton.layer.cornerRadius = 26
        verifyButton.isEnabled = false
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)

        [titleLabel, subTitleLabel, otpStack, timerLabel, resendButton, verifyButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            otpStack.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 28),
            otpStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            otpStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            otpStack.heightAnchor.constraint(equalToConstant: 55),

            timerLabel.topAnchor.constraint(equalTo: otpStack.bottomAnchor, constant: 20),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            resendButton.topAnchor.constraint(equalTo: otpStack.bottomAnchor, constant: 20),
            resendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            verifyButton.heightAnchor.constraint(equalToConstant: 52),
            verifyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - Setup OTP Fields
    private func setupOTPFields() {

        for index in 0..<otpLength {

            let field = UITextField()
            field.tag = index
            field.delegate = self
            field.textAlignment = .center
            field.font = .systemFont(ofSize: 22, weight: .bold)
            field.textColor = .white
            field.tintColor = orange
            field.backgroundColor = fieldBg
            field.keyboardType = .numberPad
            field.textContentType = .oneTimeCode
            field.layer.cornerRadius = 14
            field.layer.borderWidth = 1.5
            field.layer.borderColor = UIColor.clear.cgColor

            otpFields.append(field)
            otpStack.addArrangedSubview(field)
        }
    }

    // MARK: - Timer
    private func startTimer() {

        secondsRemaining = resendDuration
        timerLabel.isHidden = false
        resendButton.isHidden = true
        updateTimerLabel()

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateTimer),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func updateTimer() {

        secondsRemaining -= 1

        if secondsRemaining <= 0 {
            countdownTimer?.invalidate()
            timerLabel.isHidden = true
            resendButton.isHidden = false
            return
        }

        updateTimerLabel()
    }

    private func updateTimerLabel() {
        timerLabel.text = String(format: "Resend OTP in 00:%02d", secondsRemaining)
    }

    // MARK: - Helpers
    private func getOTP() -> String {
        return otpFields.map { $0.text ?? "" }.joined()
    }

    private func updateVerifyButtonState() {

        let isComplete = otpFields.allSatisfy { !($0.text ?? "").isEmpty }

        verifyButton.isEnabled = isComplete
        verifyButton.backgroundColor = isComplete ? orange : orange.withAlphaComponent(0.35)
    }

    private func setFieldBorder(_ field: UITextField, focused: Bool) {
        field.layer.borderColor = focused ? orange.cgColor : UIColor.clear.cgColor
    }

    private func clearFields() {
        otpFields.forEach { $0.text = "" }
        updateVerifyButtonState()
        otpFields.first?.becomeFirstResponder()
    }

    // MARK: - Actions
    @objc private func resendTapped() {
        clearFields()
        startTimer()
        onResend?()
    }

    @objc private func verifyTapped() {
        
        let code = getOTP()
        guard code.count == otpLength else { return }
        onVerify?(code)
    }
}

// MARK: - UITextFieldDelegate
extension OTPBottomSheetVC: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        setFieldBorder(textField, focused: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        setFieldBorder(textField, focused: false)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {

        // Handle backspace
        if string.isEmpty {

            textField.text = ""

            if textField.tag > 0 {
                let previous = otpFields[textField.tag - 1]
                previous.becomeFirstResponder()
                previous.text = ""
            }

            updateVerifyButtonState()
            return false
        }

        // Filter non-numeric input
        let digitsOnly = string.filter { $0.isNumber }
        if digitsOnly.isEmpty { return false }

        // Handle paste of full/multiple OTP digits
        if digitsOnly.count > 1 {
            distribute(digitsOnly, startingAt: textField.tag)
            return false
        }

        // Single digit entry
        textField.text = digitsOnly

        if textField.tag < otpLength - 1 {
            otpFields[textField.tag + 1].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        updateVerifyButtonState()
        return false
    }

    private func distribute(_ digits: String, startingAt startIndex: Int) {

        let chars = Array(digits)
        var fieldIndex = startIndex

        for char in chars {
            guard fieldIndex < otpLength else { break }
            otpFields[fieldIndex].text = String(char)
            fieldIndex += 1
        }

        updateVerifyButtonState()

        if fieldIndex < otpLength {
            otpFields[fieldIndex].becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
    }
}
