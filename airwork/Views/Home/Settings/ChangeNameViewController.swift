//
//  ChangeNameViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 06/02/2021.
//

import UIKit
import CoreData
import Firebase

class ChangeNameViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var femaleLabel: UILabel!
    @IBOutlet weak var maleLabel: UILabel!
    
    @IBOutlet weak var femaleImage: UIImageView!
    @IBOutlet weak var maleImage: UIImageView!
    
    var gender = "Female"
    var typedName = ""
    let db = Firestore.firestore()
    let constants = Constants.init()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let male_tap = UITapGestureRecognizer(target: self, action: #selector(SignUpNameViewController.whenMaleGenderPicked))
        let female_tap = UITapGestureRecognizer(target: self, action: #selector(SignUpNameViewController.whenFemaleGenderPicked))
        
        
        femaleLabel.addGestureRecognizer(female_tap)
        maleLabel.addGestureRecognizer(male_tap)
        
        var my_id = Auth.auth().currentUser!.uid
        var account = getApplicantAccount(my_id)
        
        nameTextField.text = account?.name
        if account!.gender! == "Male"{
            if gender == "Female" {
                gender = "Male"
                
                femaleImage.isHidden = true
                maleImage.isHidden = false
            }
            
            print("set gender \(gender)")
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

    @IBAction func whenNameInputChanged(_ sender: UITextField) {
        if sender.text! == "" {
            print("nothing typed")
            doneButton.isHidden = true
            typedName = ""
        } else if sender.text!.count < 3 {
            doneButton.isHidden = true
            typedName = ""
        }
        else{
            print(sender.text!)
            doneButton.isHidden = false
            typedName = sender.text!
        }
    }
    
    @objc func whenFemaleGenderPicked(sender:UITapGestureRecognizer) {
        if gender == "Male" {
            gender = "Female"
            
            femaleImage.isHidden = false
            maleImage.isHidden = true
        }

        print("set gender \(gender)")
       }
    
    @objc func whenMaleGenderPicked(sender:UITapGestureRecognizer) {
        if gender == "Female" {
            gender = "Male"
            
            femaleImage.isHidden = true
            maleImage.isHidden = false
        }
        
        print("set gender \(gender)")
       }
    
    @IBAction func whenDoneTapped(_ sender: Any) {
        showLoadingScreen()
        var my_id = Auth.auth().currentUser!.uid
        db.collection(constants.users_ref)
            .document(my_id).updateData(
                ["name" : "\(typedName)",
                 "gender" : "\(gender)"]
            )
        
        db.collection(constants.airworkers_ref)
            .document(my_id).updateData(
                ["name" : "\(typedName)",
                 "gender" : "\(gender)"]
            ){ err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                    self.hideLoadingScreen()
                    self.navigationController?.popViewController(animated: true)
                }
                
            }
        
        var my_jobs = getMyJobsIfExists()
        
        for item in my_jobs{
            db.collection(constants.jobs)
                .document(item.country_name!)
                .collection(constants.country_jobs)
                .document(item.job_id!)
                .updateData(["uploader" : typedName])
        }
        
    }
    
    
    func getMyJobsIfExists() -> [Job] {
        do{
            let request = Job.fetchRequest() as NSFetchRequest<Job>
           
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
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
