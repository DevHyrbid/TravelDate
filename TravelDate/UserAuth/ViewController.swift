//
//  ViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone on 31/03/26.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        openSignUp()
//         Do any additional setup after loading the view.
//        for family in UIFont.familyNames {
//            print("Family: \(family)")
//            for name in UIFont.fontNames(forFamilyName: family) {
//                print("   \(name)")
//            }
//        }
        loadFont(name: "Inter-Bold", ext: "ttf")

//        titleLabel.font = UIFont(name: "Inter-Bold", size: 30)
    }
    
    func openSignUp() {
        pushVC(OnboardingViewController.self, from: .Main)
    }
    
    

    

   

}
import CoreText

extension UIViewController {
    func loadFont(name: String, ext: String) {
        guard let fontURL = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}
