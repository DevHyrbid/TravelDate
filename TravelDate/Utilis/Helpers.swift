//
//  Untitled.swift
//  TravelDate
//
//  Created by Dev CodingZone on 01/04/26.
//
import UIKit




class DividerView: UIView {

    init(text: String) {
        super.init(frame: .zero)

        let leftLine = UIView()
        leftLine.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        leftLine.translatesAutoresizingMaskIntoConstraints = false

        let rightLine = UIView()
        rightLine.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        rightLine.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.textColor = UIColor.white.withAlphaComponent(0.65)
        label.font = .montserrat(12, weight: .medium)

        let hStack = UIStackView(arrangedSubviews: [leftLine, label, rightLine])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 10

        addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leftLine.heightAnchor.constraint(equalToConstant: 1),
            rightLine.heightAnchor.constraint(equalToConstant: 1),
            leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor),

            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

class SocialButton: UIButton {
    init(icon: String, title: String, isDark: Bool) {
        super.init(frame: .zero)

        setTitle("  \(title)", for: .normal)
        setImage(UIImage(systemName: icon), for: .normal)
        titleLabel?.font = .montserrat(15, weight: .medium)
        layer.cornerRadius = 10
        layer.borderWidth = 1

        if isDark {
            // Google
            backgroundColor = .clear
            setTitleColor(.white, for: .normal)
            layer.borderColor = UIColor.white.withAlphaComponent(0.32).cgColor
            tintColor = .white
        } else {
            // Apple
            backgroundColor = .white
            setTitleColor(.black, for: .normal)
            layer.borderColor = UIColor.clear.cgColor
            tintColor = .black
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}

import UIKit

enum MontserratWeight: String {
    case regular = "Montserrat-Regular"
    case medium = "Montserrat-Medium"
    case semiBold = "Montserrat-SemiBold"
    case bold = "Montserrat-Bold"
}

extension UIFont {

    /// Main method for getting Montserrat font
    static func montserrat(_ size: CGFloat,
                           weight: MontserratWeight = .regular) -> UIFont {

        return UIFont(name: weight.rawValue, size: size)
        ?? UIFont.systemFont(ofSize: size) // fallback (never crashes)
    }

    // MARK: - Frequently Used Styles

    static var loginTitle: UIFont {
        return .montserrat(24, weight: .semiBold)
    }

    static var loginSubtitle: UIFont {
        return .montserrat(14, weight: .regular)
    }

    static var fieldTitle: UIFont {
        return .montserrat(14, weight: .medium)
    }

    static var fieldPlaceholder: UIFont {
        return .montserrat(14, weight: .regular)
    }

    static var forgotPassword: UIFont {
        return .montserrat(14, weight: .medium)
    }

    static var loginButton: UIFont {
        return .montserrat(16, weight: .semiBold)
    }

    static var socialButton: UIFont {
        return .montserrat(15, weight: .medium)
    }

    static var signupText: UIFont {
        return .montserrat(14, weight: .semiBold)
    }

    static var signupNormalText: UIFont {
        return .montserrat(14, weight: .regular)
    }
}

extension UIViewController {
     func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

 func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
}

import UIKit

extension UIColor {
    static let brandRed = UIColor(red: 192/255, green: 1/255, blue: 1/255, alpha: 1)
}

extension UIStoryboard {
    
    func instantiateViewController<T: UIViewController>() -> T {
        let viewController = self.instantiateViewController(withIdentifier: T.className)
        guard let typedViewController = viewController as? T else {
            fatalError("Unable to cast view controller of type (\(type(of: viewController))) to (\(T.className))")
        }
        return typedViewController
    }
}


extension NSObject {
    static var className: String {
        return String(describing: self)
    }
}


enum AppStoryBoard : String {
    case Main
    case Settings
    case Home
    case UserDashboard
    case Provider
    var instance : UIStoryboard {
        UIStoryboard(name: rawValue, bundle: nil)
    }
}

import UIKit

class GenderButton: UIButton {
    
    private var iconView = UIImageView()
    private var titleLbl = UILabel()
    
    var isSelectedGender: Bool = false {
        didSet { updateUI() }
    }
    
    init(title: String, icon: String) {
        super.init(frame: .zero)
        setupUI(title: title, icon: icon)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(title: String, icon: String) {
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.darkGray.cgColor
        backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 14, weight: .medium)
        titleLbl.textColor = .white
        
        let stack = UIStackView(arrangedSubviews: [iconView, titleLbl])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillProportionally
        stack.spacing = 8
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        addTarget(self, action: #selector(toggleSelection), for: .touchUpInside)
    }
    
    @objc private func toggleSelection() {
        isSelectedGender.toggle()
    }
    
    private func updateUI() {
        if isSelectedGender {
            layer.borderColor = UIColor.systemYellow.cgColor
            backgroundColor = UIColor.systemYellow.withAlphaComponent(0.2)
            titleLbl.textColor = .systemYellow
            iconView.tintColor = .systemYellow
        } else {
            layer.borderColor = UIColor.darkGray.cgColor
            backgroundColor = UIColor(white: 0.15, alpha: 1)
            titleLbl.textColor = .white
            iconView.tintColor = .white
        }
    }
}






import UIKit

class LevelCard: UIButton {
    
    private let iconView = UIImageView()
    private let titleLbl = UILabel()
    private let subLbl = UILabel()
    
    var isLevelSelected: Bool = false {
        didSet { updateUI() }
    }
    
    init(title: String, subtitle: String, icon: String, color: UIColor) {
        super.init(frame: .zero)
        setupUI(title: title, subtitle: subtitle, icon: icon, color: color)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(title: String, subtitle: String, icon: String, color: UIColor) {
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.darkGray.cgColor
        backgroundColor = UIColor(white: 0.13, alpha: 1)
        
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit
        
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLbl.textColor = .white
        
        subLbl.text = subtitle
        subLbl.font = .systemFont(ofSize: 12)
        subLbl.textColor = .lightGray
        subLbl.numberOfLines = 2
        
        let vStack = UIStackView(arrangedSubviews: [titleLbl, subLbl])
        vStack.axis = .vertical
        vStack.spacing = 2
        
        let hStack = UIStackView(arrangedSubviews: [iconView, vStack, UIView()])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        
        addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        addTarget(self, action: #selector(selectCard), for: .touchUpInside)
    }
    
    @objc private func selectCard() {
        isLevelSelected.toggle()
    }
    
    private func updateUI() {
        if isLevelSelected {
            layer.borderColor = UIColor.systemYellow.cgColor
            backgroundColor = UIColor.systemYellow.withAlphaComponent(0.2)
        } else {
            layer.borderColor = UIColor.darkGray.cgColor
            backgroundColor = UIColor(white: 0.13, alpha: 1)
        }
    }
}


import UIKit

extension UIFont {
    
    static func montserrat(_ type: Montserrat, size: CGFloat) -> UIFont {
        return UIFont(name: type.rawValue, size: size) ?? .systemFont(ofSize: size)
    }
    
    enum Montserrat: String {
        case regular = "Montserrat-Regular"
        case medium = "Montserrat-Medium"
        case semibold = "Montserrat-SemiBold"
        case bold = "Montserrat-Bold"
    }
}

@IBDesignable
open class DesignableView:UIView {
    @IBInspectable
    var clips : Bool{
        get {
             return clipsToBounds
        }set{
            clipsToBounds = newValue
        }
    }
    
    @IBInspectable
    var cornerRadiusValue: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            
            layer.cornerRadius = newValue
            layer.masksToBounds = true

            
        }
    
    }
    
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
            layer.masksToBounds = false
            

        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
            layer.masksToBounds = false

        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
            layer.masksToBounds = false

        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
            layer.masksToBounds = false

        }
       
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
                layer.masksToBounds = false
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
}

enum AppFont {

    static func regular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter-Regular", size: size) ??
        UIFont.systemFont(ofSize: size)
    }

    static func medium(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter-Medium", size: size) ??
        UIFont.systemFont(ofSize: size, weight: .medium)
    }
    
    static func semibold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter-SemiBold", size: size) ??
        UIFont.systemFont(ofSize: size, weight: .medium)
    }
    
//

