//
//  HomeViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone
//

import UIKit

// MARK: - Past Trip Model
import SwiftUI
struct PastTrip {
    let image: String
    let destination: String
    let dateRange: String
    let year: String
}

// MARK: - HomeViewController

class HomeViewController: BaseClassVc, UIScrollViewDelegate {

    @IBOutlet weak var scrollVw:UIScrollView!
    
    

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)

        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
           handleScroll(scrollView)
       }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tripsTabBarController?.showTabBar()
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
    }

    @objc private func createGroupTapped() {
        print(":tag105")
        
        self.pushVC(WelcomeViewController.self, from: .Home,hideTabBar: true)
    }
}



extension HomeViewController {
    
    @IBAction func btnActions(_ sender:UIButton) {
        switch sender.tag {
        case 101:
        
            self.pushVC(NewMatchVc.self, from: .Home,hideTabBar: true)
            break
        case 102:
            self.pushVC(ChatVc.self, from: .Home,hideTabBar: true)
            break
        case 103:
            break
            
        case 105:
            self.createGroupTapped()
            break
        default:
            break
        }
    }
    
    @IBAction func btnOpenGroup(_ sender:UIButton) {
        
        self.pushVC(MyGroupViewController.self, from: .Home,hideTabBar: true)
        
    }
    
    
    @IBAction func btnNotification(_ sender:UIButton) {
        self.pushVC(NotificationVc.self, from: .Home,hideTabBar: true)
    }
    
}
