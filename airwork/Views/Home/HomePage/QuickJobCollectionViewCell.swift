//
//  QuickJobCollectionViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 05/03/2021.
//

import UIKit

class QuickJobCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var fullViewContainer: UIView!
    @IBOutlet weak var expandedViewContainer: UIView!
    @IBOutlet weak var compactViewContainer: UIView!
    @IBOutlet weak var groupTitleLabel: UILabel!
    
    @IBOutlet weak var compactImage: UIImageView!
    @IBOutlet weak var compactTitleLabel: UILabel!
    @IBOutlet weak var expandedImage: UIImageView!
    @IBOutlet weak var expandedTitleLabel: UILabel!
    @IBOutlet weak var fullImage: UIImageView!
    
    @IBOutlet weak var compactPriceLabel: UILabel!
    @IBOutlet weak var expandedPriceLabel: UILabel!
    
}
