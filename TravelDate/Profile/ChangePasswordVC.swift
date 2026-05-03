//
//  ChangePasswordVC.swift
//  TravelDate
//
//  Created by Dev CodingZone on 25/04/26.
//

import UIKit

class ChangePasswordVC: BaseClassVc {
    
    @IBOutlet weak var txtNew:UITextField!
    @IBOutlet weak var txtOld:UITextField!
    
    @IBOutlet weak var btnSave:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
    }
    
    // MARK: -  Methods
    func setupUi() {
        
        
        btnSave.setFont(.bold, size: 18.0)
        customSet(txtNew)
        customSet(txtOld)
    }
    
    func customSet(_ txt:UITextField) {
        txt.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: txt.frame.height))
        txt.leftViewMode = .always
        txt.setFont(.regular, size: 14)
        txt.layer.cornerRadius = 15
        txt.clipsToBounds = true
    }
    
    func changePassword() {
        
        request.current_password  = txtOld.text ?? ""
        request.new_password  = txtNew.text ?? ""
        request.changePwd { errMsg, errCode in
            if errCode == 200 {
                print("password Change")
            } else {
                self.showAlert(errMsg)
            }
        }
        
    }
    
    
    @IBAction func btnSave(_ sender:UIButton){
        changePassword()
    }
    
    @IBAction func btnBack(_ sender:UIButton){
        super.backTapped()
    }
    
    
}
