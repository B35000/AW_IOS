//
//  QuickJobTableViewCell.swift
//  airwork
//
//  Created by Bry Onyoni on 05/03/2021.
//

import UIKit
import CoreData
import Firebase

class QuickJobTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    @IBOutlet weak var quickJobCollection: UICollectionView!
    @IBOutlet weak var groupTitleLabel: UILabel!
    var whenQuickJobTapped : ((_ value: Int) -> Void)?
    var pos = 0
    var job_group = HomeViewController.quickJobGroup()
    let COMPACT_VIEW_COUNT_THRESHOLD = 3 //1 in every 3 collections is compact
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let constants = Constants.init()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        quickJobCollection.delegate = self
        quickJobCollection.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return job_group.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "quickJobItems", for: indexPath) as! QuickJobCollectionViewCell
        
        let job_item = job_group.items[indexPath.row]
        
        cell.compactTitleLabel.text = job_item.jobTitle
        cell.expandedTitleLabel.text = job_item.jobTitle
        
        do {
            cell.compactImage.image = UIImage(named: job_item.jobTitle)
            cell.expandedImage.image = UIImage(named: job_item.jobTitle)
        } catch {
            print("error loading images for \(job_item.jobTitle)")
        }
        
        DispatchQueue.global(qos: .background).async { [self] in
//            let prices = getTagPricesForTags(selected_tags: job_item.tags_to_use)
            let prices = constants.getTagPricesForTags(selected_tags: job_item.tags_to_use, context: self.context)

            DispatchQueue.main.async {
                let uid = Auth.auth().currentUser!.uid
                let me = self.getAccountIfExists(uid: uid)
                let curr = me?.phone?.country_currency as! String
                
                if !prices.isEmpty {
                    var top = Int(constants.getTopAverage(prices))
                    var bottom = Int(constants.getBottomAverage(prices))
                    
                    if prices.count == 1 {
                        top = Int(prices[0])
                        bottom = Int(prices[0])
                    }
                    
                    if (top != 0  && top != bottom) {
                        cell.compactPriceLabel.text = "\(bottom) - \(top) \(curr)"
                        cell.expandedPriceLabel.text = cell.compactPriceLabel.text
                    }else if (top != 0  && top == bottom) {
                        cell.compactPriceLabel.text = "~ \(top) \(curr)"
                        cell.expandedPriceLabel.text = cell.compactPriceLabel.text
                    }else{
                        cell.compactPriceLabel.text = ""
                        cell.expandedPriceLabel.text = cell.compactPriceLabel.text
                    }
                }else{
                    cell.compactPriceLabel.text = ""
                }
            }
        }
        
        
        cell.compactImage.layer.cornerRadius = 5
        cell.expandedImage.layer.cornerRadius = 10
        
        if pos % COMPACT_VIEW_COUNT_THRESHOLD == 0 {
            cell.expandedViewContainer.isHidden = true
            cell.compactViewContainer.isHidden = false
        }else{
            cell.expandedViewContainer.isHidden = false
            cell.compactViewContainer.isHidden = true
        }
        
        
        return cell
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
//    {
//
//        return 4;
//    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //expanded width: 250, height: 170
//        return CGSize(width: 250, height: 75)
        if pos % COMPACT_VIEW_COUNT_THRESHOLD == 0 {
            return CGSize(width: 250, height: 75)
        }else{
            return CGSize(width: 230, height: 170)
        }
           
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         // handle tap events
        self.whenQuickJobTapped?(indexPath.item)
     }

    
    

    func getGlobalTagsIfExists() -> [GlobalTag]{
        do{
            let request = GlobalTag.fetchRequest() as NSFetchRequest<GlobalTag>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
        }catch {
            
        }
        
        return []
    }
    
    
    

    func getAccountIfExists(uid: String) -> Account? {
        do{
            let request = Account.fetchRequest() as NSFetchRequest<Account>
            let predic = NSPredicate(format: "uid == %@", uid)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }

}
