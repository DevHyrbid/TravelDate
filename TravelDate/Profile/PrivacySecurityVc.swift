//
//  PrivacySecurityVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 19/04/26.
//

import UIKit

class PrivacySecurityVc: BaseClassVc {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnBack(_ sender:UIButton){
        super.backTapped()
    }
    
    @IBAction func btnGetVerfued(_ sender:UIButton) {
        let vc = GetVerifiedVc()
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
