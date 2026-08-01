//
//  GroupTableViewCell.swift
//  TravelDate
//
//  Created by Dev CodingZone on 13/04/26.
//

import UIKit

class GroupTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnEdit:UIButton!
    @IBOutlet weak var lblLocation:UILabel!
    @IBOutlet weak var imgUser:UIImageView!
    @IBOutlet weak var collectionVw:UICollectionView!
    @IBOutlet weak var lbl1:UILabel!
    @IBOutlet weak var lbl2:UILabel!
    @IBOutlet weak var lbl3:UILabel!
    @IBOutlet weak var lbl4:UILabel!
    
    var styles: [String] = [] {
        didSet {
            collectionVw.reloadData()
            collectionVw.layoutIfNeeded()
            
            centerCollectionView()
        }
    }
    
    func centerCollectionView() {
        let contentWidth = collectionVw.collectionViewLayout.collectionViewContentSize.width
        let collectionWidth = collectionVw.bounds.width
        
        let inset = max((collectionWidth - contentWidth) / 2, 0)
        
        collectionVw.contentInset = UIEdgeInsets(
            top: 0,
            left: inset,
            bottom: 0,
            right: inset
        )
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionVw.register(
            TravelStyleCell.self,
            forCellWithReuseIdentifier: TravelStyleCell.identifier
        )
        
        if let layout = collectionVw.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 8
            layout.minimumLineSpacing = 8
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        collectionVw.delegate = self
        collectionVw.dataSource = self
        collectionVw.backgroundColor = .clear
        collectionVw.showsHorizontalScrollIndicator = false
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

extension GroupTableViewCell: UICollectionViewDelegate,
                              UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        styles.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TravelStyleCell.identifier,
            for: indexPath
        ) as! TravelStyleCell
        
        cell.configure(title: styles[indexPath.item], isSelected: false)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let text = styles[indexPath.item]

        let font = UIFont.systemFont(ofSize: 14, weight: .medium)

        let width = (text as NSString).size(withAttributes: [.font: font]).width

        return CGSize(width: width + 32, height: 36)
    }
}
