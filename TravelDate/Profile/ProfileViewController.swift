//
//  ProfileViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone on 14/04/26.
//

import UIKit

class ProfileViewController: BaseClassVc {
    
    // MARK: - IBoutlets
    @IBOutlet weak var txtAbout: UITextView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var collectionVw: UICollectionView!
    
    // MARK: - Arr
    var arr = [String]()
    
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if User.curentUser?.travelStyles != nil {
            for i  in 0..<User.curentUser!.travelStyles!.count {
                arr.append(User.curentUser!.travelStyles?[i] ?? "")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                
                self.collectionVw.reloadData()
            })
        }
            collectionVw.register(TravelStyleCell.self,
                                  forCellWithReuseIdentifier: TravelStyleCell.identifier)
        }
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }
    
    // MARK: - ViewViewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.txtAbout.text = User.curentUser?.short_bio ?? ""
        lblName.text = User.curentUser?.name ?? ""
        lblUserName.text = "@\(User.curentUser?.userName ?? "")"
        if let url = URL(string: User.curentUser?.profile_image ?? "") {
            loadImage(imgProfile, url: url)
        }
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
        
        imgProfile.contentMode = .scaleToFill
        
        tripsTabBarController?.showTabBar()
    }
    
    func saveAPi() {
        
        request.editProfileAPi { msg, errCode in
            if errCode == 200 {
                self.showAlert("Profile UpdatedSuccesfully")
            }
        }
        
    }
    
}

extension ProfileViewController {
    @IBAction func btnSettings(_ sender:UIButton){
        self.pushVC(SettingsVc.self, from: .Settings, hideTabBar: true)
    }
    
    @IBAction func btnEditABout(_ sender:UIButton){
        if sender.tag == 101 {
            self.pushVC(EditProfileVc.self, from: .Settings, hideTabBar: true)
        } else if sender.tag == 102 {
            openAboutEdit()
        }
       
    }
    
    @IBAction func btnAddStyles(_ sender:UIButton){
        let picker = TravelStylePickerView()
           picker.delegate = self
           picker.present(in: self)
    }
    
    func openAboutEdit() {
        let editView = AboutEditView()

        editView.onSave = { [weak self] text in
            guard let self = self else { return }
            
            self.txtAbout.text = text
            
            //                request.name = txtName.text ?? ""
            request.short_bio = text
            request.editProfileAPi { msg, errCode in
                
            }
           
        }

        editView.present(in: self.view, text: txtAbout.text)
    }
}

extension ProfileViewController: TravelStylePickerDelegate {
    
    func travelStylePicker(_ picker: TravelStylePickerView, didSelect style: TravelStyle) {
        print("Selected:", style.title)
        if !arr.contains(style.title) {
            arr.append(style.title)
        }
        request.travelStyles = arr
        request.editProfileAPi { msg, errCode in
            
        }
        self.collectionVw.reloadData()
    }
}

extension ProfileViewController : CollectionDelegate
{
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TravelStyleCell.identifier,
            for: indexPath
        ) as! TravelStyleCell
        cell.titleLabel.text = arr[indexPath.row]
        cell.configure(title: arr[indexPath.row], isSelected: true)
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
}
