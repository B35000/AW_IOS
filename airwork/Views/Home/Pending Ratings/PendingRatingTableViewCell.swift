//
//  PendingRatingTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 13/02/2021.
//

import UIKit
import Cosmos

class PendingRatingTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var jobStartDateLabel: UILabel!
    @IBOutlet weak var jobAmountLabel: UILabel!
    @IBOutlet weak var tagsCollection: UICollectionView!
    @IBOutlet weak var jobTimeLabel: UILabel!
    @IBOutlet weak var duration: UILabel!
    
    @IBOutlet weak var amountView: UIView!
    @IBOutlet weak var timeDurationView: UIView!
    @IBOutlet weak var takenDownImage: UIImageView!
    var jobTags = [JobTag]()
    
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingsLabel: UILabel!
    @IBOutlet weak var setRatingView: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var andOtherLabel: UILabel!
    
    var whenCancelTapped : (() -> Void)?
    var whenViewAllTapped : (() -> Void)?
    var whenSetTapped : (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        tagsCollection.delegate = self
        tagsCollection.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func whenRemoveTapped(_ sender: Any) {
        whenViewAllTapped?()
    }
    
    @IBAction func whenSetTapped(_ sender: Any) {
        whenSetTapped?()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return jobTags.count

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "PendingRatingJobTagCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PendingJobTagCollectionViewCell
        
        let tag = jobTags[indexPath.row]
        cell.tagTitleLabel.text = tag.title
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 3;
    }
    

}