    static func bold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Inter-Bold", size: size) ??
        UIFont.systemFont(ofSize: size, weight: .bold)
    }
}


final class SkeletonView: UIView {

    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = UIColor(hex: "#1C1C1E")
        layer.cornerRadius = 12
        clipsToBounds = true

        gradient.colors = [
            UIColor(hex: "#2A2A2C").cgColor,
            UIColor(hex: "#3A3A3C").cgColor,
            UIColor(hex: "#2A2A2C").cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.locations  = [0, 0.5, 1]

        layer.addSublayer(gradient)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        startAnimating()
    }

    private func startAnimating() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue   = [1, 1.5, 2]
        animation.duration  = 1.2
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "skeleton")
    }

    func stop() {
        gradient.removeAllAnimations()
        removeFromSuperview()
    }
}


class Constants : NSObject {
    
    struct StreamKeys{
        static let youtube_key = "5pht-r040-chtz-q2qq-5myb"
        static let facebook_key = "122132673794916498-0-Ab30elO2Uw-dw5bWc5Adtk9U"
    }
    struct APIResponseCodes {
        static let statusCodeSuccessfull = 200
        static let statusCodeInternalServerError = 500
        static let statusCodeInternetNotAvailable = -1009
    }
    
    
    static let Settings = ["Account","Subscription","Support & FAQ","Legal","Terms & Condtions"]
    
    
    
