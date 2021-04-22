//
//  ContactDetailViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 02/02/2021.
//

import UIKit
import Cosmos
import CoreData
import Firebase

class ContactDetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var completedNumberLabel: UILabel!
    @IBOutlet weak var jobsLabel: UILabel!
    @IBOutlet weak var ratedLabel: UILabel!
    @IBOutlet weak var lastThreeNumberLabel: UILabel!
    @IBOutlet weak var lastThreeLabel: UILabel!
    
    @IBOutlet weak var yourRatingForLabel: UILabel!
    @IBOutlet weak var inLastJobLabel: UILabel!
    @IBOutlet weak var lastRatingLabel: UILabel!
    @IBOutlet weak var lastRatingView: CosmosView!
    
    @IBOutlet weak var emailTitleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var howOthersWorkedLabel: UILabel!
    
    @IBOutlet weak var jobCardView: CardView!
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var jobDateLabel: UILabel!
    @IBOutlet weak var jobAmountLabel: UILabel!
    @IBOutlet weak var tagsCollection: UICollectionView!

    @IBOutlet weak var jobRatingView: CosmosView!
    @IBOutlet weak var jobRatingLabel: UILabel!
    @IBOutlet weak var viewJobButton: UIButton!
    
    var contact_id = ""
    var last_job_id = ""
    var my_jobs = [String]()
    var jobTags = [JobTag]()
    var constants = Constants.init()
    var db = Firestore.firestore()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        loadContactData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_job), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_account), object: nil)
    }
    
    @objc func didGetNotification(_ notification: Notification){
        print("refreshing user!")
        
        loadContactData()
    }
    
    func loadContactData(){
        my_jobs.removeAll()
        jobTags.removeAll()
        
        if self.amIAirworker(){
            let my_job_objs = self.getAppliedJobsIfExist()
            for item in my_job_objs{
                my_jobs.append(item.job_id!)
            }
        }else{
            let my_job_objs = self.getUploadedJobsIfExists()
            for item in my_job_objs{
                my_jobs.append(item.job_id!)
            }
        }
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(contact_id)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            self.contactImageView.image = im
              
            let image = self.contactImageView!
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
                    self.contactImageView.image = im
                    
                    let image = self.contactImageView!
                    image.layer.borderWidth = 1
                    image.layer.masksToBounds = false
                    image.layer.borderColor = UIColor.white.cgColor
                    image.layer.cornerRadius = image.frame.height/2
                    image.clipsToBounds = true
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: self.contact_id)
                }
              }
        }
        
        let contact_acc = self.getApplicantAccount(contact_id)!
        
        //load the contact name
        contactName.text = "\(contact_acc.name!)."
        
        //load the applicants ratings
        let ratings = getAccountRatings(contact_id)
        if ratings.isEmpty {
            ratingLabel.text = "New!"
        }else{
            ratingLabel.text = "\(ratings.count) Ratings."
            if ratings.count == 1 {
                ratingLabel.text = "1 Rating."
            }
        }
        
        //load the number of completed jobs
        completedNumberLabel.text = "\(ratings.count)"
        if ratings.count == 1 {
            jobsLabel.text = "Job"
        }
        
        //load the last 3 jobs ratings
        if ratings.isEmpty {
            ratedLabel.text = ""
            lastThreeNumberLabel.text = ""
            lastThreeLabel.text = ""
        }
        else{
            ratedLabel.text = "Rated:"
            if ratings.count > 3 {
                var last3 = Array(ratings.suffix(3))
                var total = 0.0
                for item in last3 {
                    total += Double(item.rating)
                }
                lastThreeNumberLabel.text = "\(round(10 * total/3.0)/10)"
            }else{
                //less than 3
                var total = 0.0
                for item in ratings {
                    total += Double(item.rating)
                }
                lastThreeNumberLabel.text = "\(round(10 * total/Double(ratings.count))/10)"
                lastThreeLabel.text = "Last \(ratings.count)."
            }
        }
        
        emailLabel.text = contact_acc.email!
        yourRatingForLabel.text = "Your rating for \(contact_acc.name!)"
        
        if contact_acc.gender == "Female" {
            inLastJobLabel.text = "In her last job with you"
            howOthersWorkedLabel.text = "See how others have worked with her."
        }
        
        
        let me = Auth.auth().currentUser?.uid
        
        
        let my_received_ratings = self.getAccountRatings(contact_id)
        var my_ratings = [Rating]()
        for item in my_received_ratings{
            if my_jobs.contains(item.job_id!){
                my_ratings.append(item)
            }
        }
        
        var job = getJobIfExists(job_id: my_ratings.last!.job_id!)
        
        for tag in job!.tags! {
            jobTags.append(tag as! JobTag)
        }
        
        tagsCollection.delegate = self
        tagsCollection.dataSource = self
        
        jobTitleLabel.text = job!.job_title!
        
        let date = DateComponents(calendar: .current, year: Int(job!.start_year), month: Int(job!.start_month)+1, day: Int(job!.start_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
            jobDateLabel.text = "\(timeOffset) ago."
        }else{
            jobDateLabel.text = "In \(timeOffset)"
        }
        
        jobAmountLabel.text = "\(job!.pay_currency!) \(job!.pay_amount) Quoted."
        if job!.pay_amount == 0 {
            jobAmountLabel.text = ""
        }
        
        last_job_id = job!.job_id!
        
        jobRatingView.settings.fillMode = .precise
        lastRatingView.settings.fillMode = .precise
        jobRatingView.rating = round(10 * my_ratings.last!.rating)/10
        jobRatingLabel.text = "\(round(10 * my_ratings.last!.rating)/10)"
        
        lastRatingLabel.text = "\(round(10 * my_ratings.last!.rating)/10)"
        lastRatingView.rating = round(10 * my_ratings.last!.rating)/10
        
        jobRatingView.didTouchCosmos = { rating in
            self.jobRatingLabel.text = "\(round(10 * rating)/10)"
        }
        
        jobRatingView.didFinishTouchingCosmos = { rating in
            self.lastRatingLabel.text = "\(round(10 * rating)/10)"
            self.lastRatingView.rating = round(10 * rating)/10
            
            self.jobRatingLabel.text = "\(round(10 * rating)/10)"
            self.updateRating(rating, self.last_job_id)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ContactDetailViewController.whenViewJobTapped))
        jobCardView.addGestureRecognizer(tap)
    }
    
    @objc func whenViewJobTapped(sender:UITapGestureRecognizer) {
        viewJobButton.sendActions(for: .touchUpInside)
    }
    
    func updateRating(_ rating: Double, _ job_id: String){
        let app_acc = self.getApplicantAccount(contact_id)
        let jobbo = self.getJobIfExists(job_id: job_id)!
        let t_mills = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        let data: [String : Any] = [
            "rating": rating,
        ]
        
        var my_id = Auth.auth().currentUser!.uid
        
        if amIAirworker(){
            let job_owner_acc = self.getApplicantAccount(jobbo.uploader_id!)
            let uploader_id = jobbo.uploader_id!
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.all_my_ratings)
                .document(my_id+job_id).updateData(data)
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.employee_ratings)
                .document(job_id)
                .collection(constants.employee_ratings)
                .document(my_id)
                .updateData(data)
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.employee_ratings)
                .document(job_id)
                .updateData([
                    "rated_job" : job_id,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.airworkers_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(uploader_id)
                .collection(constants.contact_ratings)
                .document(job_id)
                .updateData(data)
            
            db.collection(constants.airworkers_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(uploader_id)
                .updateData([
                    "rated_user" : uploader_id,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.jobs_ref)
                .document(jobbo.country_name!)
                .collection(constants.country_jobs)
                .document(jobbo.job_id!)
                .collection(constants.employer_rating)
                .document(my_id)
                .updateData(data){ err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                    }
                    
                }
        }else{
        
            db.collection(constants.airworkers_ref)
                .document(contact_id)
                .collection(constants.all_my_ratings)
                .document(my_id+job_id).updateData(data)
            
            db.collection(constants.airworkers_ref)
                .document(contact_id)
                .collection(constants.my_job_ratings)
                .document(job_id).updateData(data)
            
            db.collection(constants.users_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(contact_id)
                .updateData([
                    "rated_user" : contact_id,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.users_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(contact_id)
                .collection(constants.contact_ratings)
                .document(job_id)
                .updateData(data)
            
            db.collection(constants.jobs_ref)
                .document(jobbo.country_name!)
                .collection(constants.country_jobs)
                .document(jobbo.job_id!)
                .collection(constants.worker_ratings)
                .document(contact_id)
                .updateData(data){ err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                    }
                    
                }
            
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch(segue.identifier ?? "") {
                        
        case "viewContact":
            guard let contactDetailViewController = segue.destination as? ContactDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }

        case "viewJobDetails":
            guard let jobDetailViewController = segue.destination as? JobDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            jobDetailViewController.job_id = last_job_id
            
        case "viewContactRatingsSegue":
            guard let jobHistoryViewController = segue.destination as? JobHistoryViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            jobHistoryViewController.applicant_id = contact_id
            jobHistoryViewController.job_id = last_job_id
            
        case "viewContactsJobsSegue":
            guard let jobsViewController = segue.destination as? JobsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            jobsViewController.contact_id = contact_id
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        jobTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "TakeDownJobTagCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TakeDownTagCollectionViewCell
        
        let tag = jobTags[indexPath.row]
        
        cell.titleLabel.text = tag.title
        
        return cell
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
            let rater_id = item.rating_id!.replacingOccurrences(of: job_id!, with: "")
            
            var req_id_format = "\(job!.uploader_id!)\(job!.job_id!)"
//            req_id_format = "\(job!.job_id!)"
            if self.amIAirworker(){
                if rater_id != ""{
                    req_id_format = "\(rater_id)\(job!.job_id!)"
                }
            }
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
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }

    
}
