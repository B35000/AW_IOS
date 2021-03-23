//
//  ContactTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 01/02/2021.
//

import UIKit
import Cosmos

class ContactTableViewCell: UITableViewCell {
    @IBOutlet weak var contactImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contactAgeLabel: UILabel!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var jobsDoneLabel: UILabel!
    @IBOutlet weak var lastRatingLabel: UILabel!
    @IBOutlet weak var lastRatingView: CosmosView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