    struct  Validation {
        static let internetAppearOffline = ""
        static let name = "Please enter your first name."
        static let lastname = "Please enter your last name."
        static let emailInvalid  = "Please enter a valid email."
        static let emailEmpty  = "Please enter your email."
        static let password  = "Please enter your password."
        static let cnfrmpassword  = "Please enter your confirm password."
        static let passwordMatch  = "Password and confirm password do not match."
        static let agreeTerms = "Please Confirm that you agree to terms and conditions."
    }
    
    struct  device_Config {
        static let deviceToken = UserDefaults.standard.value(forKey: "device_token") as? String ?? "IOS"
        static let deviceType = "ios"
    }
    struct  login_Type {
        static let google = "google"
        static let apple = "apple"
    }
    
    struct role_Type {
        static let provider = "provider"
        static let patient = "patient"
    }
    
    
    /*
     "January", "February", "March", "April", "May", "June",
     "July", "August", "September", "October", "November", "December"
     */
    
    
    struct Device_Config {
        static let device_token = UserDefaults.standard.value(forKey: "device_token") as? String ?? "APPToken"
        static let device_type = "IOS"
    }
    
}
extension String {
    func isValidEmail() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }

    func isNumeric() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z]", options: .caseInsensitive)

        return !(regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil)
    }

    func validateUrl () -> Bool {
        let urlRegEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: self)
    }
}


extension UIViewController {

    func pushVC<T: UIViewController>(
        _ vcType: T.Type,
        from storyboard: AppStoryBoard,
        animated: Bool = true,
        hideTabBar: Bool = false,
        configure: ((T) -> Void)? = nil
    ) {
        let vc = storyboard.instance.instantiateViewController(
            withIdentifier: String(describing: vcType)
        ) as! T

        configure?(vc)

        // 👉 Hide tab bar if needed
        if hideTabBar {
            if let tabBarVC = self.tripsTabBarController {
                tabBarVC.hideTabBar()
            }
        }

        navigationController?.pushViewController(vc, animated: animated)
    }

    

}



import UIKit
import Kingfisher

final class ImageLoader {

    static func setImageKing(
        _ imageView: UIImageView,
        urlString: String?,
        placeholder: UIImage? = nil,
        cornerRadius: CGFloat = 0,
        contentMode: UIView.ContentMode = .scaleAspectFill
    ) {

        imageView.kf.cancelDownloadTask()
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = cornerRadius

        guard
            let urlString = urlString,
            let url = URL(string: urlString)
        else {
            imageView.image = placeholder
            return
        }

        imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.25)),
                .cacheOriginalImage
            ]
        )
    }
}

import UIKit

@IBDesignable
open class DesignableImageView: UIImageView {

