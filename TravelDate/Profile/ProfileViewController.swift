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
    @IBOutlet weak var btnVwHistory: UIButton!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var collectionVw: UICollectionView!
    @IBOutlet weak var lblProfileTitle: UILabel!
    @IBOutlet weak var tblVw:UITableView!
    @IBOutlet weak var borderView: ProgressBorderView!
    @IBOutlet weak var heightVw: NSLayoutConstraint!
    @IBOutlet weak var imgMyTrips: UIImageView!
    @IBOutlet weak var imgPermium: UIImageView!
    @IBOutlet weak var imgPermiumHeight: NSLayoutConstraint!
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
        
        DispatchQueue.main.async {
            if self.hasPaidSubscription {
                self.imgPermium.isHidden = false
                self.imgPermiumHeight.constant = 34
            } else {
                self.imgPermium.isHidden = true
                self.imgPermiumHeight.constant = 0
            }
            self.arr = User.curentUser?.travelStyles ?? []

            self.collectionVw.performBatchUpdates({
                self.collectionVw.reloadSections(IndexSet(integer: 0))
            })
        }
        
//        let vc = TravelListViewController()
//        navigationController?.pushViewController(vc, animated: true)
//        
        collectionVw.register(TravelStyleCell.self,
                                      forCellWithReuseIdentifier: TravelStyleCell.identifier)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }
    
    // MARK: - ViewViewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        txtAbout.setFont(.medium, size: 14.0)
        lblName.setFont(.bold, size: 20.0)
        lblUserName.setFont(.regular, size: 14.0)
        self.txtAbout.text = User.curentUser?.short_bio ?? ""
        lblName.text = User.curentUser?.name ?? ""
        if User.curentUser?.userName != "" {
            lblUserName.text = "@\(User.curentUser?.userName ?? "")"
        } else {
            lblUserName.text = ""
        }
        if let url = URL(string: User.curentUser?.profile_image ?? "") {
            loadImage(imgProfile, url: url)
        } else {
            imgProfile.image = UIImage(named: "User")
        }
        imgProfile.layer.cornerRadius = imgProfile.frame.height / 2
        
        imgProfile.contentMode = .scaleAspectFill
        imgProfile.clipsToBounds = true
        
        tripsTabBarController?.showTabBar()
        registerNib()
        updateProfileCompletion()
    }
    
    
    
    func updateProfileCompletion() {

        var completedFields = 0
        let totalFields = 5

        if !(User.curentUser?.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty {
            completedFields += 1
        }

        if !(User.curentUser?.userName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty {
            completedFields += 1
        }

        if !(User.curentUser?.short_bio ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty {
            completedFields += 1
        }

        if !(User.curentUser?.profile_image ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty {
            completedFields += 1
        }

        if !(User.curentUser?.travelStyles?.isEmpty ?? true) {
            completedFields += 1
        }

        let progress = CGFloat(completedFields) / CGFloat(totalFields)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.borderView.setProgress(progress)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        imgProfile.layer.cornerRadius = imgProfile.bounds.width / 2
        imgProfile.clipsToBounds = true
    }
    
    func registerNib() {
        tblVw.register(TravelCell.self,
                           forCellReuseIdentifier: TravelCell.identifier)
        getHistoryTrips()
    }
    
    func getHistoryTrips() {
        request.getHistoryTrips { [self] model, err, code in
            if code == 200 {
                self.data.removeAll()
//                if data.count == 0 {
//                    imgMyTrips.isHidden = true
//                } else {
//                    imgMyTrips.isHidden = false
//                }
                for (_, item) in model!.enumerated() {
                    
                    self.data.append(TravelItem(
                        title: item.title ?? "",
                        month: updateDate(item.endDate ?? ""),
                        icon: item.coverImage,
                        status: item.status ?? ""
                    ))
                }
                DispatchQueue.main.async {
                    let rowHeight: CGFloat = 116
                    let count = min(data.count, 3)

                    self.heightVw.constant = CGFloat(count) * rowHeight
                    if self.data.count > 3 {
                        self.btnVwHistory.isHidden = false
                } else {
                    self.btnVwHistory.isHidden = true
                }
             
                    self.tblVw.reloadData()
                }
                
            }
        }
    }
    
    func updateDate( _ isoString:String) -> String{
        

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.timeZone = TimeZone(identifier: "UTC")
            
            let result = formatter.string(from: date)
            print(result) // May 2026
            return result
        }
        return ""
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

        selectedTravelStyles = (User.curentUser?.travelStyles ?? []).compactMap {
            TravelStyle(title: $0)
        }

        let picker = TravelStylePickerView(selectedStyles: selectedTravelStyles)
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

        print("Selected count:", style.count)
        print(style.map { $0.title })

        selectedTravelStyles = style

        arr = style.map { $0.title }

        print(arr)

        request.travelStyles = arr

        
        request.editProfileAPi { [weak self] msg, errCode in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                print("After API:", User.curentUser?.travelStyles ?? [])
                
//                self.arr = User.curentUser?.travelStyles ?? []
//              
//                self.selectedTravelStyles = self.arr.compactMap {
//                    TravelStyle(title: $0)
//                }
                print(self.arr,self.arr.count,self.selectedTravelStyle,"ANA IDAR DEKHO")
                
                DispatchQueue.main.async {
                    self.arr = User.curentUser?.travelStyles ?? []

                    self.collectionVw.performBatchUpdates({
                        self.collectionVw.reloadSections(IndexSet(integer: 0))
                    })
                }
            }
        }

        
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
        self.pushVC(PreiumController.self, from: .Settings,hideTabBar: true)
//        self.pushVC(FreeSubscriptionVc.self, from: .Settings,hideTabBar: true)
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
        100 // 110 (containerView height, measured from Figma) + 8 top + 8 bottom inset
    }
}

extension ProfileViewController {
    @IBAction func btnView(_ sender:UIButton) {
        let vc = TravelListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
