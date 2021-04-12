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
            let prices = getTagPricesForTags(selected_tags: job_item.tags_to_use)

            DispatchQueue.main.async {
                let uid = Auth.auth().currentUser!.uid
                let me = self.getAccountIfExists(uid: uid)
                let curr = me?.phone?.country_currency as! String
                
                if !prices.isEmpty {
                    var top = Int(getTopAverage(prices))
                    var bottom = Int(getBottomAverage(prices))
                    
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

    
    
    var at_most_2 = "At most 2 hours."
    var two_to_four = "Around 2 to 4 hours."
    var whole_day = "The whole day."
    
    func getTagPricesForTags(selected_tags: [String]) -> [Double]{
        var tag_with_prices = [Double]()
        
        for selected_tag in selected_tags {
            var global_t = self.getGlobalTagIfExists(tag_title: selected_tag)
            if global_t != nil {
                var associated_tag_prices = getAssociatedTagPrices(global_t!, selected_tags)
                if tag_with_prices.count < associated_tag_prices.count {
                    tag_with_prices.removeAll()
                    tag_with_prices.append(contentsOf: associated_tag_prices)
                }
            }
        }
        
        return tag_with_prices
    }
    
    func getAssociatedTagPrices(_ global_tag: GlobalTag,_ selected_tags: [String]) -> [Double] {
        var prices: [Double] = []
        var price_ids: [String] = []
        
        var associates = self.getGlobalTagAssociatesIfExists(tag_title: global_tag.title!)
//        print("tag associates for tag: \(global_tag.title!) -------------------------> \(associates.count)")
        if !associates.isEmpty{
            for associateTag in associates{
                var price = Double(associateTag.pay_amount)
                
                
                var json = associateTag.tag_associates
                let decoder = JSONDecoder()
                
                
                do{
                    var shared_tags: [String] = []
                    if json != nil {
                        let jsonData = json!.data(using: .utf8)!
                        let tags: [json_tag] =  try decoder.decode(json_tag_array.self, from: jsonData).tags
                        for item in tags{
                            if selected_tags.contains(item.tag_title) {
                                if(!shared_tags.contains(item.tag_title)){
                                    shared_tags.append(item.tag_title)
                                }
                            }
                        }
                    }
                    
                    print("shared tags for fumigate: \(associateTag.job_id!): \(shared_tags)")
                    
                    if (shared_tags.count == 1 && selected_tags.count == 1) || (shared_tags.count >= 2) {
                        //associated tag obj works
                        var price = Double(associateTag.pay_amount)
//                        print("set \(price) for tag \(associateTag.title!)")

                        if associateTag.no_of_days > 0 {
                            price = price / Double(associateTag.no_of_days)
                        }
                        if associateTag.work_duration != nil {
                            switch associateTag.work_duration {
                                case two_to_four:
                                    price = price / 2
                                case two_to_four:
                                    price = price / 4
                                default:
                                    price = price / 1
                            }
                        }
                        
                        if(!price_ids.contains(associateTag.job_id!)){
                            prices.append(price)
                            price_ids.append(associateTag.job_id!)
                        }
                    }
                    
                }catch {
                    
                }
            }
        }
        
        
        return prices
    }
    
    func getTopAverage(_ prices: [Double]) -> Double {
        let sortedPrices = prices.sorted(by: >)
        
        var number_of_items = Int(Double(prices.count) * 0.6)
        
        var total = 0.0
        for price in sortedPrices.prefix(number_of_items) {
            total += price
        }
        
        if total.isZero {
            return 0.0
        }
        
        return total / Double(number_of_items)
    }
    
    
    func getBottomAverage(_ prices: [Double]) -> Double {
        let sortedPrices = prices.sorted(by: <)
        
        var number_of_items = Int(Double(prices.count) * 0.6)
        
        var total = 0.0
        for price in sortedPrices.prefix(number_of_items) {
            total += price
        }
        
        if total.isZero {
            return 0.0
        }
        
        return total / Double(number_of_items)
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
    
    
    
    func getGlobalTagAssociatesIfExists(tag_title: String) -> [JobTag]{
        do{
            let request = JobTag.fetchRequest() as NSFetchRequest<JobTag>
            let predic = NSPredicate(format: "title == %@ && global == \(NSNumber(value: true))", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    func getGlobalTagIfExists(tag_title: String) -> GlobalTag?{
        do{
            let request = GlobalTag.fetchRequest() as NSFetchRequest<GlobalTag>
            let predic = NSPredicate(format: "title == %@", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
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
    
    struct json_tag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
    }
    
    struct json_tag_array: Codable{
        var tags: [json_tag] = []
    }
    
    
}
