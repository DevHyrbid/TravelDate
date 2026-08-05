//
//  NewMatchCellTableViewCell.swift
//  TravelDate
//
//  Created by Dev CodingZone on 13/04/26.
//

import UIKit

class NewMatchCellTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nwVw:UIView!
    @IBOutlet weak var savedVw:UIView!
    @IBOutlet weak var matchVw:UIView!
    @IBOutlet weak var matchVwSave:UIView!
    @IBOutlet weak var lblMatched:UILabel!
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var lblTime:UILabel!
    @IBOutlet weak var lblLocation:UILabel!
    @IBOutlet weak var btnSaveGroup:UIButton!
    @IBOutlet weak var btnStart:UIButton!
    @IBOutlet weak var imgVw:UIImageView!
    @IBOutlet weak var imgVwSave:UIImageView!
    @IBOutlet weak var lblName:UILabel!
    @IBOutlet weak var lblTimeSave:UILabel!
    @IBOutlet weak var lblLocationSave:UILabel!
    @IBOutlet weak var btnViewGroup:UIButton!
    @IBOutlet weak var vwGlass:UIView!
    
    let membersView = MembersProgressView()
    let membersVwSave = MembersProgressView()
    
    var onStartChat: (() -> Void)?
    var onSaveGroup: (() -> Void)?
    var onViewGroup: (() -> Void)?
    var onRemoveBookmark: (() -> Void)?
    func setTimeText(_ text: String)  { lblTime.text  = text  }
    func setTimeTextSave(_ text: String)  { lblTimeSave.text  = text  }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        membersView.translatesAutoresizingMaskIntoConstraints = false
        membersView.progressTrack.isHidden  = true
        membersVwSave.progressTrack.isHidden  = true
        membersView.backgroundColor = .clear
        membersVwSave.backgroundColor = .clear
        matchVw.addSubview(membersView)
        NSLayoutConstraint.activate([
            membersView.leadingAnchor.constraint(equalTo: matchVw.leadingAnchor),
            membersView.trailingAnchor.constraint(equalTo: matchVw.trailingAnchor),
            membersView.topAnchor.constraint(equalTo: matchVw.topAnchor),
            membersView.bottomAnchor.constraint(equalTo: matchVw.bottomAnchor),
        ])
        
        membersVwSave.translatesAutoresizingMaskIntoConstraints = false
        matchVwSave.addSubview(membersVwSave)
        NSLayoutConstraint.activate([
            membersVwSave.leadingAnchor.constraint(equalTo: matchVwSave.leadingAnchor),
            membersVwSave.trailingAnchor.constraint(equalTo: matchVwSave.trailingAnchor),
            membersVwSave.topAnchor.constraint(equalTo: matchVwSave.topAnchor),
            membersVwSave.bottomAnchor.constraint(equalTo: matchVwSave.bottomAnchor),
        ])
        
        // MARK: - Fonts
        lblMatched.font = AppFont.semibold(10)
        lblTitle.font = AppFont.semibold(22)
        lblTime.font = AppFont.regular(14)
        lblLocation.font = AppFont.regular(14)
        
        lblName.font = AppFont.semibold(16)
        lblTimeSave.font = AppFont.regular(13)
        lblLocationSave.font = AppFont.regular(13)
        btnSaveGroup.layer.borderWidth = 1
        btnSaveGroup.layer.borderColor = UIColor.lightGray.cgColor
//        btnStart.setFont(UIFont(name: "Poppins-SemiBold", size: 18.0)
//           btnSaveGroup.setFont(UIFont(name: "Poppins-SemiBold", size: 18.0)
                                 btnViewGroup.layer.borderWidth = 1
        btnViewGroup.layer.borderColor = UIColor.lightGray.cgColor
        btnStart.addTarget(self, action: #selector(startChatTapped), for: .touchUpInside)
        btnSaveGroup.addTarget(self, action: #selector(saveGroupTapped), for: .touchUpInside)
        btnViewGroup.addTarget(self,
                               action: #selector(viewGroupTapped),
                               for: .touchUpInside)
        
    }
    
    @objc func viewGroupTapped() {
        onViewGroup?()
    }
    
    @objc private func startChatTapped() {
        onStartChat?()
    }
    
    @objc private func saveGroupTapped() {
        onSaveGroup?()
        
    }
    
    func showNewMatch() {
        nwVw.isHidden = false
        savedVw.isHidden = true
    }

    func showSavedGroup() {
        nwVw.isHidden = true
        savedVw.isHidden = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    
    
    func configureNewMatch(with model: Group) {

        nwVw.isHidden = false
        savedVw.isHidden = true

        let group = model

        lblTitle.text = group.title
        lblLocation.text = group.destination

//        lblTime.text = formatDateRange(
//            start: group?.startDate ?? "",
//            end: group?.endDate ?? ""
//        )

        

        membersView.configure(
            members: group.members ?? [],
            totalCount: group.maxGroupSize ?? 0,
            completedCount: group.members?.count ?? 0
        )
    }

    
    
    func configureSavedGroup(with model: Group) {
        print("nwVw:", nwVw.isHidden)
        print("savedVw:", savedVw.isHidden)
//        nwVw.isHidden = true
        savedVw.isHidden = false

        lblName.text = model.title
        lblLocationSave.text = model.destination

//        lblTimeSave.text = formatDateRange(
//            start: model.startDate ?? "",
//            end: model.endDate ?? ""
//        )

        membersVwSave.configure(
            members: model.members ?? [],
            totalCount: model.maxGroupSize ?? 0,
            completedCount: model.members?.count ?? 0
        )
    }
    
}

import UIKit

final class GlassBadgeLabel: UIView {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let label = UILabel()

    init(text: String) {
        super.init(frame: .zero)
        setup(text: text)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(text: "")
    }

    private func setup(text: String) {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        // Glass background
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isUserInteractionEnabled = false
        addSubview(blurView)

        // Slight white tint for the frosted look
        let tintView = UIView()
        tintView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        tintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tintView)

        // Label
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintView.topAnchor.constraint(equalTo: topAnchor),
            tintView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tintView.bottomAnchor.constraint(equalTo: bottomAnchor),

            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Rounded only on trailing side (pill hanging from corner)
        layer.cornerRadius = bounds.height / 2
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
}
