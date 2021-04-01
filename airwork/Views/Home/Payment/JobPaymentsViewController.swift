//
//  JobPaymentsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 19/03/2021.
//

import UIKit
import CoreData
import Firebase
import Cosmos

class JobPaymentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var jobCountLabel: UILabel!
    @IBOutlet weak var unpaidJobsTableView: UITableView!
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var myJobs = [Job]()
    var my_jobs = [String]()
    var my_job_ratings: [String: Double] = [String: Double]()
    var constants = Constants.init()
    var payment_total = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpViews()
    }
    @IBAction func whenCancelTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func setUpViews(){
        let payment_objs = self.getJobPaymentsIfExists()
        var paid_jobs: [String] = [String]()
        my_job_ratings.removeAll()
        
        for item in payment_objs {
            let payment_receipt = self.getPaymentReceipt(item.payment_receipt!)
            
            for job in payment_receipt.paid_jobs {
                paid_jobs.append(job.job_id)
            }
        }
        
        var my_received_ratings_jobs: [String] = [String]()
        var my_id = Auth.auth().currentUser!.uid
        let my_ratings = self.getAccountRatings(my_id)
        
        for item in my_ratings {
            print("loaded rating: \(item.rating_id)")
        }
        print("my ratings size:-------------- \(my_ratings.count)")
        
        for item in my_ratings {
            if(!paid_jobs.contains(item.job_id!)){
                my_received_ratings_jobs.append(item.job_id!)
                my_job_ratings[item.job_id!] = item.rating
            }
//            my_received_ratings_jobs.append(item.job_id!)
        }
        
        if !my_received_ratings_jobs.isEmpty {
            myJobs.removeAll()
            payment_total = 0
            
            for item in my_received_ratings_jobs {
                let job = self.getJobIfExists(job_id: item)!
                myJobs.append(job)
                
                var job_applicants = self.getJobApplicantsIfExists(job_id: job.job_id!)
                var my_price = 0
                var my_curr = ""
                var my_id = Auth.auth().currentUser!.uid
                print("my_id: \(my_id)")
                print("Job_id: \(job.job_id!)")
                
                var my_application = self.getAppliedJobIfExists(job_id: job.job_id!)!
                print("my application price---------------------- : \(my_application.application_pay_amount)")
                if my_application.application_pay_amount != 0 {
                    my_price = Int(my_application.application_pay_amount)
                    my_curr = my_application.application_pay_currency!
                }
                
                
                if my_price != 0 {
                    print("pay for job \(job.job_id!) :: \(my_price)")
                    payment_total += Int(Double(my_price) * constants.pay_perc)
                }else{
                    print("pay for job \(job.job_id!) :: \(job.pay_amount)")
                    payment_total += Int(Double(job.pay_amount) * constants.pay_perc)
                }
                
            }
            
            
            unpaidJobsTableView.delegate = self
            unpaidJobsTableView.dataSource = self
            unpaidJobsTableView.reloadData()
        }
        
        var my_account = self.getApplicantAccount(user_id: my_id)
        
        self.amountLabel.text = "\(payment_total)"
        self.currencyLabel.text = "\(my_account!.phone!.country_currency!)"
        self.jobCountLabel.text = "For the \(my_received_ratings_jobs.count) jobs"
    }
    
    func getPaymentReceipt(_ payment_receipt_json: String) -> PaymentReceipt{
        let decoder = JSONDecoder()
        
        do{
            let jsonData = payment_receipt_json.data(using: .utf8)!
            let job_images =  try decoder.decode(PaymentReceipt.self, from: jsonData)
            
            return job_images
        }catch{
            print("error loading job images")
        }
        
        return PaymentReceipt()
    }
    
    struct PaymentReceipt: Codable{
        var receipt_time = 0
        var transaction_id = ""
        var paymentResponse = PaymentResponse()
        var method = PaymentMethod()
        var paid_jobs: [encodable_job] = [encodable_job]()
    }
    
    struct PaymentResponse: Codable{
        var ResponseDescription = ""
        var ResponseCode = ""
        var MerchantRequestID = ""
        
        var CheckoutRequestID = ""
        var ResultCode = ""
        var ResultDesc = ""
        var timeOfDay: String = ""
        var datee: String = ""
        var payingPhoneNumber: String = ""
        var pushrefInAdminConsole: String = ""
        var uploaderId: String = ""
    }
    
    struct PaymentMethod: Codable{
        var name = ""
        var min_amount = 0
        var min_amount_currency = ""
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
    
    struct selected_workers: Codable{
        var worker_list = [String]()
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        //initiatePaySegue
        
        switch(segue.identifier ?? "") {
            
        case "initiatePaySegue":
            guard let paymentInitiatorViewController = segue.destination as? PaymentInitiatorViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            paymentInitiatorViewController.payment_total = payment_total
            
            
        default:
            print("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 3
        return myJobs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentJobItem", for: indexPath) as! PaymentJobTableViewCell
        print("loaded job item: \(indexPath.row)")
        
        
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
        
        var my_price = 0
        var my_curr = ""
        var my_id = Auth.auth().currentUser!.uid
        
        var my_application = self.getAppliedJobIfExists(job_id: job.job_id!)!
        if my_application.application_pay_amount != 0 {
            my_price = Int(my_application.application_pay_amount)
            my_curr = my_application.application_pay_currency!
        }
        
        if my_price == 0 {
            cell.jobAmountLabel.text = "\(job.pay_currency!) \(job.pay_amount) Qouted."
            if job.pay_amount == 0 {
                cell.jobAmountLabel.text = ""
                cell.amountView.isHidden = true
            }
        }else {
            cell.jobAmountLabel.text = "For \(my_curr) \(my_price)"
            cell.jobAmountLabel.textColor = UIColor(named: "CustomAmountColor")
        }

        cell.jobTimeLabel.text = "At \(job.time_hour):\(job.time_minute)\(self.gett("a", date))"



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


        cell.takenDownImage.isHidden = true
//            !job.taken_down
        
        cell.receivedRatingLabel.text = "\(round(10 * my_job_ratings[job.job_id!]!) / 10)"
        cell.receivedRatingView.rating = my_job_ratings[job.job_id!]!
        
        
        return cell
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
    
    func getAccountRating(_ rating_id: String) -> Rating? {
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
    
    func getAccountRatings(_ user_id: String) -> [Rating] {
        print("loading ratings for user id: \(user_id)")
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
            var my_id = Auth.auth().currentUser!.uid
            print("filtering rating: \(item.rating_id)")
            
            let job_id = item.job_id
            let job = self.getJobIfExists(job_id: job_id!)
            print("Am I owner??? ---- \(job!.uploader_id! == my_id)")
            let rater_id = item.rating_id!.replacingOccurrences(of: job_id!, with: "")
            
            
            var req_id_format = "\(job!.uploader_id!)\(job!.job_id!)"
//            var req_id_format = "\(job!.job_id!)"
            if self.amIAirworker(){
                if rater_id != ""{
                    req_id_format = "\(rater_id)\(job!.job_id!)"
                }
                if job!.uploader_id! == my_id {
                    //we dont want to show my uploaded jobs. If its my job, just reject automatically
                
                    req_id_format = "reject"
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
    
    
    func getJobPaymentsIfExists() -> [JobPayment] {
        do{
            let request = JobPayment.fetchRequest() as NSFetchRequest<JobPayment>
            
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
    
    func getAppliedJobIfExists(job_id: String) -> AppliedJob? {
        do{
            let request = AppliedJob.fetchRequest() as NSFetchRequest<AppliedJob>
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

}
