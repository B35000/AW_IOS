//
//  WorkerPayViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import CoreData
import Firebase
import Foundation

class WorkerPayViewController: UIViewController {
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var suggestedLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var leaveSwitch: UISwitch!
    
    var at_most_2 = "At most 2 hours."
    var two_to_four = "Around 2 to 4 hours."
    var whole_day = "The whole day."
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var selected_tags = [String]()
    var amount = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let i = navigationController?.viewControllers.firstIndex(of: self)
        let tagsVC = (navigationController?.viewControllers[i!-4]) as! NewJobTagsViewController
        
        self.selected_tags = tagsVC.selectedTags
        
        let durationVC = (navigationController?.viewControllers[i!-2]) as! DurationViewController
        
        self.setSuggestion(selected_tags: selected_tags)
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    @IBAction func leaveAmountSwitched(_ sender: UISwitch) {
        if sender.isOn {
            amountField.text = ""
            self.amount = 0
            amountField.isEnabled = false
            finishButton.isHidden = false
        } else {
            amountField.isEnabled = true
            finishButton.isHidden = true
        }
    }
    
    @IBAction func whenAmountTyped(_ sender: UITextField) {
        hideErrorLabel()
        
        var isnumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: sender.text!))

        if !sender.hasText {
            showError("Set something")
            self.amount = 0
        }else if !isnumber{
            showError("You can't set that")
        }else if sender.text!.contains("-") {
            showError("You can't set that")
            self.amount = 0
        }
        else if Int(sender.text!)! <= 0 {
            showError("You can't set that")
            self.amount = 0
        }
        else{
            self.amount = Int(sender.text!)!
        }
        showFinishIfOk()
    }
    
    func showFinishIfOk(){
        if self.amount != 0 {
            finishButton.isHidden = false
        }else{
            finishButton.isHidden = true
            if leaveSwitch.isOn {
                finishButton.isHidden = false
            }
        }
    }
    
    func showError(_ error: String){
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func hideErrorLabel(){
        errorLabel.isHidden = true
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func setSuggestion(selected_tags: [String]){
        let prices = getTagPricesForTags(selected_tags: selected_tags)
        
        
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        let curr = me?.phone?.country_currency as! String
        
        if !prices.isEmpty {
            var top = Int(getTopAverage(prices))
            var bottom = Int(getBottomAverage(prices))
            
            if (top != 0  && top != bottom) {
                suggestedLabel.text = "Suggested: \(bottom) - \(top) \(curr), for ~2hrs"
            }
        }
    }
    
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
        
        var associates = self.getGlobalTagAssociatesIfExists(tag_title: global_tag.title!)
        if !associates.isEmpty{
            for associateTag in associates{
                var price = Double(associateTag.pay_amount)
                
                
                var json = associateTag.tag_associates
                let decoder = JSONDecoder()
                let jsonData = json!.data(using: .utf8)!
                
                do{
                    let tags: [json_tag] =  try decoder.decode(json_tag_array.self, from: jsonData).tags
                    var shared_tags: [String] = []
                    for item in tags{
                        if selected_tags.contains(item.tag_title) {
                            shared_tags.append(item.tag_title)
                        }
                    }
                    print("shared tags count \(shared_tags.count)")
                    
                    if shared_tags.count == selected_tags.count || shared_tags.count >= 1 {
                        //associated tag obj works
                        var price = Double(associateTag.pay_amount)
                        print("set \(price) for tag \(associateTag.title!)")
                        
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
                        
                        prices.append(price)
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
    
    
    struct json_tag_array: Codable{
        var tags: [json_tag] = []
    }
    
    struct json_tag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
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
