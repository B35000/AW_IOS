//
//  ApplicantTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 22/01/2021.
//

import UIKit

class ApplicantTableViewCell: UITableViewCell {
    @IBOutlet weak var applicantImageView: UIImageView!
    @IBOutlet weak var applicantNameLabel: UILabel!
    @IBOutlet weak var applicantRatingsLabel: UILabel!
    @IBOutlet weak var applicationTimeLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var selectedApplicantImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
