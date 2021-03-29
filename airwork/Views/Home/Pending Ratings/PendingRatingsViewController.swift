//
//  PendingRatingsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 13/02/2021.
//

import UIKit
import CoreData
import Firebase

class PendingRatingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var myJobs = [Job]()
    var my_jobs = [String]()
    var constants = Constants.init()
    let db = Firestore.firestore()
    
    @IBOutlet weak var pendingJobsTableView: UITableView!
    @IBOutlet weak var skipBarButton: UIBarButtonItem!
    @IBOutlet weak var openNewJobPart: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        resetUpViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_job), object: nil)
        
    }
    
    @objc func didGetNotification(_ notification: Notification){
        print("refreshing job!")
        resetUpViews()
    }
    
    func resetUpViews(){
        getPendingJobs()
        if !myJobs.isEmpty{
            pendingJobsTableView.delegate = self
            pendingJobsTableView.dataSource = self
        }else{
            //just go back
//            self.navigationController?.popViewController(animated: true)
            
            openNewJobPart.sendActions(for: .touchUpInside)
            self.navigationController?.popViewController(animated: false)
        }
    }
    
    func getPendingJobs(){
        let my_uploaded_jobs = self.getUploadedJobsIfExists()
        let my_applied_jobs = self.getAppliedJobsIfExists()
        myJobs.removeAll()
        
        if amIAirworker(){
            for applied_job in my_applied_jobs{
                let job = self.getJobIfExists(job_id: applied_job.job_id!)
                
                if (job != nil) {
                    //lets check if the jobs end date has past
                    let today = Date()
                    
                    let end_date = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day)).date!
                    
                    //compare the two dates
                    
                    
                    var selected_users_json = job!.selected_workers ?? ""
                    if (selected_users_json != "" && end_date < today) {
            //            selected_users_json = job!.selected_workers!
                        let decoder = JSONDecoder()
                        let jsonData = selected_users_json.data(using: .utf8)!
                        
                        do{
                            var selected_users = selected_workers()
                            
                            if selected_users_json != "" {
                                selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                            }
                            
                            if !selected_users.worker_list.isEmpty {
                                let me = Auth.auth().currentUser?.uid
                                
                                if selected_users.worker_list.contains(me!){
                                    var rating_id = me!+job!.job_id!
                                    
                                    var existing_rating = self.getRatingIfExists(rating_id: rating_id)
                                    if existing_rating == nil {
                                        //the applicant was chosen but has not been rated
                                        if(!job!.ignore_unrated_workers){
                                            myJobs.append(job!)
                                        }
                                    }
                                }
                                
                            }
                            
                        }catch{
                            print("error loading selected users")
                        }
                    }
                }
            }
        }else{
        
            for uploaded_job in my_uploaded_jobs{
                let job = self.getJobIfExists(job_id: uploaded_job.job_id!)
                
                if (job != nil) {
                    //lets check if the jobs end date has past
                    let today = Date()
                    
                    let end_date = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day)).date!
                    
                    //compare the two dates
                    
                    
                    var selected_users_json = job!.selected_workers ?? ""
                    if (selected_users_json != "" && end_date < today) {
            //            selected_users_json = job!.selected_workers!
                        let decoder = JSONDecoder()
                        let jsonData = selected_users_json.data(using: .utf8)!
                        
                        do{
                            var selected_users = selected_workers()
                            
                            if selected_users_json != "" {
                                selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                            }
                            
                            if !selected_users.worker_list.isEmpty {
                                for user in selected_users.worker_list{
                                    var rating_id = user+job!.job_id!
                                    
                                    var existing_rating = self.getRatingIfExists(rating_id: rating_id)
                                    if existing_rating == nil {
                                        //the applicant was chosen but has not been rated
                                        if(!job!.ignore_unrated_workers){
                                            myJobs.append(job!)
                                        }
                                    }
                                    else{
    //                                    if(!job!.ignore_unrated_workers){
    //                                        myJobs.append(job!)
    //                                    }
                                    }
                                }
                                
                            }
                            
                        }catch{
                            print("error loading selected users")
                        }
                    }
                }
                
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        myJobs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PendingRatingItem", for: indexPath) as! PendingRatingTableViewCell
        
        let job = myJobs[indexPath.row]
        let job_id = job.job_id!
        
        for tag in job.tags! {
            cell.jobTags.append(tag as! JobTag)
        }
        cell.jobTitleLabel.text = job.job_title!
        
        let date = DateComponents(calendar: .current, year: Int(job.start_year), month: Int(job.start_month)+1, day: Int(job.start_day), hour: Int(job.time_hour), minute: Int(job.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job.end_year), month: Int(job.end_month)+1, day: Int(job.end_day), hour: Int(job.time_hour), minute: Int(job.time_minute)).date!
        
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
            cell.jobStartDateLabel.text = "\(timeOffset) ago."
        }else{
            cell.jobStartDateLabel.text = "In \(timeOffset)"
        }
        
        cell.amountView.isHidden = false
        cell.jobAmountLabel.text = "\(job.pay_currency!) \(job.pay_amount) Qouted."
        if job.pay_amount == 0 {
            cell.jobAmountLabel.text = ""
            cell.amountView.isHidden = true
        }
        
