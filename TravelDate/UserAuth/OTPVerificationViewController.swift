import UIKit

class OTPVerificationViewController: UIViewController {

    var inputFields: [UITextField] = []
    var resendButton: UIButton!
    var timerLabel: UILabel!
    var timer: Timer?
    var secondsRemaining: Int = 30

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startResendTimer()
    }

    private func setupUI() {
        view.backgroundColor = .white
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 10

        for _ in 0..<4 {
            let textField = UITextField()
            textField.borderStyle = .roundedRect
            textField.textAlignment = .center
            textField.keyboardType = .numberPad
            textField.delegate = self
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            inputFields.append(textField)
            stackView.addArrangedSubview(textField)
        }

        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmOTP), for: .touchUpInside)

        resendButton = UIButton(type: .system)
        resendButton.setTitle("Resend Code", for: .normal)
        resendButton.addTarget(self, action: #selector(resendCode), for: .touchUpInside)

        timerLabel = UILabel()
        timerLabel.text = "Resend in \(secondsRemaining) seconds"

        let stackViewContainer = UIStackView(arrangedSubviews: [stackView, confirmButton, timerLabel, resendButton])
        stackViewContainer.axis = .vertical
        stackViewContainer.spacing = 20
        stackViewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackViewContainer)

        NSLayoutConstraint.activate([
            stackViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackViewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let index = inputFields.firstIndex(of: textField) {
            if let text = textField.text, text.count > 1 {
                textField.text = String(text.last!)
                if index < inputFields.count - 1 {
                    inputFields[index + 1].becomeFirstResponder()
                }
            } else if textField.text?.count == 0, index > 0 {
                inputFields[index - 1].becomeFirstResponder()
            }
        }
    }

    @objc private func confirmOTP() {
        let otp = inputFields.map { $0.text ?? "" }.joined()
        if otp.count < 4 {
            showError("Please enter a valid 4-digit OTP.")
            return
        }
        // Handle OTP verification logic here
        print("OTP Entered: \(otp)")
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc private func resendCode() {
        // Implement resend code logic
        secondsRemaining = 30
        startResendTimer()
        print("Resend code clicked")
    }

    private func startResendTimer() {
        timerLabel.isHidden = false
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }

    @objc private func updateTimer() {
        if secondsRemaining > 0 {
            timerLabel.text = "Resend in \(secondsRemaining) seconds"
            secondsRemaining -= 1
        } else {
            timer?.invalidate()
            timerLabel.isHidden = true
            resendButton.isEnabled = true
        }
    }
}

extension OTPVerificationViewController: UITextFieldDelegate {}
