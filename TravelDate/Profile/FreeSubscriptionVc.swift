//  FreeSubscriptionVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 28/07/26.
//
import UIKit
class FreeSubscriptionVc: BaseClassVc {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension FreeSubscriptionVc {
    
    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    @IBAction func btnContinue(_ sender:UIButton) {
        self.pushVC(PreiumController.self, from: .Settings,hideTabBar: true)
    }
}