    // MARK: - Corner Radius
    @IBInspectable
    var cornerRadiusValue: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            clipsToBounds = true
        }
    }

    // MARK: - Border Width
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    // MARK: - Border Color
    @IBInspectable
    var borderColor: UIColor? {
        get {
            guard let cgColor = layer.borderColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    // MARK: - Shadow Radius
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
            clipsToBounds = false
        }
    }

    // MARK: - Shadow Opacity
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
            clipsToBounds = false
        }
    }

    // MARK: - Shadow Offset
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
            clipsToBounds = false
        }
    }

    // MARK: - Shadow Color
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            guard let cgColor = layer.shadowColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            layer.shadowColor = newValue?.cgColor
            clipsToBounds = false
        }
    }

    // MARK: - Content Mode (Preview-safe)
    @IBInspectable
    var scaleAspectFill: Bool {
        get {
            return contentMode == .scaleAspectFill
        }
        set {
            contentMode = newValue ? .scaleAspectFill : .scaleToFill
        }
    }
}


import UIKit

final class FGFieldView: UIView {

    enum RightAccessory {
        case none
        case image(UIImage)
        case button(UIImage, target: Any?, action: Selector)
    }

    let textField = UITextField()
     let leftIcon = UIImageView()
 let rightButton = UIButton(type: .system)
     let rightImage = UIImageView()

    init(leftSystemIcon: String,
         placeholder: String,
         isSecure: Bool = false,
         right: RightAccessory = .none) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 56).isActive = true

        backgroundColor = UIColor.white.withAlphaComponent(0.92)
        layer.cornerRadius = 14
        clipsToBounds = true

        leftIcon.translatesAutoresizingMaskIntoConstraints = false
        leftIcon.image = UIImage(systemName: leftSystemIcon)
        leftIcon.tintColor = UIColor(hex: "#D94C8A")
        leftIcon.contentMode = .scaleAspectFit
        addSubview(leftIcon)

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .next
        textField.textColor = UIColor(hex: "#2B2B2B")
        textField.rightViewMode = .never
        
        addSubview(textField)

        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.tintColor = UIColor(hex: "#D94C8A")
        rightButton.isHidden = true
        addSubview(rightButton)

        rightImage.translatesAutoresizingMaskIntoConstraints = false
        rightImage.tintColor = UIColor(hex: "#D94C8A")
        rightImage.contentMode = .scaleAspectFit
        rightImage.isHidden = true
        addSubview(rightImage)
        

        // Configure right accessory
        switch right {
        case .none:
            break
        case .image(let img):
            rightImage.isHidden = false
            rightImage.image = img
        case .button(let img, let target, let action):
            rightButton.isHidden = false
            rightButton.setImage(img, for: .normal)
            rightButton.addTarget(target, action: action, for: .touchUpInside)
        }
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leftIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            leftIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftIcon.widthAnchor.constraint(equalToConstant: 20),
            leftIcon.heightAnchor.constraint(equalToConstant: 20),

            rightButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            rightButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightButton.widthAnchor.constraint(equalToConstant: 34),
            rightButton.heightAnchor.constraint(equalToConstant: 34),

            rightImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightImage.widthAnchor.constraint(equalToConstant: 18),
            rightImage.heightAnchor.constraint(equalToConstant: 18),

                textField.leadingAnchor.constraint(equalTo: leftIcon.trailingAnchor, constant: 12),
                textField.trailingAnchor.constraint(equalTo: rightButton.leadingAnchor, constant: -10),
                textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        
            
        ])

        // if there is a right accessory, give textField space
        if !rightButton.isHidden {
            textField.trailingAnchor.constraint(equalTo: rightButton.leadingAnchor, constant: -8).isActive = true
        } else if !rightImage.isHidden {
            textField.trailingAnchor.constraint(equalTo: rightImage.leadingAnchor, constant: -10).isActive = true
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
import UIKit

enum Montserrat {
    static func regular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Regular", size: size)!
    }

    static func medium(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Medium", size: size)!
    }

    static func semiBold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-SemiBold", size: size)!
    }

    static func bold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Bold", size: size)!
    }

    static func extraBold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-ExtraBold", size: size)!
    }
}




 

 

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        r = (int >> 16) & 0xFF
        g = (int >> 8) & 0xFF
        b = int & 0xFF
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}


import UIKit

@IBDesignable
open class DesignableButton: UIButton {