//        cell.jobTimeLabel.text = "At \(job.time_hour):\(job.time_minute)\(self.gett("a", date))"
        
        var job_views = self.getJobViewsIfExists(job_id: job.job_id!)
        var applicants = self.getJobApplicantsIfExists(job_id: job.job_id!)
        
        if job.job_title == "Food" {
            print("\(job_views.count) job views for: \(job.job_title!)")
        }
        
        var t = ""
        var a = ""
        
        if !job_views.isEmpty{
            t = "\(job_views.count) views"
            if job_views.count == 1 {
                t = "1 view"
            }
        }
        
        if !applicants.isEmpty{
            a = "\(applicants.count) applicants"
            if applicants.count == 1 {
                a = "1 applicant"
            }
        }
        
        let views_applicants = "\(t) \(a)"
        
        cell.jobTimeLabel.text = views_applicants
        
        
        if job.work_duration == "" {
            timeOffset = end_date.offset(from: date)
            if timeOffset == "" {
                timeOffset = date.offset(from: end_date)
            }
            cell.duration.text = "\(timeOffset)"
            
        }else{
            if job.work_duration == self.constants.durationless {
                cell.duration.text = " "
            }else{
                cell.duration.text = "\(job.work_duration!)"
            }
            
        }
        
        if (job_views.isEmpty && applicants.isEmpty){
            cell.timeDurationView.isHidden = true
        }else{
            cell.timeDurationView.isHidden = false
        }
        
//        cell.takenDownImage.isHidden = !job.taken_down
        
        
        //only first unrated applicant
        var user =  self.getFirstUnratedUser(job: job)
        
        cell.setRatingView.settings.fillMode = .precise
        cell.setRatingView.didTouchCosmos = { rating in
            cell.ratingLabel.text = "\(round(10 * rating)/10)"
            
        }
        
        
        var account = self.getApplicantAccount(user_id: user)
        var rating_id = user+job_id
        var existing_rating = self.getRatingIfExists(rating_id: rating_id)
        var account_ratings = self.getAccountRatings(user)
        
        cell.ratingLabel.text = "4.0"
        cell.setRatingView.rating = 4.0
        
        if existing_rating != nil{
            print("loaded a rating: \(round(10 * existing_rating!.rating)/10)")
            cell.setRatingView.rating = round(10 * existing_rating!.rating)/10
            cell.ratingLabel.text = "\(round(10 * existing_rating!.rating)/10)"
            cell.removeButton.isHidden = false
        }else{
            cell.removeButton.isHidden = true
        }
        
        cell.nameLabel.text = account?.name!
        cell.ratingsLabel.text = "\(account_ratings.count) Ratings."
        if account_ratings.count == 1 {
            cell.ratingsLabel.text = "\(account_ratings.count) Rating."
        }else if account_ratings.count == 0 {
            cell.ratingsLabel.text = "New!"
        }
        
        cell.whenCancelTapped = {
            print("remove item \(indexPath.row)")
            cell.removeButton.isHidden = true
            self.delete_rating(user, job_id: job_id)
            self.context.delete(existing_rating!)
            
            NotificationCenter.default.post(name: NSNotification.Name(self.constants.refresh_job), object: "listener")
        }
        
        
        
        cell.whenViewAllTapped = {
            print("open all the other picked applicants")
        }
        
