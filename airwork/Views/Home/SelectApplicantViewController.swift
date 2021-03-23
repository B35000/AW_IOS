//
//  SelectApplicantViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 23/01/2021.
//

import UIKit
import CoreData
import Firebase

class SelectApplicantViewController: UIViewController {
    @IBOutlet weak var confirmMessageLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var applicationAgeLabel: UILabel!
    @IBOutlet weak var ratingsLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var applicantImageView: UIImageView!
    
    
    var applicant_id = ""
    var job_id: String = ""
    var constants = Constants.init()
    let db = Firestore.firestore()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        var theirAcc = self.getApplicantAccount(applicant_id)
        var theApplication = self.getJobApplicantIfExists(job_id, applicant_id)
        let job = self.getJobIfExists(job_id: job_id)
        
        var selected_users_json = job!.selected_workers
        let decoder = JSONDecoder()
        var selected_users = selected_workers()
        
        do{
            if selected_users_json != nil && selected_users_json != "" {
                let jsonData = selected_users_json!.data(using: .utf8)!
                selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
            }
            
            if selected_users.worker_list.contains(applicant_id){
                confirmMessageLabel.text = "Remove \(theirAcc!.name!) from doing your job?"
                
            }else{
                confirmMessageLabel.text = "Are you sure you want to add \(theirAcc!.name!) to do your job?"

            }
        
        }catch{
            print("error loading selected users")
        }
        
        
        //set the applicants name
        nameLabel.text = theirAcc!.name
        
        var app_date = Date(timeIntervalSince1970: TimeInterval(theApplication!.application_time) / 1000)
    
        var timeOffset = app_date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: app_date)
            applicationAgeLabel.text = "\(timeOffset)."
        }else{
            applicationAgeLabel.text = "\(timeOffset)"
        }
        
        var ratings = self.getAccountRatings(theirAcc!.uid!)
        
        //set the applicants number of ratings
        ratingsLabel.text = "\(ratings.count) Ratings."
        if ratings.count == 1 {
            ratingsLabel.text = "\(ratings.count) Rating."
        }else if ratings.count == 0 {
            ratingsLabel.text = "New!"
        }
        
        //set their application amount
    
        if theApplication!.application_pay_amount != job!.pay_amount {
            amountLabel.text = "For  \(theApplication!.application_pay_currency!)  \(theApplication!.application_pay_amount)"
            amountLabel.textColor = UIColor(named: "CustomAmountColor")
        }else{
            amountLabel.text = "For your amount."
            amountLabel.textColor = UIColor.secondaryLabel
        }
                
        let uid = theApplication!.applicant_uid!
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(uid)
            .child("avatar.jpg")
        
        ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
              // Uh-oh, an error occurred!
                print("loading image from cloud failed")
            } else {
              // Data for "images/island.jpg" is returned
              let im = UIImage(data: data!)
                self.applicantImageView.image = im
                
                let image = self.applicantImageView!
                image.layer.borderWidth = 1
                image.layer.masksToBounds = false
                image.layer.borderColor = UIColor.white.cgColor
                image.layer.cornerRadius = image.frame.height/2
                image.clipsToBounds = true
            }
          }
    }
    
    struct selected_workers: Codable{
        var worker_list = [String]()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func whenConfirmTapped(_ sender: UIBarButtonItem) {
        self.showLoadingScreen()
        var theirAcc = self.getApplicantAccount(applicant_id)
        var theApplication = self.getJobApplicantIfExists(job_id, applicant_id)
        let job = self.getJobIfExists(job_id: job_id)
        
        var selected_users_json = job!.selected_workers
        let decoder = JSONDecoder()
        var selected_users = selected_workers()
        
        do{
            if selected_users_json != nil && selected_users_json != "" {
                let jsonData = selected_users_json!.data(using: .utf8)!
                selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
            }
            
            if !selected_users.worker_list.contains(applicant_id){
                selected_users.worker_list.append(applicant_id)
            }else{
                var pos = selected_users.worker_list.firstIndex(of: applicant_id)!
                selected_users.worker_list.remove(at: pos)
            }
            
            //encode the new  selected users array
            var new_selected_users_json = ""
            let encoder = JSONEncoder()
            let selected_users_string = try encoder.encode(selected_users)
            new_selected_users_json = String(data: selected_users_string, encoding: .utf8)!
            
            //update the new selected users in db
            let uid = Auth.auth().currentUser!.uid
            let me = self.getAccountIfExists(uid: uid)
            
            let ref = db.collection(constants.airworkers_ref)
                .document(applicant_id)
                .collection(constants.notifications)
                .document()
            let upload_time = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
            var message = "\(me!.name!) has selected you to do a job."
            if !selected_users.worker_list.contains(applicant_id){
                message = "\(me!.name!) has removed you from a job."
            }
            ref.setData([
                "message" : message,
                "time" : upload_time,
                "user_name" : me!.name!,
                "user_id" : applicant_id,
                "job_id" : job!.job_id!,
                "notif_id" : ref.documentID
            ])
            
            
            db.collection(constants.jobs)
                .document(job!.country_name!)
                .collection("country_jobs")
                .document(job!.job_id!)
                .updateData([
                    "selected_workers" : new_selected_users_json
                ]){ err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                        self.hideLoadingScreen()
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                }
        
        }catch{
            print("error loading selected users")
        }
        
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
    
    func getAccountRatings(_ user_id: String) -> [Rating] {
        do{
            let request = Rating.fetchRequest() as NSFetchRequest<Rating>
            
            let predic = NSPredicate(format: "rated_user_id == %@", user_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return filterRatings(ratings: items)
            }
            
        }catch {
            
        }
        
        return []
    }
    
    func filterRatings(ratings: [Rating]) -> [Rating] {
        var filtered_items = [Rating]()
        
        for item in ratings {
            let job_id = item.job_id
            let job = self.getJobIfExists(job_id: job_id!)
            
            let req_id_format = "\(job!.uploader_id!)\(job!.job_id!)"
            if item.rating_id! == req_id_format{
                filtered_items.append(item)
            }
        }
        
        return filtered_items
    }
    
    func getJobIfExists(job_id: String) -> Job? {
        do{
            let request = Job.fetchRequest() as NSFetchRequest<Job>
            let predic = NSPredicate(format: "job_id == %@", job_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getJobApplicantIfExists(_ job_id: String,_ applicant_id: String) -> JobApplicant?{
        do{
            let request = JobApplicant.fetchRequest() as NSFetchRequest<JobApplicant>
            
            let predic = NSPredicate(format: "job_id == %@", job_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                for item in items {
                    if item.applicant_uid == applicant_id {
                        return item
                    }
                }
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
    
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
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
