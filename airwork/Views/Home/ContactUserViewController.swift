//
//  ContactUserViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 15/04/2021.
//

import UIKit
import CoreData

class ContactUserViewController: UIViewController {
    @IBOutlet weak var guidelineImage: UIImageView!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var contact_id = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
  
        
        if amIAirworker(){
            if UITraitCollection.current.userInterfaceStyle == .dark {
                guidelineImage.image = UIImage(named: "WorkerGuidelineDark")
            }else{
                guidelineImage.image = UIImage(named: "WorkerGuideline")
            }
        }else{
            if UITraitCollection.current.userInterfaceStyle == .dark {
                guidelineImage.image = UIImage(named: "UserGuidelineDark")
            }else{
                guidelineImage.image = UIImage(named: "UserGuideline")
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func whenCalledTapped(_ sender: Any) {
        let their_acc = self.getApplicantAccount(contact_id)
        let phone = "\(their_acc!.phone!.country_number_code!) \(their_acc!.phone!.digit_number)"
        
        if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction func whenEmailTapped(_ sender: Any) {
        let their_acc = self.getApplicantAccount(contact_id)
        let email = their_acc!.email!
        if let url = URL(string: "mailto:\(email)") {
          if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
          } else {
            UIApplication.shared.openURL(url)
          }
        }
    }
    
    
    
    func amIAirworker() -> Bool{
        let app_data = self.getAppDataIfExists()
        
        if app_data!.is_airworker {
            return true
        }
        
        return false
    }
    
    func getAppDataIfExists() -> AppData? {
        do{
            let request = AppData.fetchRequest() as NSFetchRequest<AppData>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }else{
                let new_app_data = AppData(context: self.context)
                return new_app_data
            }
            
        }catch {
            
        }
        
        return nil
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
    
}
