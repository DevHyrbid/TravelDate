//
//  Untitled.swift
//  TravelDate
//
//  Created by Dev CodingZone on 01/04/26.
//

// MARK: - Colors
// MARK: - Colors
extension UIColor {
    static let appBg        = UIColor(hex: "#151718")
    static let appCard      = UIColor(hex: "#111211")
    static let appOrange    = UIColor(hex: "#FF6B00")
    static let appGrayText  = UIColor(hex: "#9E9E9E")
    static let appPlaceholder = UIColor(hex: "FFFFFF")
    static let appBorder    = UIColor(hex: "#2A2A2A")
 
    
    
}



import Foundation
import UIKit
import Kingfisher

struct LabeledTextField {
    let container: UIView
    let textField: UITextField
}
typealias CollectionDelegate = UICollectionViewDelegate & UICollectionViewDataSource & UICollectionViewDelegateFlowLayout


class BaseClassVc: UIViewController {
    
     lazy var imagePicker = ImagePickerManager(presentingVC: self)
    var request = User.new()
    private var lastOffset: CGFloat = 0
    private var isScrollingDown = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addGradient()
        
    }
    
    
    func applyGlassEffect(to button: UIButton) {
        
        // Background
        button.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        
        // Rounded
        button.layer.cornerRadius = button.frame.height / 2
        button.clipsToBounds = true
        
        // Border
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        
        // Blur
        let blur = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blur)
        
        blurView.frame = button.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isUserInteractionEnabled = false
        blurView.layer.cornerRadius = button.frame.height / 2
        blurView.clipsToBounds = true
        
        button.insertSubview(blurView, at: 0)
        
        // Shadow / Glow
        button.layer.shadowColor = UIColor.white.withAlphaComponent(0.08).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
    }
    
    func addGradient() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.cgColor,
            UIColor(red: 0.2, green: 0.1, blue: 0.1, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 1.5]
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyGlowGradient()
    }
    
    
    func formatDateRange(start: String, end: String) -> String {
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let startDate = isoFormatter.date(from: start),
              let endDate = isoFormatter.date(from: end) else {
            return ""
        }
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMMM"
        
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "d MMMM yyyy"
        
        let startStr = dayFormatter.string(from: startDate)
        let endStr = endFormatter.string(from: endDate)
        
        return "\(startStr) - \(endStr)"
    }
    

    func loadImage(_ img:UIImageView, url: URL) {
        img.kf.setImage(
            with: url,
            placeholder: UIImage(named: "User"), // optional
            options: [
                .transition(.fade(0.3)),
                .cacheOriginalImage
            ]
        )
    }
    
    
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
  

   

    func handleScroll(_ scrollView: UIScrollView) {

        let currentOffset = scrollView.contentOffset.y
        let delta = currentOffset - lastOffset

        // Ignore very small movements
        guard abs(delta) > 5 else { return }

        // Ignore top bounce
        if currentOffset <= 0 {
            tripsTabBarController?.showTabBar()
            lastOffset = currentOffset
            return
        }

        // Ignore bottom bounce
        let maxOffset = scrollView.contentSize.height - scrollView.frame.height
        if currentOffset >= maxOffset {
            lastOffset = currentOffset
            return
        }

        // Scroll DOWN → hide
        if delta > 0 && currentOffset > 50 {

            if !isScrollingDown {
                isScrollingDown = true

                UIView.animate(withDuration: 0.25) {
                    self.tripsTabBarController?.hideTabBar()
                }
            }

        }
        // Scroll UP → show
        else if delta < 0 {

            if isScrollingDown {
                isScrollingDown = false

                UIView.animate(withDuration: 0.25) {
                    self.tripsTabBarController?.showTabBar()
                }
            }
        }

        lastOffset = currentOffset
    }

    
     func makeFieldTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.setFont(.medium, size: 14)
        return label
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

          navigationController?.setNavigationBarHidden(true, animated: false)
      }

      override func viewWillDisappear(_ animated: Bool) {
          super.viewWillDisappear(animated)

          navigationController?.setNavigationBarHidden(true, animated: false)
      }
    func currentDate(_ format:String) ->String{
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: Date())
    }

    
    
    
    func dateFromString(_ format:String,date:Date) ->String{
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
   
    
    
    
    
    func showAlert(_ message: String) {
       
            let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        
    }
    
    func showAlertAction(_ message: String, onOk: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            onOk?()
        }))
        present(alert, animated: true)
    }
    
    func showMaterialConfirm(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        confirmColor: UIColor = .systemRed,
        cancelTitle: String = "Cancel",
        onConfirm: (() -> Void)? = nil
    ) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancel = UIAlertAction(title: cancelTitle, style: .cancel)

        let confirm = UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm?()
        }

        confirm.setValue(confirmColor, forKey: "titleTextColor")

        alert.addAction(cancel)
        alert.addAction(confirm)

        present(alert, animated: true)
    }
    
    
    
    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc func openSettings() {
        //        pushVC(SettingsVC.self, from: .Settings)
    }
    
    func openNotification() {
        //        pushVC(NotificationViewController.self, from: .Settings)
    }
    
    func hideNavigate(_ hide:Bool){
        self.navigationController?.navigationBar.isHidden = hide
    }
    
    
    func uploadImg(_ data: Data, completion: @escaping (String?) -> Void) {
//        
        request.uploadImage(data) { errMsg, errCode in
            DispatchQueue.main.async {
                if errCode == Constants.APIResponseCodes.statusCodeSuccessfull {
                    completion(errMsg)   // image name / URL
                } else {
                    print(errMsg)
                    completion(nil)
                }
            }
        }
    }
    
    
    
}

