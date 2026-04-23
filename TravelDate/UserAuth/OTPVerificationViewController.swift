import UIKit

class OTPVc: UIViewController, UITextFieldDelegate {

    private var otpFields: [UITextField] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .black
        
        // LOGO
        let logo = UILabel()
        logo.text = "Trips"
        logo.textColor = .orange
        logo.font = .systemFont(ofSize: 28, weight: .semibold)
        logo.textAlignment = .center
        logo.layer.borderWidth = 1
        logo.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        logo.layer.cornerRadius = 12
        logo.clipsToBounds = true
        logo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logo)
        
        // TITLE
        let title = UILabel()
        title.text = "Verification"
        title.textColor = .white
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)
        
        // SUBTITLE
        let subtitle = UILabel()
        subtitle.text = "Enter 4 digit code"
        subtitle.textColor = .lightGray
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitle)
        
        // OTP STACK
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        // CREATE 4 FIELDS
        for i in 0..<4 {
            let tf = UITextField()
            tf.backgroundColor = UIColor(white: 0.15, alpha: 1)
            tf.textAlignment = .center
            tf.font = .systemFont(ofSize: 20, weight: .medium)
            tf.textColor = .white
            tf.layer.cornerRadius = 25
            tf.keyboardType = .numberPad
            tf.delegate = self
            tf.tag = i
            tf.addTarget(self, action: #selector(textChanged), for: .editingChanged)
            
            stack.addArrangedSubview(tf)
            otpFields.append(tf)
        }
        
        // CONFIRM BUTTON
        let btn = UIButton()
        btn.setTitle("Confirm", for: .normal)
        btn.backgroundColor = .orange
        btn.layer.cornerRadius = 25
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        view.addSubview(btn)
        
        // CONSTRAINTS
        NSLayoutConstraint.activate([
            logo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.widthAnchor.constraint(equalToConstant: 100),
            logo.heightAnchor.constraint(equalToConstant: 100),
            
            title.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 30),
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            subtitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stack.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 30),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.heightAnchor.constraint(equalToConstant: 50),
            stack.widthAnchor.constraint(equalToConstant: 240),
            
            btn.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 40),
            btn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            btn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - OTP Handling
    
    @objc private func textChanged(_ textField: UITextField) {
        if textField.text?.count == 1 {
            let next = textField.tag + 1
            if next < otpFields.count {
                otpFields[next].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // backspace support
        if string.isEmpty {
            textField.text = ""
            let prev = textField.tag - 1
            if prev >= 0 {
                otpFields[prev].becomeFirstResponder()
            }
            return false
        }
        return textField.text?.isEmpty ?? true
    }
    
    @objc private func confirmTapped() {
        let otp = otpFields.compactMap { $0.text }.joined()
        print("OTP:", otp)
    }
}