//        if amIAirworker() {
//            if existing_rating == nil {
//                cell.removeButton.isHidden = true
//            }else{
//                cell.removeButton.isHidden = false
//            }
//        }else{
//            if(self.getNumberOfSelectedUnratedUsers(job: job) > 1){
//                cell.removeButton.isHidden = false
//            }else{
//                cell.removeButton.isHidden = true
//            }
//        }
        
        cell .whenSetTapped = {
            self.set_rating(job_id: job_id, applicant: user, rating: round(10 * cell.setRatingView.rating)/10)
        }
        
        let uid = user
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(uid)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            cell.userImageView.image = im
            
            let image = cell.userImageView!
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
                    cell.userImageView.image = im
                    
                    let image = cell.userImageView!
                    image.layer.borderWidth = 1
                    image.layer.masksToBounds = false
                    image.layer.borderColor = UIColor.white.cgColor
                    image.layer.cornerRadius = image.frame.height/2
                    image.clipsToBounds = true
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: uid)
                }
              }
        }
        
        ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
              // Uh-oh, an error occurred!
                print("loading image from cloud failed")
            } else {
              // Data for "images/island.jpg" is returned
              let im = UIImage(data: data!)
                cell.userImageView.image = im
                
                let image = cell.userImageView!
                image.layer.borderWidth = 1
                image.layer.masksToBounds = false
                image.layer.borderColor = UIColor.white.cgColor
                image.layer.cornerRadius = image.frame.height/2
                image.clipsToBounds = true
            }
          }
        
        cell.whenCancelTapped = {
            print("cancel rating user!")
        }
        
        cell.whenSetTapped = {
            print("Set rating user!")
        }
        
        job.ignore_unrated_workers = true
        do{
            try context.save()
        }catch{
            
        }
        
        return cell
    }
    
    
    
    func getFirstUnratedUser(job: Job) -> String{
        
        if amIAirworker(){
            return job.uploader_id!
        }
        
        var selected_users_json = job.selected_workers ?? ""
        if selected_users_json != "" {
//            selected_users_json = job!.selected_workers!
            let decoder = JSONDecoder()
            let jsonData = selected_users_json.data(using: .utf8)!
            
            do{
                var selected_users = selected_workers()
                
                if selected_users_json != "" {
                    selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                }
                
                if !selected_users.worker_list.isEmpty {
                    for user in selected_users.worker_list{
                        var rating_id = user+job.job_id!
                        
                        var existing_rating = self.getRatingIfExists(rating_id: rating_id)
                        if existing_rating == nil {
                            //the applicant was chosen but has not been rated
                            return user
                        }
//                        else{
//                            return user
//                        }
                    }
                    
                }
                
            }catch{
                print("error loading selected users")
            }
        }
        
        return ""
    }
    
    func getNumberOfSelectedUnratedUsers(job: Job) -> Int{
        if amIAirworker(){
            return 1
        }
        var selected_users_json = job.selected_workers ?? ""
        if selected_users_json != "" {
//            selected_users_json = job!.selected_workers!
            let decoder = JSONDecoder()
            let jsonData = selected_users_json.data(using: .utf8)!
            
            do{
                var selected_users = selected_workers()
                
                if selected_users_json != "" {
                    selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                }
                
                if !selected_users.worker_list.isEmpty {
                    return selected_users.worker_list.count
                    
                }
                
            }catch{
                print("error loading selected users")
            }
        }
        
        return 0
    }
    
    // MARK: - Update Ratings
    
    func delete_rating(_ applicant: String, job_id: String){
        showLoadingScreen()
        
        let jobbo = jobAsInCodable(job_id)
        let job_ob = self.getJobIfExists(job_id: job_id)
        let t_mills = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        
        if amIAirworker(){
            let uploader_id = job_ob!.uploader_id!
            var my_id = Auth.auth().currentUser!.uid
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.all_my_ratings)
                .document(my_id+job_id).delete()
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.employee_ratings)
                .document(job_id)
                .collection(constants.employee_ratings)
                .document(my_id)
                .delete()
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.employee_ratings)
                .document(job_id)
                .setData([
                    "rated_job" : job_id,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.airworkers_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(uploader_id)
                .collection(constants.contact_ratings)
                .document(job_id)
                .delete()
            
            db.collection(constants.airworkers_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(uploader_id)
                .setData([
                    "rated_user" : uploader_id,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.jobs_ref)
                .document(jobbo.country_name)
                .collection(constants.country_jobs)
                .document(jobbo.job_id)
                .collection(constants.employer_rating)
                .document(my_id)
                .delete(){ err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                        
                        self.hideLoadingScreen()
                    }
                    
                }
        }else{
            var my_id = Auth.auth().currentUser!.uid
            
            db.collection(constants.airworkers_ref)
                .document(applicant)
                .collection(constants.all_my_ratings)
                .document(my_id+job_id).delete()
            
            db.collection(constants.airworkers_ref)
                .document(applicant)
                .collection(constants.my_job_ratings)
                .document(job_id).delete()
            
            db.collection(constants.users_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(applicant)
                .setData([
                    "rated_user" : applicant,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.users_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(applicant)
                .collection(constants.contact_ratings)
                .document(job_id)
                .delete()
            
            db.collection(constants.jobs_ref)
                .document(jobbo.country_name)
                .collection(constants.country_jobs)
                .document(jobbo.job_id)
                .collection(constants.worker_ratings)
                .document(applicant)
                .delete(){ err in
                    if let err = err {
                        print("Error removing document: \(err)")
                    } else {
                        print("Document successfully removed!")
                        
                        self.hideLoadingScreen()
                        
                    }
                    
                }
        }
    }
    
    func set_rating(job_id: String, applicant: String, rating: Double){
        showLoadingScreen()
        
        let jobbo = jobAsInCodable(job_id)
        let job_ob = self.getJobIfExists(job_id: job_id)
        let t_mills = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        var job_json = ""
        var tag_associates = ""
        let encoder = JSONEncoder()
        
        var job_tag_list = jobtaglist()
        job_tag_list.tags = jobbo.selected_tags
        
        do {
            let json_string = try encoder.encode(jobbo)
            let tags_json = try encoder.encode(job_tag_list)
            
            job_json = String(data: json_string, encoding: .utf8)!
            tag_associates = String(data: tags_json, encoding: .utf8)!
        }catch {
           print("error encoding job")
        }
        
        let app_acc = self.getApplicantAccount(user_id: applicant)
        
        let data: [String : Any] = [
            "rating": rating,
            "rating_explanation": "",
            "user_id" : applicant,
            "job_country" : jobbo.country_name,
            "job_id" : job_id,
            "rating_time" : t_mills,
            "job_object" : job_json,
            "language" : jobbo.language
        ]
        
        if amIAirworker(){
            let job = job_ob
            let job_owner_acc = self.getApplicantAccount(user_id: job!.uploader_id!)
            let uploader_id = job!.uploader_id!
            var my_id = Auth.auth().currentUser!.uid
            
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.all_my_ratings)
                .document(my_id+job_id).setData(data)
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.employee_ratings)
                .document(job_id)
                .collection(constants.employee_ratings)
                .document(my_id)
                .setData(data)
            
            db.collection(constants.users_ref)
                .document(uploader_id)
                .collection(constants.employee_ratings)
                .document(job_id)
                .setData([
                    "rated_job" : job_id,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.airworkers_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(uploader_id)
                .collection(constants.contact_ratings)
                .document(job_id)
                .setData(data)
            
            db.collection(constants.airworkers_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(uploader_id)
                .setData([
                    "rated_user" : uploader_id,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.jobs_ref)
                .document(jobbo.country_name)
                .collection(constants.country_jobs)
                .document(jobbo.job_id)
                .collection(constants.employer_rating)
                .document(my_id)
                .setData(data){ err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                        
                        self.hideLoadingScreen()
                    }
                    
                }
        }else{
            var my_id = Auth.auth().currentUser!.uid
            
            db.collection(constants.airworkers_ref)
                .document(applicant)
                .collection(constants.all_my_ratings)
                .document(my_id+job_id).setData(data)
            
            db.collection(constants.airworkers_ref)
                .document(applicant)
                .collection(constants.my_job_ratings)
                .document(job_id).setData(data)
            
            db.collection(constants.users_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(applicant)
                .setData([
                    "rated_user" : applicant,
                    "last_update" : t_mills
                ])
            
            db.collection(constants.users_ref)
                .document(my_id)
                .collection(constants.my_contacts)
                .document(applicant)
                .collection(constants.contact_ratings)
                .document(job_id)
                .setData(data)
            
            db.collection(constants.jobs_ref)
                .document(jobbo.country_name)
                .collection(constants.country_jobs)
                .document(jobbo.job_id)
                .collection(constants.worker_ratings)
                .document(applicant)
                .setData(data){ err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                        self.hideLoadingScreen()
                    }
                    
                }
        }
        
        print("updated rating objects for each user")
        
        let job = job_ob
        
        let date = DateComponents(calendar: .current, year: Int(job!.start_year), month: Int(job!.start_month)+1, day: Int(job!.start_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: end_date)
        
        print("updating global tag data now")
        for tag in jobbo.selected_tags{
            if jobbo.pay.amount != 0{
                let pay: [String: Any] = [
                    "amount" : jobbo.pay.amount,
                    "currency" : jobbo.pay.currency
                ]
                
                let location: [String: Any] = [
                    "latitude" : jobbo.location_set.latitude,
                    "longitude" : jobbo.location_set.longitude,
                    "description" : jobbo.location_set.description
                ]
                
                var data: [String: Any] = [
                    "job_id" : job_id,
                    "pay" : pay,
                    "work_duration" : jobbo.work_duration,
                    "no_of_days" : components.day ?? 0,
                    "location" : location,
                    "record_time" : t_mills,
                    "tag_associates" : tag_associates
                ]
                
                db.collection(constants.jobs_ref)
                    .document(job!.country_name!)//making sure its country specific so they share the same currency
                    .collection(constants.tags)
                    .document(tag.tag_title)
                    .setData([
                        "title" : tag.tag_title,
                        "last_update" : t_mills
                    ])
                
                db.collection(constants.jobs_ref)
                    .document(job!.country_name!)//making sure its country specific so they share the same currency
                    .collection(constants.tags)
                    .document(tag.tag_title)
                    .collection(constants.its_jobs)
                    .document(job!.job_id!)
                    .setData(data)
            }
        }
    }
    
    func jobAsInCodable(_ job_id: String) -> encodable_job{
        let job = self.getJobIfExists(job_id: job_id)
        
        var enc_job = encodable_job()
        enc_job.job_title = job!.job_title!
        enc_job.job_details = job!.job_details!
        enc_job.job_worker_count = Int(job!.job_worker_count)
        
        var jobTags = [JobTag]()
        
        for tag in job!.tags! {
            jobTags.append(tag as! JobTag)
        }
        
        for item in jobTags{
            var jobtags = jobtag()
            jobtags.tag_title = item.title!
            jobtags.no_of_days = Int(item.no_of_days)
            jobtags.tag_class = "custom"
            jobtags.work_duration = item.work_duration ?? ""
            enc_job.selected_tags.append(jobtags)
        }
        
        enc_job.work_duration = job!.work_duration!
        
        var start_date = myDate()
        start_date.day = Int(job!.start_day)
        start_date.month = Int(job!.start_month)
        start_date.month_of_year = job!.start_month_of_year!
        start_date.year = Int(job!.start_year)
        start_date.day_of_week = job!.start_day_of_week!
        
        enc_job.start_date = start_date
        
        var end_date = myDate()
        end_date.day = Int(job!.end_day)
        end_date.month = Int(job!.end_month)
        end_date.month_of_year = job!.end_month_of_year!
        end_date.year = Int(job!.end_year)
        end_date.day_of_week = job!.end_day_of_week!
        
        enc_job.end_date = end_date
        
        var time = Time()
        time.am_pm = job!.am_pm!
        time.hour = Int(job!.time_hour)
        time.minute = Int(job!.time_minute)
        
        enc_job.time = time
        enc_job.is_asap = job!.is_asap
        
        var location = myLocation()
        location.latitude = job!.location_lat
        location.longitude = job!.location_long
        location.description = job!.location_desc!
        
        enc_job.location_set = location
        
        var pay = Pay()
        pay.amount = Int(job!.pay_amount)
        pay.currency = job!.pay_currency!
        
        enc_job.pay = pay
        enc_job.country_name = job!.country_name!
        enc_job.country_name_code = job!.country_name_code!
        enc_job.language = job!.language!
        enc_job.upload_time = Int(job!.upload_time)
        enc_job.job_id = job!.job_id!
        
        var uploader = Uploader()
        uploader.name = job!.uploader_name!
        uploader.id = job!.uploader_id!
        uploader.email = job!.uploader_email!
        
        var my_id = Auth.auth().currentUser!.uid
        var me = self.getApplicantAccount(user_id: my_id)
        uploader.number = Int(me!.phone!.digit_number)
        uploader.country_code = job!.uploader_phone_number_code!
        enc_job.uploader = uploader
        
        return enc_job
    }
    
    struct encodable_job: Codable{
        var job_title = ""
        var job_details = ""
        var job_worker_count = 0
        var selected_tags: [jobtag] = []
        var work_duration: String = ""
        var start_date: myDate = myDate()
        var end_date: myDate = myDate()
        var time: Time = Time()

        var is_asap = false
        var location_set = myLocation()
        var pay = Pay()
        var country_name = ""
        var country_name_code = ""
        var language = ""
        var upload_time = 0
        var job_id = ""
        var uploader = Uploader()
    }
    
    struct jobtag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
    }
    
    struct jobtaglist: Codable{
        var tags = [jobtag]()
    }
    
    struct myDate: Codable{
        var day = 0
        var month = 0
        var year = 0
        var day_of_week = ""
        var month_of_year = ""
    }
    
    struct Time: Codable{
        var hour = 0
        var minute = 0
        var am_pm = ""
    }
    
    struct myLocation: Codable{
        var latitude = 0.0
        var longitude = 0.0
        var description = ""
    }
    
    struct Pay: Codable{
        var amount = 0
        var currency = ""
    }
    
    struct Uploader: Codable{
        var id = ""
        var email = ""
        var name = ""
        var number = 0
        var country_code = ""
    }
    
    
    
    
    
    // MARK: - Core Data Functions
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
    
    func getRatingIfExists(rating_id: String) -> Rating? {
        do{
            let request = Rating.fetchRequest() as NSFetchRequest<Rating>
            let predic = NSPredicate(format: "rating_id == %@", rating_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getJobViewsIfExists(job_id: String) -> [JobView]{
        do{
            let request = JobView.fetchRequest() as NSFetchRequest<JobView>
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
    
    func getAppliedJobsIfExists() -> [AppliedJob] {
        do{
            let request = AppliedJob.fetchRequest() as NSFetchRequest<AppliedJob>
            let sortDesc = NSSortDescriptor(key: "application_time", ascending: false)
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
