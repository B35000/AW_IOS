//
//  AppliedJobTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 25/02/2021.
//

import UIKit

class AppliedJobTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
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
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0))
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return jobTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "AppliedJobTagCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AppliedJobTagCollectionViewCell
        
        let tag = jobTags[indexPath.row]
        cell.tagTitleLabel.text = tag.title
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 3;
    }

}
