//
//  EditProfileVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 23/04/26.
//

import UIKit

class EditProfileVc: BaseClassVc {
    
    @IBOutlet weak var txtUserName:UITextField!
    @IBOutlet weak var txtName:UITextField!
    @IBOutlet weak var imgProfile:UIImageView!
    @IBOutlet weak var btnSave:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
    }
    
    // MARK: -  Methods
    func setupUi() {
        
        if let url = URL(string: User.curentUser?.profile_image ?? "") {
            loadImage(imgProfile, url: url)
        }
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
        txtName.text = User.curentUser?.name ?? ""
        txtUserName.text = "\(User.curentUser?.userName ?? "")"
        btnSave.setFont(.bold, size: 18.0)
        customSet(txtName)
        customSet(txtUserName)
    }
    
    func customSet(_ txt:UITextField) {
        txt.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: txtName.frame.height))
        txt.leftViewMode = .always
        txt.setFont(.regular, size: 14)
        txt.layer.cornerRadius = 15
        txt.clipsToBounds = true
    }
    
    func saveAPi() {
        request.name = txtName.text ?? ""
        request.userName = txtUserName.text ?? ""
        request.editProfileAPi { msg, errCode in
            DispatchQueue.main.async {
                if errCode == 200 {
                    self.showAlert("Profile UpdatedSuccesfully")
                }
            }
           
        }
        
    }
    
    

}

extension EditProfileVc {
    @IBAction func btnEditImg(_ sender:UIButton){
        imagePicker.showImagePicker(allowCamera: true) { [weak self] img in
            guard let self = self else { return }

            print(img)

            self.imgProfile.image = img
            self.imgProfile.contentMode = .scaleAspectFill

            guard let data = img.jpegData(compressionQuality: 0.7) else { return }

            self.uploadImg(data) { [weak self] imageName in
                guard let self = self else { return }

                print(imageName, "UPLOAD SUCCESS")
                
                request.profile_image = imageName
            }
        }
    }
    
    
    
    @IBAction func btnSave(_ sender:UIButton){
        saveAPi()
    }
    
    @IBAction func btnBack(_ sender:UIButton){
        super.backTapped()
    }
    
    
}
