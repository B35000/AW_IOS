//
//  ApplicantRatingTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 31/01/2021.
//

import UIKit
import Cosmos

class ApplicantRatingTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingsLabel: UILabel!
    @IBOutlet weak var setRatingView: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    
    var whenCancelTapped : (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func whenCancelTapped(_ sender: Any) {
        whenCancelTapped?()
    }
    
}
