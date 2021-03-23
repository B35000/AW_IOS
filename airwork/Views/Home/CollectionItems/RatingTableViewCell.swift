//
//  RatingTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 20/01/2021.
//

import UIKit
import Cosmos

class RatingTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var ratingMonthLabel: UILabel!
    @IBOutlet weak var ratingDayLabel: UILabel!
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var ratingTimeLabel: UILabel!
    @IBOutlet weak var ratingAgeLabel: UILabel!
    @IBOutlet weak var jobDurationLabel: UILabel!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var rating: CosmosView!
    
    @IBOutlet weak var durationView: UIView!
    var tags = [String]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
           // Code you want to be delayed
            
        }
        
        tagsCollectionView.delegate = self
        tagsCollectionView.dataSource = self
        
        
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        print("number of tags: \(tags.count)")
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ratingTagCell", for: indexPath) as! RatingTagCollectionViewCell
        cell.titleLabel.text = tags[indexPath.row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 1
    }
    

}
