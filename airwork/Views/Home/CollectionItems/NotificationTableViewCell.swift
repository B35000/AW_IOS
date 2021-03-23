//
//  NotificationTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 10/01/2021.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    @IBOutlet weak var notificationItem: UILabel!
    @IBOutlet weak var notifAgeLabel: UILabel!
    @IBOutlet weak var senderLabel: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
