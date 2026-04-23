//
//  ProfileViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone on 14/04/26.
//

import UIKit

class ProfileViewController: BaseClassVc {
    
    @IBOutlet weak var txtAbout: UITextView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getProfile()
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func getProfile() {
        
        guard let token = UserDefaults.standard.string(forKey: "user_token") else {
            Toast.show(message: "User not logged in", view: self.view)
            return
        }

        Loader.shared.show()

        let headers = [
            "Authorization": "Bearer \(token)"
        ]

        
    }
    
    func bindProfile(user: [String: Any]) {

        let name = user["name"] as? String ?? ""
        let email = user["email"] as? String ?? ""
        let image = user["profile_image"] as? String ?? ""

        lblUserName.text = name
        lblName.text = email
        txtAbout.text = "Active user" // optional static or from API

        if let url = URL(string: image) {
            loadImage(from: url)
        }
    }
    
    func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.imgProfile.image = UIImage(data: data)
            }
        }.resume()
    }
}

extension ProfileViewController {
    @IBAction func btnSettings(_ sender:UIButton){
        self.pushVC(SettingsVc.self, from: .Settings, hideTabBar: true)
    }
    
    @IBAction func btnEditABout(_ sender:UIButton){
        if sender.tag == 101 {
            self.pushVC(EditProfileVc.self, from: .Settings)
        } else if sender.tag == 102 {
            if txtAbout.isUserInteractionEnabled {
                txtAbout.isUserInteractionEnabled  = false
            } else {
                txtAbout.isUserInteractionEnabled  = true
            }
        }
       
    }
    
    @IBAction func btnAddStyles(_ sender:UIButton){
        
    }
}
