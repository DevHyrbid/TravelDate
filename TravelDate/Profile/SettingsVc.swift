//
//  SettingsVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 16/04/26.
//

import UIKit

class SettingsVc: BaseClassVc {
    
    @IBOutlet weak var blurVw: UIVisualEffectView!
    @IBOutlet weak var vwSwitch: UIView!
    @IBOutlet weak var vwChangePwd:UIView!
    @IBOutlet weak var vwChangeHeight:NSLayoutConstraint!
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
        
    }
    
    func setupUi(){
        
        if User.curentUser?.social_id ?? ""  != "" || User.curentUser?.social_id ?? "" != nil {
            self.vwChangePwd.isHidden = false
            self.vwChangeHeight.constant  = 90
        } else {
            self.vwChangePwd.isHidden = true
            self.vwChangeHeight.constant  = 0
        }
        self.blurVw.isHidden  = true
        let customSwitch = CustomSwitch(frame: CGRect(x: 0, y: 0, width: 56, height: 32))
        
        
        customSwitch.isOn = User.curentUser!.is_push_notification ?? true
        customSwitch.addTarget(self,
                               action: #selector(switchChanged(_:)),
                               for: .valueChanged)
        customSwitch.onColor = UIColor(hex: "#FF6B00")   // Orange
        customSwitch.offColor = UIColor(hex: "#2A2A2A")  // Dark Gray
        customSwitch.thumbColor = .black                 // Black Thumb
        vwSwitch.addSubview(customSwitch)
    }
    
    @objc func switchChanged(_ sender: CustomSwitch) {
        print(sender.isOn)
        request.is_push_notification  = sender.isOn
        request.editProfileAPi { errMsg, errCode in
            
        }
    }
}

extension SettingsVc {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    @IBAction func btnChangePassword(_ sender:UIButton) {
        self.pushVC(ChangePasswordVC.self, from: .Settings)
    }
    
    @IBAction func btnPrivacy(_ sender:UIButton) {
        self.pushVC(PrivacySecurityVc.self, from: .Settings)
    }
    
    @IBAction func btnLogout(_ sender:UIButton) {
        switch sender.tag {
        case 100:
            self.blurVw.isHidden = false
            break
        case 101:
            self.blurVw.isHidden = true
            self.request.logout { errMsg, errCode in
                DispatchQueue.main.async {
                    User.resetCurrentUser()
                    self.pushVC(LoginViewController.self, from: .Main)
                }
            }
            break
        case 102:
            self.blurVw.isHidden = true
            break
        default:
            break 
        }
    }
    
    
}

import UIKit

final class CustomSwitch: UIControl {

    private let trackView = UIView()
    private let thumbView = UIView()

    var isOn: Bool = false {
        didSet {
            animateSwitch()
            sendActions(for: .valueChanged)
        }
    }

    var onColor: UIColor = .systemOrange
    var offColor: UIColor = UIColor(white: 0.25, alpha: 1)
    var thumbColor: UIColor = .black

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {

        backgroundColor = .clear

        trackView.isUserInteractionEnabled = false
        trackView.backgroundColor = offColor
        addSubview(trackView)

        thumbView.isUserInteractionEnabled = false
        thumbView.backgroundColor = thumbColor
        thumbView.layer.shadowColor = UIColor.black.cgColor
        thumbView.layer.shadowOpacity = 0.2
        thumbView.layer.shadowRadius = 3
        thumbView.layer.shadowOffset = CGSize(width: 0, height: 1)
        addSubview(thumbView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggle))
        addGestureRecognizer(tap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        trackView.frame = bounds
        trackView.layer.cornerRadius = bounds.height / 2

        let size = bounds.height - 6
        let y = (bounds.height - size) / 2

        thumbView.frame = CGRect(x: 3, y: y, width: size, height: size)
        thumbView.layer.cornerRadius = size / 2

        animateSwitch(animated: false)
    }

    @objc private func toggle() {
        isOn.toggle()
    }

    private func animateSwitch(animated: Bool = true) {

        let size = bounds.height - 6
        let x = isOn ? bounds.width - size - 3 : 3

        let changes = {
            self.trackView.backgroundColor = self.isOn ? self.onColor : self.offColor
            self.thumbView.frame.origin.x = x
        }

        if animated {
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0,
                           options: [.curveEaseInOut]) {
                changes()
            }
        } else {
            changes()
        }
    }
}
