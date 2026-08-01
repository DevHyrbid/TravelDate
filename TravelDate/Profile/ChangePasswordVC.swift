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
        txtNew.setPlaceholder("Current password")
        txtOld.setPlaceholder("New password")
        txtNew.enablePasswordToggle()
        txtOld.enablePasswordToggle()
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
import UIKit

extension UITextField {

    func enablePasswordToggle() {
        isSecureTextEntry = true

        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .lightGray

        // Position button with trailing padding
        button.frame = CGRect(x: 10, y: 0, width: 20, height: 20)

        // Container width = button width + left/right padding
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        container.addSubview(button)

        rightView = container
        rightViewMode = .always

        button.addTarget(self,
                         action: #selector(togglePasswordVisibility(_:)),
                         for: .touchUpInside)
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        isSecureTextEntry.toggle()

        let imageName = isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)

        // Prevent cursor jump
        if let text = text {
            self.text = ""
            insertText(text)
        }
    }
}
