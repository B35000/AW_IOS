//
//  AllApplicantsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 22/01/2021.
//

import UIKit
import CoreData
import Firebase

class AllApplicantsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var applicantsTableView: UITableView!
    var constants = Constants.init()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var applicants = [JobApplicant]()
    var job_id = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        applicants = getJobApplicantsIfExists(job_id: job_id)
        
        applicantsTableView.delegate = self
        applicantsTableView.dataSource = self
        
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        //viewPickedApplicant
        
        switch(segue.identifier ?? "") {
                        
        case "viewPickedApplicant":
            guard let applicantDetailViewController = segue.destination as? ApplicantViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let appItemTableViewCell = sender as? ApplicantTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = applicantsTableView.indexPath(for: appItemTableViewCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedApplicant = applicants[indexPath.row]
            
            applicantDetailViewController.job_id = selectedApplicant.job_id!
            applicantDetailViewController.applicant_id = selectedApplicant.applicant_uid!
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        applicants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "applicantItemCell", for: indexPath) as! ApplicantTableViewCell
        let job_applicant = applicants[indexPath.row]
        let user_applicant = getApplicantAccount(job_applicant.applicant_uid!)!
        
        cell.applicantNameLabel.text = user_applicant.name!
        var app_date = Date(timeIntervalSince1970: TimeInterval(job_applicant.application_time) / 1000)
    
        var timeOffset = app_date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: app_date)
            cell.applicationTimeLabel.text = "\(timeOffset)."
        }else{
            cell.applicationTimeLabel.text = "\(timeOffset)"
        }
        
        //set their ratings
        var ratings = self.getAccountRatings(user_applicant.uid!)
        
        cell.applicantRatingsLabel.text = "\(ratings.count) Ratings."
        if ratings.count == 1 {
            cell.applicantRatingsLabel.text = "\(ratings.count) Rating."
        }else if ratings.count == 0 {
            cell.applicantRatingsLabel.text = "New!"
        }
        
        //set their application amount
        let job = getJobIfExists(job_id: job_id)
        if job_applicant.application_pay_currency != nil {
            if job_applicant.application_pay_amount != job!.pay_amount {
                cell.amountLabel.text = "For  \(job_applicant.application_pay_currency!)  \(job_applicant.application_pay_amount)"
                cell.amountLabel.textColor = UIColor(named: "CustomAmountColor")
            }else{
                cell.amountLabel.text = "For your amount."
                cell.amountLabel.textColor = UIColor.secondaryLabel
            }
        }else{
            cell.amountLabel.text = "For your amount."
            cell.amountLabel.textColor = UIColor.secondaryLabel
        }
        
        let uid = job_applicant.applicant_uid!
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(uid)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            cell.applicantImageView.image = im
              
            let image = cell.applicantImageView!
            image.layer.borderWidth = 1
            image.layer.masksToBounds = false
            image.layer.borderColor = UIColor.white.cgColor
            image.layer.cornerRadius = image.frame.height/2
            image.clipsToBounds = true
        }else{
            ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                  // Uh-oh, an error occurred!
                    print("loading image from cloud failed")
                } else {
                  // Data for "images/island.jpg" is returned
                  let im = UIImage(data: data!)
                    cell.applicantImageView.image = im
                    
                    let image = cell.applicantImageView!
                    image.layer.borderWidth = 1
                    image.layer.masksToBounds = false
                    image.layer.borderColor = UIColor.white.cgColor
                    image.layer.cornerRadius = image.frame.height/2
                    image.clipsToBounds = true
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: uid)
                }
              }
        }
        
        var selected_users_json = job!.selected_workers
        let decoder = JSONDecoder()
        
        
        do{
            var selected_users = selected_workers()
            
            if selected_users_json != nil && selected_users_json != "" {
                let jsonData = selected_users_json!.data(using: .utf8)!
                selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
            }
            
            if selected_users.worker_list.contains(job_applicant.applicant_uid!){
                cell.selectedLabel.isHidden = false
                cell.selectedApplicantImage.isHidden = false
                
                let my_id = Auth.auth().currentUser?.uid
                for item in ratings{
                    if (item.job_id! == job_id){
                        print("changin selected word with \(item.rating)")
                        cell.selectedLabel.text = "Rated: \(round(10 * item.rating)/10)"
                        break
                    }
                }
            }else{
                cell.selectedLabel.isHidden = true
                cell.selectedApplicantImage.isHidden = true
                
                let my_id = Auth.auth().currentUser?.uid
                let ratings = getAccountRatings(my_id!)
                for item in ratings{
                    if item.user_id! == job_applicant.applicant_uid!{
                        cell.selectedLabel.isHidden = false
                        cell.selectedLabel.text = "You last rated: \(round(10 * item.rating)/10)"
                        break
                    }
                }
                
            }
        
        }catch{
            print("error loading selected users")
        }
        
        return cell
    }
    
    struct selected_workers: Codable{
        var worker_list = [String]()
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
    
    func getJobApplicantsIfExists(job_id: String) -> [JobApplicant]{
        do{
            let request = JobApplicant.fetchRequest() as NSFetchRequest<JobApplicant>
            
            let predic = NSPredicate(format: "job_id == %@", job_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
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
    
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }

}
