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
    let constants = Constants.init()
    
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
        let prices = constants.getTagPricesForTags(selected_tags: selected_tags, context: self.context)
        
        
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        let curr = me?.phone?.country_currency as! String
        
        if !prices.isEmpty {
            var top = Int(constants.getTopAverage(prices))
            var bottom = Int(constants.getBottomAverage(prices))
            
            if (top != 0  && top != bottom) {
                suggestedLabel.text = "Suggested: \(bottom) - \(top) \(curr), for ~2hrs"
            }
        }
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
