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
    @IBOutlet weak var lblName:UILabel!
    @IBOutlet weak var lblGreating:UILabel!
    @IBOutlet weak var lblDay:UILabel!
    @IBOutlet weak var lblMin:UILabel!
    @IBOutlet weak var lblSec:UILabel!
    @IBOutlet weak var lblHours:UILabel!
    @IBOutlet weak var lblDate:UILabel!
    @IBOutlet weak var lblLocation:UILabel!
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var imgTrips:UIImageView!
    @IBOutlet weak var imgProfile:UIImageView!
    
    @IBOutlet weak var height:NSLayoutConstraint!
    @IBOutlet weak var hideVw:UIView!
    @IBOutlet weak var lblLeft:UILabel!
    
    @IBOutlet weak var vwMembers:UIView!
    
    @IBOutlet weak var btnList:UIButton!
    
    var timer: Timer?
    var targetDate: Date?
    var data: GroupsData? = nil
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
        
        
    }
    
    
    
    func makeTripMenu(trips: [Group]) -> UIMenu {
        let actions = trips.map { trip in
            UIAction(
                title: trip.groupTitle ?? "",
                image: UIImage(systemName:"arrow.right")
            ) { _ in
                self.didSelectTrip(trip)
            }
        }

        return UIMenu(title: "Past Trips", children: actions)
    }
    
    
    func didSelectTrip(_ res: Group) {
        

        // update your card data
//        updateUI(with: trip)
        
        
        
        self.setupCountdown(startDateString: res.startDate ?? "")
        
        self.lblDate.text = self.formatDateRange(
            start: res.startDate ?? "",
            end: res.endDate ?? ""
        )
        self.lblLocation.text = res.destination ?? ""
        self.lblTitle.text = res.groupTitle ?? ""
        if let url = URL(string: res.coverImage ?? "") {
            self.loadImage(self.imgTrips, url: url)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        lblName.text = User.curentUser?.name ?? ""
        if let url = URL(string: User.curentUser?.profile_image ?? "") {
            loadImage(imgProfile, url: url)
        }
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        
        tripsTabBarController?.showTabBar()
        setupUi()
    }
   
    
    func setupUi(){
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)
        lblGreating.text = getGreeting()
        lblName.setFont(.bold, size: 21.0)
        lblGreating.setFont(.regular, size: 18.0)
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
        imgProfile.contentMode = .scaleToFill
        getGroups()
    }
    
    func setupCountdown(startDateString: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: startDateString) {
            self.targetDate = date
            startTimer()
        }
    }
    
    
    func startTimer() {
        timer?.invalidate() // avoid multiple timers

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdown()
        }
    }
    
    func updateCountdown() {
        guard let targetDate = targetDate else { return }

        let now = Date()

        if targetDate <= now {
            timer?.invalidate()
            
            lblDay.text = "0"
            lblHours.text = "0"
            lblMin.text = "0"
            lblSec.text = "0"
            return
        }

        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: now, to: targetDate)

        lblDay.text = String(format: "%02d", components.day ?? 0)
        lblHours.text = String(format: "%02d", components.hour ?? 0)
        lblMin.text = String(format: "%02d", components.minute ?? 0)
        lblSec.text = String(format: "%02d", components.second ?? 0)
    }
    
    
    func getGroups() {
        request.getGroups { model,msg, code in
            if code == 200 {
                DispatchQueue.main.async { [self] in
                    if let res = model?.data?.groups?.first {
                        self.btnList.menu = makeTripMenu(trips: (model?.data?.groups!)!)
                        self.btnList.showsMenuAsPrimaryAction = true
                        self.data = model?.data ?? nil
                        self.setupCountdown(startDateString: res.startDate ?? "")
                        
                        self.lblDate.text = self.formatDateRange(
                            start: res.startDate ?? "",
                            end: res.endDate ?? ""
                        )
                        self.lblLocation.text = res.destination ?? ""
                        self.lblTitle.text = res.groupTitle ?? ""
                        if let url = URL(string: res.coverImage ?? "") {
                            self.loadImage(self.imgTrips, url: url)
                        }
                        self.hideVw.isHidden = true
                        self.height.constant = 670
                        self.btnList.isHidden = false
                    } else {
                        self.btnList.isHidden = true
                        self.hideVw.isHidden = false
                        self.height.constant = 100
                    }
                    
                }
            } else {
                
                DispatchQueue.main.async {
                    self.btnList.isHidden = true
                    self.showAlert(msg)
                }
                
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }
    
    
    @objc private func createGroupTapped() {
        print(":tag105")
        
        self.pushVC(WelcomeViewController.self, from: .Home,hideTabBar: true)
    }
    
    deinit {
        timer?.invalidate()
    }
}



extension HomeViewController {
    
    @IBAction func btnActions(_ sender:UIButton) {
        print(sender.tag , "CLODIDID")
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
        
        self.pushVC(MyGroupViewController.self, from: .Home,hideTabBar: true) { vc in
            vc.data = self.data
            
            
        }
        
    }
    
    
    @IBAction func btnNotification(_ sender:UIButton) {
        self.pushVC(NotificationVc.self, from: .Home,hideTabBar: true)
    }
    
    
    @IBAction func btnCreateGroup(_ sender:UIButton) {
        self.pushVC(WelcomeViewController.self, from: .Home,hideTabBar: true)
    }
    
   
}
