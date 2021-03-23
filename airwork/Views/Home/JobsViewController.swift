//
//  JobsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 10/01/2021.
//

import UIKit
import CoreData
import Firebase

class JobsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var jobsTableView: UITableView!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var myJobs = [Job]()
    var my_jobs = [String]()
    var constants = Constants.init()
    var contact_id = ""
    var viewAppliedJobs = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        print("loading new jobs -----------------------------------")
        
        if contact_id != ""{
            self.title = "Jobs With Contact"
            
            if amIAirworker(){
                //here load new jobs
                var my_job_objs = self.getAppliedJobsIfExists()
                for item in my_job_objs{
                    my_jobs.append(item.job_id!)
                }
            }else{
                var my_job_objs = self.getUploadedJobsIfExists()
                for item in my_job_objs{
                    my_jobs.append(item.job_id!)
                }
            }
            
            
            let my_received_ratings = self.getAccountRatings(contact_id)
            var my_ratings = [Rating]()
            for item in my_received_ratings{
                if my_jobs.contains(item.job_id!){
                    my_ratings.append(item)
                }
            }
            
            for item in my_ratings{
                var job = getJobIfExists(job_id: item.job_id!)
                myJobs.append(job!)
            }
           
            
        }
        else{
            if amIAirworker(){
                self.title = "New Jobs"
                
                var uploadedJobs = [Job]()
                var my_job_objs = getNewJobsIfExists()
                
                if viewAppliedJobs{
                    self.title = "Applied Jobs"
                    var my_applied_objs = getAppliedJobsIfExists()
                    my_job_objs.removeAll()
                    for item in my_applied_objs {
                        my_job_objs.append(self.getJobIfExists(job_id: item.job_id!)!)
                    }
                }
                
                for item in my_job_objs{
                    if (isJobOk(job: item) || viewAppliedJobs){
                        uploadedJobs.append(item)
                    }
                }
                
                print("loaded \(my_job_objs.count) jobs")
                
                for item in uploadedJobs {
                    if(self.getJobIfExists(job_id: item.job_id!) != nil){
                        myJobs.append(self.getJobIfExists(job_id: item.job_id!)!)
                    }
                }
            }else{
                let uploadedJobs = self.getUploadedJobsIfExists()
                for item in uploadedJobs {
                    if(self.getJobIfExists(job_id: item.job_id!) != nil){
                        myJobs.append(self.getJobIfExists(job_id: item.job_id!)!)
                    }
                }
            }
            
        }
        
        jobsTableView.delegate = self
        jobsTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_job), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetChangeUser(_:)), name: NSNotification.Name(rawValue: constants.swapped_account_type), object: nil)
    }
    
    @objc func didGetChangeUser(_ notification: Notification){
        print("changing user account!")
        self.navigationController?.popToRootViewController(animated: true)
        resetUpViews()
    }
    
    @objc func didGetNotification(_ notification: Notification){
        print("refreshing job!")
        resetUpViews()
    }
    
    func resetUpViews(){
        myJobs.removeAll()
        my_jobs.removeAll()
        
        if contact_id != ""{
            
            if amIAirworker(){
                //here load new jobs
                var my_job_objs = getNewJobsIfExists()
                
                for item in my_job_objs{
                    if isJobOk(job: item){
                        my_jobs.append(item.job_id!)
                    }
                }
            }else{
                var my_job_objs = self.getUploadedJobsIfExists()
                for item in my_job_objs{
                    my_jobs.append(item.job_id!)
                }
            }
            
            
            let my_received_ratings = self.getAccountRatings(contact_id)
            var my_ratings = [Rating]()
            for item in my_received_ratings{
                if my_jobs.contains(item.job_id!){
                    my_ratings.append(item)
                }
            }
            
            for item in my_ratings{
                var job = getJobIfExists(job_id: item.job_id!)
                myJobs.append(job!)
            }
           
            
        }else{
            if amIAirworker(){
                var uploadedJobs = [Job]()
                var my_job_objs = getNewJobsIfExists()
                
                if viewAppliedJobs{
                    var my_applied_objs = getAppliedJobsIfExists()
                    my_job_objs.removeAll()
                    for item in my_applied_objs {
                        my_job_objs.append(self.getJobIfExists(job_id: item.job_id!)!)
                    }
                }
                
                for item in my_job_objs{
                    if (isJobOk(job: item) || viewAppliedJobs){
                        uploadedJobs.append(item)
                    }
                }
                
                print("loaded \(uploadedJobs.count) jobs")
                for item in uploadedJobs {
                    if(self.getJobIfExists(job_id: item.job_id!) != nil){
                        myJobs.append(self.getJobIfExists(job_id: item.job_id!)!)
                    }
                }
            }else{
                let uploadedJobs = self.getUploadedJobsIfExists()
                for item in uploadedJobs {
                    if(self.getJobIfExists(job_id: item.job_id!) != nil){
                        myJobs.append(self.getJobIfExists(job_id: item.job_id!)!)
                    }
                }
            }
            
        }
        
        jobsTableView.reloadData()
    }
    
    func isJobAFutureJob(job: Job) -> Bool {
        let today = Date()
        
        let start_date = DateComponents(calendar: .current, year: Int(job.start_year), month: Int(job.start_month)+1, day: Int(job.start_day)+1).date!
        
        //compare the two dates
        if (start_date > today) {
            //if start date is in future, it would be greater than today
            return true
        }
        
        return false
    }
    
    func isJobOk(job: Job) -> Bool{
//        if job.job_id! == "mYWiUZLwcTO8y8DzoyKl"{
//            return true
//        }
        
        if job.taken_down {
            return false
        }
        
        if job.auto_taken_down {
            return false
        }
        
        if !isJobAFutureJob(job: job){
            return false
        }
        
  
        let uid = Auth.auth().currentUser!.uid
        if job.uploader_id == uid {
            return false
        }
        
        return true
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch(segue.identifier ?? "") {
                        
        case "viewSelectedJob":
            guard let jobDetailViewController = segue.destination as? JobDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let jobItemTableViewCell = sender as? JobItemTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = jobsTableView.indexPath(for: jobItemTableViewCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedJob = myJobs[indexPath.row]
            print("notif item: \(selectedJob.job_title)")
            jobDetailViewController.job_id = selectedJob.job_id!
//            jobDetailViewController = selectedNotif
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myJobs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "jobItem", for: indexPath) as! JobItemTableViewCell
//        print("loaded job item: \(indexPath.row)")
        let job = myJobs[indexPath.row]
        
        for tag in job.tags! {
            cell.jobTags.append(tag as! JobTag)
        }
        cell.jobTitleLabel.text = job.job_title!
        
        var hr = Int(job.time_hour)
        if job.am_pm == "PM" {
            hr += 12
        }
        
        let date = DateComponents(calendar: .current, year: Int(job.start_year), month: Int(job.start_month)+1, day: Int(job.start_day), hour: hr, minute: Int(job.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job.end_year), month: Int(job.end_month)+1, day: Int(job.end_day), hour: hr, minute: Int(job.time_minute)).date!
        
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
        
        if amIAirworker(){
            cell.jobTimeLabel.text = "At \(job.time_hour):\(job.time_minute)\(self.gett("a", date))"
        }
        
        
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
        
        cell.takenDownImage.isHidden = !job.taken_down
        
        
        return cell
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
            let rater_id = item.rating_id!.replacingOccurrences(of: job_id!, with: "")
            
            var req_id_format = "\(job!.uploader_id!)\(job!.job_id!)"
//            var req_id_format = "\(job!.job_id!)"
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
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
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
    
    func getNewJobsIfExists() -> [Job]{
        do{
            let request = Job.fetchRequest() as NSFetchRequest<Job>
            let sortDesc = NSSortDescriptor(key: "upload_time", ascending: false)
            request.sortDescriptors = [sortDesc]
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return[]
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
  

}
