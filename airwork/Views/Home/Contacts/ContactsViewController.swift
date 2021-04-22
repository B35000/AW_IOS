//
//  ContactsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 01/02/2021.
//

import UIKit
import CoreData
import Firebase

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var contactsTable: UITableView!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var contacts = [Contact]()
    var my_jobs = [String]()
    let constants = Constants.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_job), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_account), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetChangeUser(_:)), name: NSNotification.Name(rawValue: constants.swapped_account_type), object: nil)
    }
    
    @objc func didGetChangeUser(_ notification: Notification){
        print("changing user account!")
        self.navigationController?.popToRootViewController(animated: true)
        updateData()
    }
    
    @objc func didGetNotification(_ notification: Notification){
        print("refreshing user!")
        
        updateData()
    }
    
    func setData(){
        contacts.removeAll()
        contacts = self.getContacts()
        print("loaded \(contacts.count) contacts to show")
        my_jobs.removeAll()
        
        if !amIAirworker(){
            let my_job_objs = self.getUploadedJobsIfExists()
            for item in my_job_objs{
                my_jobs.append(item.job_id!)
            }
        }else{
            let my_applied_jobs = self.getAppliedJobsIfExist()
            print("loaded \(my_applied_jobs.count) applications")
            for item in my_applied_jobs{
                my_jobs.append(item.job_id!)
            }
        }
        
        contactsTable.delegate = self
        contactsTable.dataSource = self
    }
    
    func updateData(){
        contacts.removeAll()
        contacts = self.getContacts()
        print("loaded \(contacts.count) contacts to show")
        my_jobs.removeAll()
        
        if !amIAirworker(){
            let my_job_objs = self.getUploadedJobsIfExists()
            for item in my_job_objs{
                my_jobs.append(item.job_id!)
            }
        }else{
            let my_applied_jobs = self.getAppliedJobsIfExist()
            print("loaded \(my_applied_jobs.count) applications")
            for item in my_applied_jobs{
                print("adding applied job: \(item.job_id!)")
                my_jobs.append(item.job_id!)
            }
        }
        
        contactsTable.reloadData()
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        //viewContact
        
        switch(segue.identifier ?? "") {
                        
        case "viewContact":
            guard let contactDetailViewController = segue.destination as? ContactDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let appItemTableViewCell = sender as? ContactTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = contactsTable.indexPath(for: appItemTableViewCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedContact = contacts[indexPath.row]
            
        
            contactDetailViewController.contact_id = selectedContact.rated_user!
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactItem") as! ContactTableViewCell
        let contact = contacts[indexPath.row]
        let account = self.getApplicantAccount(user_id: contact.rated_user!)
        
        cell.nameLabel.text = account?.name!
        let uid = contact.rated_user!
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(uid)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            cell.contactImage.image = im
              
            let image = cell.contactImage!
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
                    cell.contactImage.image = im
                    
                    let image = cell.contactImage!
                    image.layer.borderWidth = 1
                    image.layer.masksToBounds = false
                    image.layer.borderColor = UIColor.white.cgColor
                    image.layer.cornerRadius = image.frame.height/2
                    image.clipsToBounds = true
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: uid)
                }
              }
        }
        
        let ratings = self.getAccountRatings(contact.rated_user!)
        var total = 0.0
        for item in ratings {
            total += Double(item.rating)
        }
        cell.rating.text = "\(round(10 * total/Double(ratings.count))/10)"
        
        let me = Auth.auth().currentUser?.uid
        print("loading contact : \(contact.rated_user!) ratings")
        let my_received_ratings = self.getAccountRatings(contact.rated_user!)
//        var my_received_ratings = self.getAccountRatings(me!)
        if(amIAirworker()){
            let my_received_ratings = self.getAccountRatings(contact.rated_user!)
        }
        print("contacts received \(my_received_ratings.count) ratings")
        var my_ratings = [Rating]()
        
        for item in my_received_ratings{
            if my_jobs.contains(item.job_id!){
                my_ratings.append(item)
            }else{
                print("my jobs doesnt contain \(item.job_id!)")
            }
        }
        print("picked \(my_ratings.count) to show")
        
        cell.jobsDoneLabel.text = "Did \(my_ratings.count) jobs with you."
        if my_ratings.count == 1{
            cell.jobsDoneLabel.text = "Did 1 job with you."
        }
        
        cell.lastRatingLabel.text = "You last rated: \(round(10 * my_ratings.last!.rating)/10)"
        cell.lastRatingView.rating = round(10 * my_ratings.last!.rating)/10
        
        cell.lastRatingView.settings.updateOnTouch = false
        cell.lastRatingView.settings.fillMode = .precise
        
        let date = Date(timeIntervalSince1970: TimeInterval(my_ratings.last!.rating_time) / 1000)
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
            cell.contactAgeLabel.text = "\(timeOffset)."
        }else{
            cell.contactAgeLabel.text = "\(timeOffset)"
        }
        
        
        return cell
    }

    func getContacts() -> [Contact] {
        do{
            let request = Contact.fetchRequest() as NSFetchRequest<Contact>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
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
            print("loading rating : \(item.rating_id)")
            let rater_id = item.rating_id!.replacingOccurrences(of: job_id!, with: "")
            
            var req_id_format = "\(job!.uploader_id!)\(job!.job_id!)"
//            req_id_format = "\(job!.job_id!)"
            if self.amIAirworker(){
                if rater_id != ""{
                    req_id_format = "\(rater_id)\(job!.job_id!)"
                }
            }
            
//            print("Req id being used : \(req_id_format)")
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
    
    func getApplicantAccount(user_id: String) -> Account? {
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
    
    func getUploadedJobsIfExists() -> [UploadedJob] {
        do{
            let request = UploadedJob.fetchRequest() as NSFetchRequest<UploadedJob>
            let sortDesc = NSSortDescriptor(key: "upload_time", ascending: false)
            request.sortDescriptors = [sortDesc]
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
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
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getAppliedJobsIfExist() -> [AppliedJob] {
        do{
            let request = AppliedJob.fetchRequest() as NSFetchRequest<AppliedJob>
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
}
