//
//  OTPViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone on 19/07/26.
//
import UIKit

class OTPBottomSheetVC: UIViewController {

    var onVerified: (() -> Void)?

    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let otpField = UITextField()
    private let verifyButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupUI()
    }

    private func setupUI() {

        titleLabel.text = "Verify OTP"
        titleLabel.font = .boldSystemFont(ofSize: 24)

        subTitleLabel.text = "Enter the 6 digit OTP"
        subTitleLabel.font = .systemFont(ofSize: 15)
        subTitleLabel.textColor = .gray

        otpField.placeholder = "123456"
        otpField.textAlignment = .center
        otpField.keyboardType = .numberPad
        otpField.font = .boldSystemFont(ofSize: 28)
        otpField.layer.cornerRadius = 12
        otpField.layer.borderWidth = 1
        otpField.layer.borderColor = UIColor.systemGray4.cgColor

        verifyButton.setTitle("Verify", for: .normal)
        verifyButton.backgroundColor = .black
        verifyButton.tintColor = .white
        verifyButton.layer.cornerRadius = 12
        verifyButton.addTarget(self,
                               action: #selector(verifyOTP),
                               for: .touchUpInside)

        [titleLabel,
         subTitleLabel,
         otpField,
         verifyButton].forEach {

            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            otpField.topAnchor.constraint(equalTo: subTitleLabel.bottomAnchor, constant: 30),
            otpField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            otpField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            otpField.heightAnchor.constraint(equalToConstant: 55),

            verifyButton.topAnchor.constraint(equalTo: otpField.bottomAnchor, constant: 30),
            verifyButton.leadingAnchor.constraint(equalTo: otpField.leadingAnchor),
            verifyButton.trailingAnchor.constraint(equalTo: otpField.trailingAnchor),
            verifyButton.heightAnchor.constraint(equalToConstant: 52)

        ])
    }

    @objc
    private func verifyOTP() {

        guard let otp = otpField.text,
              otp.count == 6 else {
            return
        }

        FirebaseManager.shared.verifyOTP(code: otp) { success, message in

            DispatchQueue.main.async {

                if success {

                    self.dismiss(animated: true)

                    self.onVerified?()

                } else {

                    let alert = UIAlertController(title: nil,
                                                  message: message,
                                                  preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "OK",
                                                  style: .default))

                    self.present(alert, animated: true)
                }
            }
        }
    }
}
