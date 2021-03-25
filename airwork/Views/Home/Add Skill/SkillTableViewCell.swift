//
//  SkillTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 21/01/2021.
//

import UIKit
import Firebase

class SkillTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource,
                          UICollectionViewDelegateFlowLayout{
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var imagesCollection: UICollectionView!
    
    var skill_images = [String]()
    var user_id = ""
    var constants = Constants.init()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        imagesCollection.delegate = self
        imagesCollection.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        skill_images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "skillImageCell", for: indexPath) as! SkillImageCollectionViewCell
        
        let image_name = skill_images[indexPath.row]
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(user_id)
            .child(constants.qualification_images)
            .child("\(image_name).jpg")
        
        ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
              // Uh-oh, an error occurred!
                print("loading image from cloud failed")
            } else {
              // Data for "images/island.jpg" is returned
                let im = UIImage(data: data!)
                cell.imageView.image = im
            }
          }
        
        return cell
    }

}