    // MARK: - Corner Radius
    @IBInspectable
    var cornerRadiusValue: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            clipsToBounds = true
        }
    }

    // MARK: - Border Width
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    // MARK: - Border Color
    @IBInspectable
    var borderColor: UIColor? {
        get {
            guard let cgColor = layer.borderColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    // MARK: - Shadow Radius
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
            clipsToBounds = false
        }
    }

    // MARK: - Shadow Opacity
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
            clipsToBounds = false
        }
    }

    // MARK: - Shadow Offset
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
            clipsToBounds = false
        }
    }

    // MARK: - Shadow Color
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            guard let cgColor = layer.shadowColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            layer.shadowColor = newValue?.cgColor
            clipsToBounds = false
        }
    }

    // MARK: - Background Color (State Safe)
    @IBInspectable
    var normalBackgroundColor: UIColor? {
        didSet {
            setBackgroundColor(normalBackgroundColor, for: .normal)
        }
    }

    @IBInspectable
    var highlightedBackgroundColor: UIColor? {
        didSet {
            setBackgroundColor(highlightedBackgroundColor, for: .highlighted)
        }
    }

    // MARK: - Helpers
    private func setBackgroundColor(_ color: UIColor?, for state: UIControl.State) {
        guard let color = color else { return }
        setBackgroundImage(UIImage.fromColor(color), for: state)
    }
}

// MARK: - UIImage helper
extension UIImage {
    static func fromColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}

import UIKit

extension UITableView {

    func register<T: UITableViewCell>(_ cell: T.Type) {
        let identifier = String(describing: T.self)

        if Bundle.main.path(forResource: identifier, ofType: "nib") != nil {
            let nib = UINib(nibName: identifier, bundle: nil)
            register(nib, forCellReuseIdentifier: identifier)
        } else {
            register(T.self, forCellReuseIdentifier: identifier)
        }
    }

    func dequeue<T: UITableViewCell>(_ cell: T.Type,
                                    for indexPath: IndexPath) -> T {
        let identifier = String(describing: T.self)

        guard let cell = dequeueReusableCell(
            withIdentifier: identifier,
            for: indexPath
        ) as? T else {
            fatalError("Failed to dequeue cell with identifier: \(identifier)")
        }

        return cell
    }
}

final class GlassButton: UIButton {

    private let blurView = UIVisualEffectView()
    private let tintView = UIView()
    private let highlightLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        layer.cornerRadius = 18
        clipsToBounds = true
        
        // 1. Blur (back)
        blurView.effect = UIBlurEffect(style: .systemMaterialDark)
        blurView.isUserInteractionEnabled = false
        addSubview(blurView)
        
        // 2. Tint (above blur)
        tintView.backgroundColor = UIColor(
            red: 30/255,
            green: 30/255,
            blue: 35/255,
            alpha: 0.6
        )
        tintView.isUserInteractionEnabled = false
        addSubview(tintView)
        
        // 3. Gradient (above tint)
//        layer.addSublayer(gradientLayer)
        
        // 4. Highlight (top layer)
        layer.addSublayer(highlightLayer)
        
        // TEXT
        setTitleColor(.white, for: .normal)
        
        // 👇 CRITICAL LINE
        bringSubviewToFront(titleLabel!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        blurView.frame = bounds
        tintView.frame = bounds
//        gradientLayer.frame = bounds
        highlightLayer.frame = bounds
        
        // 👇 keep text always on top
        if let titleLabel = titleLabel {
            bringSubviewToFront(titleLabel)
        }
    }
    
    // MARK: - States
    
    func setSelectedStyle() {
        blurView.isHidden = true
        tintView.isHidden = true
        highlightLayer.isHidden = true
        
        backgroundColor = UIColor.themeOrange
        layer.borderColor = UIColor.clear.cgColor
        
        setTitleColor(.white, for: .normal)
    }

    func setUnselectedStyle() {
        blurView.isHidden = false
        tintView.isHidden = false
        highlightLayer.isHidden = false
        
        backgroundColor = .clear
        layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        
        setTitleColor(.white, for: .normal) // 👈 force pure white
    }
    
    
}


@IBDesignable
class DesignableLabel: UILabel {

    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable
    var borderColor: UIColor? {
        get {
            guard let cgColor = layer.borderColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
            layer.masksToBounds = false
        }
    }

    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
            layer.masksToBounds = false
        }
    }

}
