//
//  GroupTableViewCell.swift
//  TravelDate
//
//  Created by Dev CodingZone on 13/04/26.
//

import UIKit

class GroupTableViewCell: UITableViewCell {

    @IBOutlet weak var btnEdit:UIButton!
    @IBOutlet weak var lblLocation:UILabel!
    @IBOutlet weak var imgUser:UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
