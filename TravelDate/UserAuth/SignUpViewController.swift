import UIKit


class SignUpViewController: UIViewController, UITextFieldDelegate {

    // MARK: - UI Elements

   
    private let nameLabel = makeLabel("Full Name")
    private let emailLabel = makeLabel("Email")
    private let passwordLabel = makeLabel("Password")

    private let nameField = AuthTextFieldView(
        placeholder: "John Doe",
        icon: UIImage(systemName: "person")
    )

    private let emailField = AuthTextFieldView(
        placeholder: "your@email.com",
        icon: UIImage(systemName: "envelope")
    )

    private let passwordField: AuthTextFieldView = {
        let field = AuthTextFieldView(
            placeholder: "Enter your password",
            icon: UIImage(systemName: "lock")
        )
        field.isPasswordField = true
        return field
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDelegates()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .black

        let scrollView = UIScrollView()
        let contentView = UIView()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [
//            titleLabel,

            nameLabel,
            nameField,

            emailLabel,
            emailField,

            passwordLabel,
            passwordField
        ])

        stack.axis = .vertical
        stack.spacing = 16

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 240),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // UX improvements
        emailField.textField.keyboardType = .emailAddress
        emailField.textField.autocapitalizationType = .none
        nameField.textField.autocapitalizationType = .words
    }

    private func setupDelegates() {
        nameField.textField.delegate = self
        emailField.textField.delegate = self
        passwordField.textField.delegate = self
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField.textField {
            emailField.textField.becomeFirstResponder()
        } else if textField == emailField.textField {
            passwordField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    // MARK: - Label Helper

    static func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont(name: "Inter-SemiBold", size: 14)
        return label
    }
    
    
    func makeButton(title: String,
                    bgColor: UIColor,
                    textColor: UIColor,
                    borderColor: UIColor = .clear) -> UIButton {

        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = UIFont(name: "Inter-SemiBold", size: 18)

        button.backgroundColor = bgColor
        button.layer.cornerRadius = 30
        button.layer.borderWidth = borderColor == .clear ? 0 : 1
        button.layer.borderColor = borderColor.cgColor

        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true

        return button
    }
}


// MARK: - Custom TextField View

class AuthTextFieldView: UIView {

    let textField = UITextField()
    private let iconView = UIImageView()
    private let eyeButton = UIButton(type: .system)

    var isPasswordField: Bool = false {
        didSet {
            setupPasswordToggle()
        }
    }

    init(placeholder: String, icon: UIImage?) {
        super.init(frame: .zero)
        setupUI(placeholder: placeholder, icon: icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(placeholder: String, icon: UIImage?) {

        backgroundColor = UIColor(white: 1, alpha: 0.05)
        layer.cornerRadius = 25
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 1, alpha: 0.08).cgColor

        iconView.image = icon
        iconView.tintColor = .lightGray
        iconView.contentMode = .scaleAspectFit

        textField.placeholder = placeholder
        textField.textColor = .white
        textField.tintColor = .white
        textField.font = UIFont(name: "Inter-Regular", size: 16)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.lightGray]
        )

        let stack = UIStackView(arrangedSubviews: [iconView, textField])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -50),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    private func setupPasswordToggle() {
        guard isPasswordField else { return }

        textField.isSecureTextEntry = true

        eyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
        eyeButton.tintColor = .lightGray

        eyeButton.addTarget(self, action: #selector(togglePassword), for: .touchUpInside)

        addSubview(eyeButton)
        eyeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            eyeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            eyeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            eyeButton.widthAnchor.constraint(equalToConstant: 24),
            eyeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    @objc private func togglePassword() {
        textField.isSecureTextEntry.toggle()
        let imageName = textField.isSecureTextEntry ? "eye" : "eye.slash"
        eyeButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}
