//
//  EditProfileVc.swift
//  TravelDate
//
//  Created by Dev CodingZone on 23/04/26.
//

import UIKit
import PhoneNumberKit


class EditProfileVc: BaseClassVc {
    
    @IBOutlet weak var txtUserName:UITextField!
    @IBOutlet weak var txtEmail:UITextField!
    @IBOutlet weak var txtName:UITextField!
    @IBOutlet weak var txtLocation:UITextField!
    @IBOutlet weak var txtDob:UITextField!
    @IBOutlet weak var txtGender:UITextField!
    @IBOutlet weak var txtPhone:UITextField!
    @IBOutlet weak var imgProfile:UIImageView!
    @IBOutlet weak var btnSave:UIButton!
    @IBOutlet weak var btnVerify:UIButton!
    
    var locationView: LocationSearchView!
    
    // MARK: - Phone / Country Picker
    var phoneField: PhoneNumberField!
    
    // MARK: - Gender
    let genderArray = ["male", "female"]
    let genderPicker = UIPickerView()
    
    // MARK: - DOB
    let dobPicker = UIDatePicker()
//    private let phoneNumberKit = PhoneNumberKit
    private let partialFormatter = PartialFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUi()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tripsTabBarController?.hideTabBar()
    }
    
    
    
    // MARK: -  Methods
    func setupUi() {
        
        if let url = URL(string: User.curentUser?.profile_image ?? "") {
            loadImage(imgProfile, url: url)
        }
        
        if User.curentUser?.phone_verify == true {
           
            self.btnVerify.setTitle("Verified", for: .normal)
            self.btnVerify.setTitleColor(.green, for: .normal)
            self.btnVerify.isEnabled = false
            self.txtPhone.isUserInteractionEnabled = false 
        }
        
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
        imgProfile.contentMode  = .scaleAspectFill
        txtName.text = User.curentUser?.name ?? ""
        txtUserName.text = "\(User.curentUser?.userName ?? "")"
        txtLocation.text = User.curentUser?.locationString ?? ""
        txtGender.text = User.curentUser?.gender ?? ""
        let dob = formatDOB(User.curentUser?.dob ?? "")
        print(dob) // 07/20/2026
        txtDob.text = dob
        txtEmail.text = User.curentUser?.email ?? ""
        
        btnSave.setFont(.bold, size: 18.0)
        btnVerify.setFont(.medium, size: 15.0)
        
        customSet(txtEmail)
        customSet(txtLocation)
        customSet(txtPhone)
        customSet(txtName)
        customSet(txtUserName)
        customSet(txtDob)
        customSet(txtGender)
        
        setuplocationVw()
        setupGenderPicker()
        setupDobPicker()
        setupPhoneField()
    }
    
    // MARK: - Location
    func setuplocationVw() {

        locationView = LocationSearchView()

        view.addSubview(locationView)

        locationView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            locationView.topAnchor.constraint(equalTo: txtLocation.bottomAnchor, constant: 8),
            locationView.leadingAnchor.constraint(equalTo: txtLocation.leadingAnchor),
            locationView.trailingAnchor.constraint(equalTo: txtLocation.trailingAnchor),
            locationView.heightAnchor.constraint(equalToConstant: 220)
        ])

        locationView.isHidden = true
        locationView.attach(to: txtLocation)

        locationView.onLocationSelected = { [weak self] address, coordinate in
            guard let self = self else { return }

            self.txtLocation.text = address
            self.locationView.isHidden = true

            self.request.latitude = coordinate.latitude
            self.request.longitude = coordinate.longitude
        }
    }
    
    func formatDOB(_ isoDate: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = inputFormatter.date(from: isoDate) else {
            return ""
        }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        outputFormatter.dateFormat = "yyyy-MM-dd"

        return outputFormatter.string(from: date)
    }
    
    // MARK: - Phone Country Picker
    // NOTE: call this AFTER customSet(txtPhone) — it overrides the
    // blank spacer leftView set by customSet with the tappable
    // flag + dial-code selector.
    func setupPhoneField() {
        
        phoneField = PhoneNumberField(textField: txtPhone, presentingVC: self)
        
        // Restore the user's saved country if we have an ISO code on file,
        // otherwise it defaults to India (+91).
        if let isoCode = User.curentUser?.countryIso, !isoCode.isEmpty {
            phoneField.setCountry(isoCode: isoCode)
        }
        
        
        // Pre-fill the digits only (dial code lives in the picker button).
        txtPhone.text = User.curentUser?.phone_number ?? ""
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
        let maxDate = calendar.date(byAdding: .year, value: -18, to: Date())
        
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
        request.countryIso = phoneField.countryISOCode    // 91
        request.phone_number = txtPhone.text ?? ""           // 9876543210
        
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
        
        
        print("Name:", txtName.text ?? "NIL")
        print("Username:", txtUserName.text ?? "NIL")
        print("Phone:", txtPhone.text ?? "NIL")
        print("Location:", txtLocation.text ?? "NIL")
        print("Gender:", txtGender.text ?? "NIL")
        print("DOB:", txtDob.text ?? "NIL")
        
//        if [txtName, txtUserName, txtPhone, txtLocation, txtGender, txtDob]
//            .contains(where: { !($0.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }) {
//            self.showAlert("Please add all the fields.")
//            // Update profile
//            return
//        }
        
        request.editProfileAPi { msg, errCode in
            
            DispatchQueue.main.async {
                if errCode == 200 {
                    self.showAlert("Profile Updated Successfully")
                    super.backTapped()
                } else {
                    self.showAlert(msg)
                }
            }
            print(errCode,msg,"ProfileErros")
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

            self.uploadImg(true,data) { [weak self] imageName in
                
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
    
    @IBAction func btnVerifyFirebase(_ sender: UIButton) {
        self.view.endEditing(true)
        guard let localNumber = txtPhone.text,
              !localNumber.isEmpty else {
            showAlert("Enter phone number")
            return
        }

        let phone = phoneField.fullNumber

        showLoader()

        FirebaseManager.shared.sendOTP(phone: phone) { success, message in

            DispatchQueue.main.async {

                self.hideLoader()

                if success {

                    let otpVC = OTPBottomSheetVC()
                    otpVC.modalPresentationStyle = .pageSheet

                    if let sheet = otpVC.sheetPresentationController {
                        sheet.detents = [.medium()]
                        sheet.prefersGrabberVisible = true
                        sheet.preferredCornerRadius = 24
                    }

                    otpVC.onVerify = { [weak self, weak otpVC] code in

                        guard let self = self else { return }

                        FirebaseManager.shared.verifyOTP(code: code) { verifySuccess, verifyMessage in

                            DispatchQueue.main.async {

                                if verifySuccess {

                                    otpVC?.dismiss(animated: true) {
                                        self.request.phone_verify = true
                                        self.btnVerify.setTitle("Verified", for: .normal)
                                        self.btnVerify.setTitleColor(.green, for: .normal)
                                        self.btnVerify.isEnabled = false
                                    }

                                } else {
                                    self.request.phone_verify = false
                                    print(verifyMessage, "OTP VERIFY FAILED")
                                    self.showAlert(verifyMessage)
                                }
                            }
                        }
                    }

                    otpVC.onResend = { [weak self] in

                        guard let self = self else { return }

                        FirebaseManager.shared.sendOTP(phone: self.phoneField.fullNumber) { resendSuccess, resendMessage in
                            if !resendSuccess {
                                print(resendMessage, "RESEND FAILED")
                            }
                        }
                    }

                    self.present(otpVC, animated: true)
                    
                } else {
                    print(message,"HERE OTP NOT SENT")
                    self.showAlert(message)
                }
            }
        }
    }
}

extension EditProfileVc :UITextFieldDelegate{
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        
        guard textField == txtPhone else {
            return true
        }
        
        let current = textField.text ?? ""
        
        guard let textRange = Range(range, in: current) else {
            return false
        }
        
        let updated = current.replacingCharacters(in: textRange, with: string)
        textField.text = partialFormatter.formatPartial(updated)
        
        return false
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == txtLocation {
            locationView.isHidden = false
        }
    }
}