extension UICollectionView {
    
    func register<T: UICollectionViewCell>(_ cell: T.Type) {
        let identifier = String(describing: T.self)
        
        if Bundle.main.path(forResource: identifier, ofType: "nib") != nil {
            let nib = UINib(nibName: identifier, bundle: nil)
            register(nib, forCellWithReuseIdentifier: identifier)
        } else {
            register(T.self, forCellWithReuseIdentifier: identifier)
        }
    }
    
    func dequeue<T: UICollectionViewCell>(_ cell: T.Type,
                                          for indexPath: IndexPath) -> T {
        let identifier = String(describing: T.self)
        
        guard let cell = dequeueReusableCell(
            withReuseIdentifier: identifier,
            for: indexPath
        ) as? T else {
            fatalError("Failed to dequeue cell with identifier: \(identifier)")
        }
        
        return cell
    }
}






class PaddingLabel: UILabel {
    var insets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}

import UIKit


// MARK: - LOCATIRON -----____-----
import Foundation
import CoreLocation

final class LocationHelper: NSObject {
    
    static let shared = LocationHelper()
    
    private let locationManager = CLLocationManager()
    private(set) var currentLocation: CLLocation?
    
    private override init() {
        super.init()
        configureLocationManager()
    }
    
    // MARK: - Setup
    
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Public APIs
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func getDistanceText(
        to latitude: Double,
        longitude: Double
    ) -> String {
        
        guard let currentLocation = currentLocation else {
            return "-- km"
        }
        
        let targetLocation = CLLocation(
            latitude: latitude,
            longitude: longitude
        )
        
        let meters = currentLocation.distance(from: targetLocation)
        
        if meters < 500 {
            return "Nearby"
        } else if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
    
    func getDistanceInMeters(
        to latitude: Double,
        longitude: Double
    ) -> Double? {
        
        guard let currentLocation = currentLocation else { return nil }
        
        let targetLocation = CLLocation(
            latitude: latitude,
            longitude: longitude
        )
        
        return currentLocation.distance(from: targetLocation)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationHelper: CLLocationManagerDelegate {
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        currentLocation = locations.last
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Location error: \(error.localizedDescription)")
    }
}




import UIKit

extension UIFont {

    enum AppFont: String {
        case bold = "Poppins-Bold"
        case extraBold = "Poppins-ExtraBold"
        case light = "Poppins-Light"
        case extraLight = "Poppins-ExtraLight"
        case medium = "Poppins-Medium"
        case regular = "Poppins-Regular"
        case semiBold = "Poppins-SemiBold"
        case thin = "Poppins-Thin"
    }

    static func appFont(_ font: AppFont, size: CGFloat) -> UIFont {
        return UIFont(name: font.rawValue, size: size)
            ?? UIFont.systemFont(ofSize: size)
    }
}

    extension UILabel {
        func setFont(_ font: UIFont.AppFont, size: CGFloat) {
            self.font = UIFont.appFont(font, size: size)
        }
    }
    extension UIButton {
        func setFont(_ font: UIFont.AppFont, size: CGFloat) {
            self.titleLabel?.font = UIFont.appFont(font, size: size)
        }
    }
    extension UITextField {
        func setFont(_ font: UIFont.AppFont, size: CGFloat) {
            self.font = UIFont.appFont(font, size: size)
        }
    }
    extension UITextView {
        func setFont(_ font: UIFont.AppFont, size: CGFloat) {
            self.font = UIFont.appFont(font, size: size)
        }
    }
// MARK: - REUSABLE COMPONENTS

class SectionLabel: UILabel {
    init(_ text: String) {
        super.init(frame: .zero)
        self.text = text
        self.textColor = .white
        self.setFont(.medium, size: 14)
        translatesAutoresizingMaskIntoConstraints = false
    }
    required init?(coder: NSCoder) { fatalError() }
}

class InputField: UIView {
    let tf = UITextField()
    init(_ placeholder: String) {
        super.init(frame: .zero)
        backgroundColor = Theme.card
        layer.cornerRadius = 16

        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
        )
        tf.textColor = .white
        tf.font = UIFont.appFont(.regular, size: 14)
        tf.translatesAutoresizingMaskIntoConstraints = false

        addSubview(tf)
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tf.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tf.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tf.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

class StyleButton: UIView {
    var isSelectedStyle = false { didSet { updateUI() } }

    private let title = UILabel()
    private let radio = UIView()
    private let dot = UIView()

    init(_ text: String) {
        super.init(frame: .zero)
        backgroundColor = Theme.card
        layer.cornerRadius = 16
        heightAnchor.constraint(equalToConstant: 50).isActive = true

        title.text = text
        title.textColor = UIColor.white.withAlphaComponent(0.8)
        title.setFont(.regular, size: 14)

        radio.layer.cornerRadius = 10
        radio.layer.borderWidth = 1.5
        radio.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor

        dot.backgroundColor = Theme.orange
        dot.layer.cornerRadius = 5
        dot.isHidden = true

        [title, radio].forEach { addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        radio.addSubview(dot)
        dot.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),

            radio.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            radio.centerYAnchor.constraint(equalTo: centerYAnchor),
            radio.widthAnchor.constraint(equalToConstant: 20),
            radio.heightAnchor.constraint(equalToConstant: 20),

            dot.centerXAnchor.constraint(equalTo: radio.centerXAnchor),
            dot.centerYAnchor.constraint(equalTo: radio.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    private func updateUI() {
        if isSelectedStyle {
            backgroundColor = Theme.orange.withAlphaComponent(0.15)
            layer.borderWidth = 1
            layer.borderColor = Theme.orange.cgColor
            dot.isHidden = false
            title.textColor = .white
        } else {
            backgroundColor = Theme.card
            layer.borderWidth = 0
            dot.isHidden = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}

import UIKit

class Loader {

    static let shared = Loader()
    private var loaderView: UIView?

    func show() {
        guard let window = UIApplication.shared.windows.first else { return }

        let bgView = UIView(frame: window.bounds)
        bgView.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.center = bgView.center
        indicator.startAnimating()
        indicator.color = .white

        bgView.addSubview(indicator)
        window.addSubview(bgView)

        loaderView = bgView
    }

    func hide() {
        loaderView?.removeFromSuperview()
        loaderView = nil
    }
}

import UIKit

class Toast {

    static func show(message: String, view: UIView) {
        
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.numberOfLines = 0
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true

        let padding: CGFloat = 16
        let maxWidth = view.frame.size.width - 40

        let size = toastLabel.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        toastLabel.frame = CGRect(
            x: (view.frame.size.width - size.width - padding) / 2,
            y: view.frame.size.height - 120,
            width: size.width + padding,
            height: size.height + 10
        )

        view.addSubview(toastLabel)

        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}


import UIKit

extension UIView {
    
    func applyGlowGradient() {
        // Remove old gradients
        layer.sublayers?.removeAll(where: { $0.name == "glowGradient" })
        
        // Base color
        backgroundColor = UIColor(hex: "#111211")
        
        let gradient = CAGradientLayer()
        gradient.name = "glowGradient"
        gradient.frame = bounds
        
        gradient.colors = [
            UIColor(hex: "#F76606").withAlphaComponent(0.6).cgColor,
            UIColor(hex: "#FE294D").withAlphaComponent(0.5).cgColor,
            UIColor.clear.cgColor
        ]
        
        // This creates "glow from bottom"
        gradient.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        gradient.locations = [0.0, 0.4, 1.0]
        
        // Add blur effect feel
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.5, y: 1.2) // slightly below screen
        gradient.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        layer.insertSublayer(gradient, at: 0)
    }
}
