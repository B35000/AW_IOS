//
//  ChangePhoneViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 06/02/2021.
//

import UIKit
import CountryPickerView
import Firebase
import CoreData

class ChangePhoneViewController: UIViewController {
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var cpvMain: CountryPickerView!
    @IBOutlet weak var finishButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    let db = Firestore.firestore()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        var my_id = Auth.auth().currentUser!.uid
        var account = getApplicantAccount(my_id)
        
        phoneNumberField.text = "\(account!.phone!.digit_number)"
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch(segue.identifier ?? "") {
                        
        case "verifyNumberSegue":
            guard let verifyNumberViewController = segue.destination as? VerifyNumberViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            var typedNumber = phoneNumberField.text! as String
            if typedNumber.count == 10 {
                typedNumber.remove(at: typedNumber.startIndex)
            }
            
            let country = cpvMain.selectedCountry.name
            let countryCode = cpvMain.selectedCountry.code
            let phoneCode = cpvMain.selectedCountry.phoneCode
            
            verifyNumberViewController.newNumber = "\(phoneCode)\(typedNumber)"
            
        default:
            print("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    @IBAction func whenPhoneTyped(_ sender: Any) {
        hideErrorLabel()
        
        if !phoneNumberField.hasText {
            showError("Type a phone number!")
            
            finishButton.isHidden = true
            
        } else {
            var typedNumber = phoneNumberField.text! as String
            if typedNumber.count == 10 {
                typedNumber.remove(at: typedNumber.startIndex)
            }
            
            let country = cpvMain.selectedCountry.name
            let countryCode = cpvMain.selectedCountry.code
            let phoneCode = cpvMain.selectedCountry.phoneCode
            
            finishButton.isHidden = false
            
        }
        
        
    }
    
    func showError(_ error: String){
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func hideErrorLabel(){
        errorLabel.isHidden = true
    }
    
    func getApplicantAccount(_ user_id: String) -> Account? {
        do{
            let request = Account.fetchRequest() as NSFetchRequest<Account>
            
            let predic = NSPredicate(format: "uid == %@", user_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    
    var child = SpinnerViewController()
    var isShowingSpinner = false
    func showLoadingScreen() {
        if !isShowingSpinner {
            child = SpinnerViewController()
            // add the spinner view controller
            addChild(child)
            child.view.frame = view.frame
            view.addSubview(child.view)
            child.didMove(toParent: self)
            isShowingSpinner = true
        }
    }
    
    func hideLoadingScreen(){
        if isShowingSpinner {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
            isShowingSpinner = false
        }
    }

}
