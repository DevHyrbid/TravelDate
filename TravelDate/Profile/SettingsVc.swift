//
//  SettingsVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 16/04/26.
//

import UIKit

class SettingsVc: BaseClassVc {
    
    @IBOutlet weak var blurVw: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.blurVw.isHidden  = true
    }
}

extension SettingsVc {
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
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
            self.pushVC(LoginViewController.self, from: .Main)
            break
        case 102:
            self.blurVw.isHidden = true
//            SessionManager.shared.clearSession()
//            self.pushVC(LoginViewController.self, from: .Home)
            break
        default:
            break 
        }
    }
    
    
}
