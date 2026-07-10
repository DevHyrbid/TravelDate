//
//  ProfileViewController.swift
//  TravelDate
//
//  Created by Dev CodingZone on 14/04/26.
//
struct TravelItem {
    let title: String
    let month: String
    let icon: String?
    let status: String
}
import UIKit

class ProfileViewController: BaseClassVc {
    
    // MARK: - IBoutlets
    @IBOutlet weak var txtAbout: UITextView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var collectionVw: UICollectionView!
    @IBOutlet weak var lblProfileTitle: UILabel!
    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var borderView: ProgressBorderView!

    private let progressLayer = CAShapeLayer()
    
    // MARK: - Arr
    var arr = [String]()
    var selectedTravelStyle: TravelStyle = .partygoers
    var selectedTravelStyles: [TravelStyle] = []
    var data = [TravelItem]()
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        lblProfileTitle.setFont(.medium, size: 18.0)
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
    
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        borderView.setProgress(25)x
//        request.getProfile { loginUser, errMsg, errCode in
//            print(loginUser?.front,loginUser?.back,loginUser?.selfie,"hejkruehwensmkoiu")
//        }
    }
    
    
    
   
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }
    
    // MARK: - ViewViewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        txtAbout.setFont(.medium, size: 14.0)
        lblName.setFont(.bold, size: 18.0)
        lblUserName.setFont(.bold, size: 16.0)
        self.txtAbout.text = User.curentUser?.short_bio ?? ""
        lblName.text = User.curentUser?.name ?? ""
        lblUserName.text = "@\(User.curentUser?.userName ?? "")"
        if let url = URL(string: User.curentUser?.profile_image ?? "") {
            loadImage(imgProfile, url: url)
        } else {
            imgProfile.image = UIImage(named: "User")
        }
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
        
        imgProfile.contentMode = .scaleToFill
        
        tripsTabBarController?.showTabBar()
        registerNib()
        
    }
    
    
    
    func updateProfileCompletion() {

        var completedFields = 0
        let totalFields = 4

        if !(User.curentUser?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedFields += 1
        }

        if !(User.curentUser?.userName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedFields += 1
        }

        if !(User.curentUser?.short_bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedFields += 1
        }

        if !(User.curentUser?.profile_image ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedFields += 1
        }

        let progress = CGFloat(completedFields) / CGFloat(totalFields) * 100
        print(progress)
        borderView.setProgress(25) // 75%
    }
    
    func registerNib() {
        tblVw.register(TravelCell.self,
                           forCellReuseIdentifier: TravelCell.identifier)
        getHistoryTrips()
    }
    
    func getHistoryTrips() {
        request.getHistoryTrips { model, err, code in
            if code == 200 {
                
                for (index, item) in model!.enumerated() {
                    self.data.append(TravelItem(
                        title: item.title ?? "",
                        month: "May 2026",
                        icon: item.coverImage,
                        status: item.status ?? ""
                    ))
                }
                DispatchQueue.main.async {
                    self.tblVw.reloadData()
                }
                
            }
        }
    }
    
    func saveAPi() {
        
        request.editProfileAPi {[self] msg, errCode in
            if User.curentUser?.travelStyles != nil {
                for i  in 0..<User.curentUser!.travelStyles!.count {
                    arr.append(User.curentUser!.travelStyles?[i] ?? "")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    
                    self.collectionVw.reloadData()
                })
            }        }
        
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
    
    @IBAction func btnAddStyles(_ sender: UIButton) {

        let picker = TravelStylePickerView(
            selectedStyles: selectedTravelStyles
        )

        picker.delegate = self

        picker.present()
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
    func travelStylePicker(_ picker: TravelStylePickerView, didSelect style: [TravelStyle]) {
       
        selectedTravelStyles = style

        arr.removeAll()

        for item in style {

            arr.append(item.title)
        }

        request.travelStyles = arr

        request.editProfileAPi { msg, errCode in

            print(msg)
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

extension ProfileViewController{
    @IBAction func btnUpgrade(_ sender:UIButton){
        
        // Screen 2 — Plans
        let vm = SubscriptionViewModel()
        vm.screenMode = .plans
        let vc = SubscriptionViewController(viewModel: vm, mode: .plans)
        
        // Callback when purchase succeeds
        vm.onPurchaseSuccess = {
            print("User subscribed! Unlock premium features.")
        }
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
        
    }
}

extension ProfileViewController:UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: TravelCell.identifier,
            for: indexPath
        ) as! TravelCell

        cell.configure(
            title: item.title,
            month: item.month,
            icon: item.icon,
            status: item.status
        )

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        116 // 110 (containerView height, measured from Figma) + 8 top + 8 bottom inset
    }
}
