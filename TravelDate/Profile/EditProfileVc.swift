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
    @IBOutlet weak var txtLocation:UITextField!
    @IBOutlet weak var txtDob:UITextField!
    @IBOutlet weak var txtGender:UITextField!
    @IBOutlet weak var imgProfile:UIImageView!
    @IBOutlet weak var btnSave:UIButton!
    
    var locationView: LocationSearchView!
    
    // MARK: - Gender
    let genderArray = ["male", "female"]
    let genderPicker = UIPickerView()
    
    // MARK: - DOB
    let dobPicker = UIDatePicker()
    
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
        txtLocation.text = User.curentUser?.locationString ?? ""
        txtGender.text = User.curentUser?.gender ?? ""
        txtDob.text = User.curentUser?.dob ?? ""
        
        btnSave.setFont(.bold, size: 18.0)
        
        customSet(txtLocation)
        customSet(txtName)
        customSet(txtUserName)
        customSet(txtDob)
        customSet(txtGender)
        
        setuplocationVw()
        setupGenderPicker()
        setupDobPicker()
    }
    
    // MARK: - Location
    func setuplocationVw() {
        locationView = LocationSearchView()
        locationView.isHidden = true
        locationView.attach(to: txtLocation)
        
        locationView.onLocationSelected = { [weak self] address, coordinate in
            self?.txtLocation.text = address
            self?.locationView.isHidden = true
        }
    }
    
    // MARK: - Gender Picker
    func setupGenderPicker() {
        
        genderPicker.delegate = self
        genderPicker.dataSource = self
        
        txtGender.inputView = genderPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneBtn = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(doneGenderPicker)
        )
        
        toolbar.setItems([doneBtn], animated: true)
        txtGender.inputAccessoryView = toolbar
    }
    
    @objc func doneGenderPicker() {
        txtGender.resignFirstResponder()
    }
    
    // MARK: - DOB Picker
    func setupDobPicker() {
        
        dobPicker.datePickerMode = .date
        
        if #available(iOS 13.4, *) {
            dobPicker.preferredDatePickerStyle = .wheels
        }
        
        // Minimum age 13 years
        let calendar = Calendar.current
        let maxDate = calendar.date(byAdding: .year, value: -13, to: Date())
        
        dobPicker.maximumDate = maxDate
        
        txtDob.inputView = dobPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneBtn = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(doneDatePicker)
        )
        
        toolbar.setItems([doneBtn], animated: true)
        txtDob.inputAccessoryView = toolbar
    }
    
    @objc func doneDatePicker() {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        txtDob.text = formatter.string(from: dobPicker.date)
        txtDob.resignFirstResponder()
    }
    
    // MARK: - Common UI
    func customSet(_ txt:UITextField) {
        
        txt.leftView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: 35,
                height: txtName.frame.height
            )
        )
        
        txt.leftViewMode = .always
        txt.setFont(.regular, size: 14)
        txt.layer.cornerRadius = 15
        txt.clipsToBounds = true
    }
    
    // MARK: - Save API
    func saveAPi() {
        
        request.name = txtName.text ?? ""
        request.userName = txtUserName.text ?? ""
        if let location = txtLocation.text,
           !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.locationString = location
        }

        if let gender = txtGender.text,
           !gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.gender = gender
        }

        if let dob = txtDob.text,
           !dob.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.dob = dob
        }
        
        request.editProfileAPi { msg, errCode in
            
            DispatchQueue.main.async {
                
                if errCode == 200 {
                    
                    
                    self.showAlert("Profile Updated Successfully")
                }
            }
        }
    }
}


// MARK: - UIPickerView Delegate/DataSource
extension EditProfileVc: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        numberOfRowsInComponent component: Int
    ) -> Int {
        return genderArray.count
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        return genderArray[row]
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        txtGender.text = genderArray[row]
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
