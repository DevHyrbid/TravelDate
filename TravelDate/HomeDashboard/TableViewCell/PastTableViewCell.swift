//
//  PastTableViewCell.swift
//  TravelDate
//
//  Created by Dev CodingZone on 18/05/26.
//

import UIKit

class PastTableViewCell: UITableViewCell {

    @IBOutlet weak var imgVw:UIImageView!
    @IBOutlet weak var lblTitle:UILabel!
    @IBOutlet weak var lblDate:UILabel!
   
    override func awakeFromNib() {
        super.awakeFromNib()
        lblTitle.setFont(.semiBold, size: 14.0)
        lblDate.setFont(.regular, size: 12.0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
