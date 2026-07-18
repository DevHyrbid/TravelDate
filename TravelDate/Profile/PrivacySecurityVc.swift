//
//  PrivacySecurityVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 19/04/26.
//

import UIKit

class PrivacySecurityVc: BaseClassVc {
    @IBOutlet weak var vwSwitchProfile: UIView!
    @IBOutlet weak var vwSwitchLastSeen: UIView!
    @IBOutlet weak var vwLocation: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVw(vwLocation, tag: 0)
        setupVw(vwSwitchProfile, tag: 1)
        setupVw(vwSwitchLastSeen, tag: 2)
    }
    
    func setupVw(_ vw: UIView, tag: Int) {
        let customSwitch = CustomSwitch(frame: CGRect(x: 0, y: 0, width: 56, height: 32))
        
        customSwitch.tag = tag
        customSwitch.isOn = true
        customSwitch.onColor = UIColor(hex: "#FF6B00")
        customSwitch.offColor = UIColor(hex: "#2A2A2A")
        customSwitch.thumbColor = .black
        
        customSwitch.addTarget(self,
                               action: #selector(switchChanged(_:)),
                               for: .valueChanged)
        
        vw.addSubview(customSwitch)
        
        /* Optional: center the switch
        customSwitch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customSwitch.centerXAnchor.constraint(equalTo: vw.centerXAnchor),
            customSwitch.centerYAnchor.constraint(equalTo: vw.centerYAnchor),
            customSwitch.widthAnchor.constraint(equalToConstant: 56),
            customSwitch.heightAnchor.constraint(equalToConstant: 32)
        ])
        */
    }
    
    @objc func switchChanged(_ sender: CustomSwitch) {
        switch sender.tag {
        case 0:
            print("Location:", sender.isOn)
        case 1:
            print("Profile:", sender.isOn)
        case 2:
            print("Last Seen:", sender.isOn)
        default:
            break
        }
    }
}

extension PrivacySecurityVc {
    @IBAction func btnBack(_ sender:UIButton){
        super.backTapped()
    }
    
    @IBAction func btnGetVerfued(_ sender:UIButton) {
        let vc = GetVerifiedVc()
        navigationController?.pushViewController(vc, animated: true)
    }
}
