//
//  JobDetailsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 10/01/2021.
//

import UIKit
import CoreData
import Firebase
import GoogleMaps
import Cosmos
import MapKit
import CoreLocation

class JobDetailsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var jobImagesCollectionView: UICollectionView!
    @IBOutlet weak var jobTagsCollectionView: UICollectionView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verifiedImage: UIImageView!
    @IBOutlet weak var workerCountLabel: UILabel!
    @IBOutlet weak var ratingsLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var amountView: UIView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var durFromNowLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationMap: GMSMapView!
    @IBOutlet weak var applicantsImagesCollection: UICollectionView!
    @IBOutlet weak var applicantImagesContainer: UIView!
    
    
    @IBOutlet weak var userIconImage: UIImageView!
    @IBOutlet weak var applicantNameLabel: UILabel!
    @IBOutlet weak var applicantVerifiedImage: UIImageView!
    @IBOutlet weak var applicationTimeLabel: UILabel!
    @IBOutlet weak var applicantsRatingsLabel: UILabel!
    @IBOutlet weak var applicantAmountLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var applicantCard: CardView!
    @IBOutlet weak var viewApplicantButton: UIButton!
    
    @IBOutlet weak var noApplicationsView: UIView!
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var applicantsView: UIView!
    
    @IBOutlet weak var applicantHistoryView: UIView!
    @IBOutlet weak var jobCountLabel: UILabel!
    @IBOutlet weak var jobSubscriptLabel: UILabel!
    @IBOutlet weak var averageRatingLabel: UILabel!
    @IBOutlet weak var lastRatingNumberLabel: UILabel!
    
    @IBOutlet weak var takeDownTitleLabel: UILabel!
    @IBOutlet weak var takeDownDetailsLabel: UILabel!
    @IBOutlet weak var takenDownDotImage: UIImageView!
    @IBOutlet weak var applicantSelectedImage: UIImageView!
    
    
    @IBOutlet weak var takeDownContainer: UIView!
    @IBOutlet weak var rateWorkersContainer: UIView!
    @IBOutlet weak var applyForJobContainer: UIView!
    @IBOutlet weak var jobOwnerRatingsContainer: UIView!
    
    @IBOutlet weak var applyJobTitle: UILabel!
    @IBOutlet weak var applyJobDetail: UILabel!
    @IBOutlet weak var jobOwnerRatingsExplanation: UILabel!
    
    //owner views
    @IBOutlet weak var jobOwnerImage: UIImageView!
    @IBOutlet weak var ownerNameLabel: UILabel!
    @IBOutlet weak var ownerRatingsLabel: UILabel!
    @IBOutlet weak var rateOwnerView: UIView!
    @IBOutlet weak var setRatingNumberLabel: UILabel!
    @IBOutlet weak var setRatingView: CosmosView!
    @IBOutlet weak var removeRatingButton: UIButton!
    
    //rate 1st applicant view
    @IBOutlet weak var rateApplicantView: UIView!
    @IBOutlet weak var setApplicantRatingNumberLabel: UILabel!
    @IBOutlet weak var setApplicantRatingView: CosmosView!
    @IBOutlet weak var removeApplicantRatingButton: UIButton!
    
    //my application details
    @IBOutlet weak var myuserIconImage: UIImageView!
    @IBOutlet weak var myapplicantNameLabel: UILabel!
    @IBOutlet weak var myapplicantVerifiedImage: UIImageView!
    @IBOutlet weak var myapplicantsRatingsLabel: UILabel!
    @IBOutlet weak var myjobCountLabel: UILabel!
    @IBOutlet weak var myjobSubscriptLabel: UILabel!
    @IBOutlet weak var myaverageRatingLabel: UILabel!
    @IBOutlet weak var mylastRatingNumberLabel: UILabel!
    @IBOutlet weak var myselectedLabel: UILabel!
    @IBOutlet weak var myapplicantHistoryView: UIView!
    
    @IBOutlet weak var pendingRatingsContainer: UIView!
    @IBOutlet weak var createAccountContainer: UIView!
    @IBOutlet weak var verifyIdentityContainer: UIView!
    @IBOutlet weak var verifyEmailContainer: UIView!
    
    @IBOutlet weak var openPendingRatingsButton: UIButton!
    @IBOutlet weak var ViewAttachedDoc: UIView!
    @IBOutlet weak var lock_icon: UIImageView!
    
    
    var job_id: String = ""
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var job: Job? = nil
    var job_images = [job_image]()
    var constants = Constants.init()
    var jobTags = [JobTag]()
    
    var publicUsersToShow: [String] = []
    var myLocationMarker: GMSMarker?
    var myLocationCircle: GMSCircle?
    var addedMarkers = [String : GMSMarker]()
    var addedCircles = [String : GMSCircle]()
    var addedLines = [String : [GMSPolyline]]()
    
    var jobsViews = [String]()
    var jobApplicantsUids = [String]()
    var pickedApplicantsUids = [String]()
    
    let MAX_DISTANCE_TRHESHOLD = 7000.0
    let db = Firestore.firestore()
    var job_owner_rating = 4.2
    
    var ratings: [String: Double] = [String: Double]()
    var rated_users = [String]()
    var has_loaded_map = false
    var firstApplicantId = ""
    
    let locationManager = CLLocationManager()
    var myLat = 0.0
    var myLong = 0.0
    var jobApplicants = [String]()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpViews()
        
        if amIAirworker(){
            updateView()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_job), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_account), object: nil)
    }
    
    @objc func didGetNotification(_ notification: Notification){
        print("refreshing job!")
        setUpViews()
    }
    
    func updateView(){
        let uid = Auth.auth().currentUser!.uid
        job = self.getJobIfExists(job_id: job_id)!
        
        let upload_time = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        let ref = db.collection(constants.jobs_ref)
            .document(job!.country_name!)
            .collection(constants.country_jobs)
            .document(job_id)
            .collection(constants.views)
            .document(uid).setData([
                "view_id" : uid,
                "view_time" : upload_time,
                "viewer_id" : uid,
                "job_id" : job!.job_id!
            ])
    }
    
    func canIApplyForJob() -> Bool{
        createAccountContainer.isHidden = true
        verifyIdentityContainer.isHidden = true
        pendingRatingsContainer.isHidden = true
        verifyEmailContainer.isHidden = true
        
        
        let my_application = self.getAppliedJobIfExists(job_id: job_id)
        
        if my_application != nil {
            return true
        }
        
        let uid = Auth.auth().currentUser!.uid
        
        if Auth.auth().currentUser!.isAnonymous {
            createAccountContainer.isHidden = false
            return false
        }
        
        if (!self.isEmailVerified()){
            verifyEmailContainer.isHidden = false
            return false
        }
        
        var account = self.getApplicantAccount(user_id: uid)
        if (account?.scan_id_data == nil || account?.scan_id_data == ""){
            verifyIdentityContainer.isHidden = false
            return false
        }
        
        let any_unpaid_jobs = self.getUnpaidJobs()
        if !any_unpaid_jobs.isEmpty {
            pendingRatingsContainer.isHidden = false
            return false
        }
        
        
        return true
    }
    
    
    func isEmailVerified() -> Bool{
        let me = Auth.auth().currentUser!
        let my_acc = self.getApplicantAccount(user_id: me.uid)
        me.reload { (e: Error?) in
            
        }
        
        print("email vo: ------- \(my_acc!.email_verification_obj)")
        
        if my_acc!.email_verification_obj != nil && my_acc!.email_verification_obj! != "" {
            print("returning true!!")
            return true
        }
        
        return me.isEmailVerified
        
    }
    
    var my_jobs = [String]()
    var my_job_ratings: [String: Double] = [String: Double]()
    func getUnpaidJobs() -> [String] {
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
//        print("my ratings size:-------------- \(my_ratings.count)")
        
        for item in my_ratings {
            if(!paid_jobs.contains(item.job_id!)){
                my_received_ratings_jobs.append(item.job_id!)
                my_job_ratings[item.job_id!] = item.rating
            }
        }
        
        return my_received_ratings_jobs
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
    
    var myJobs = [Job]()
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
    
    
    func setUpViews(){
        print("goten job id: \(job_id)")
        job = self.getJobIfExists(job_id: job_id)!
        job_images = self.getJobImages(images_json: job!.images!)
        jobTags.removeAll()
        for tag in job!.tags! {
            jobTags.append(tag as! JobTag)
        }
       
        //set job tags
        jobTagsCollectionView.delegate = self
        jobTagsCollectionView.dataSource = self
        
        //set job images
        jobImagesCollectionView.delegate = self
        jobImagesCollectionView.dataSource = self
        
        //set job title
        if job!.is_job_private{
            titleLabel.text = "    \(job!.job_title!)"
            lock_icon.isHidden = false
        }else{
            titleLabel.text = job!.job_title!
            lock_icon.isHidden = true
        }
        detailsLabel.text = job!.job_details!
        var views = self.getJobViewsIfExists(job_id: job!.job_id!)
        var applicants = self.getJobApplicantsIfExists(job_id: job!.job_id!)
        
        //set number of views
        viewsLabel.text = "\(views.count) views."
        if views.count == 1 {
            viewsLabel.text = "\(views.count) view."
        } else if views.count == 0 {
            viewsLabel.text = ""
        }
        
        var owner_id = job!.uploader_id!
        var owner = self.getApplicantAccount(user_id: owner_id)
        
        
        //set uploader name
        nameLabel.text = owner!.name
//        if self.isAccountVerified(user: me!){
//            verifiedImage.isHidden = false
//        }else {
//            verifiedImage.isHidden = true
//        }
        
        //set number of workers needed
        workerCountLabel.text = "\(job!.job_worker_count) workers."
        if job!.job_worker_count == 1 {
            workerCountLabel.text = "\(job!.job_worker_count) worker."
        } else if ((job!.job_worker_count == constants.maxNumber) || (job!.job_worker_count == 0)) {
            workerCountLabel.text = " "
        }
        
        //set my number of ratings
        var my_ratings = self.getAccountRatings(owner_id)
        if my_ratings.isEmpty {
            ratingsLabel.text = "New!"
        }else{
            ratingsLabel.text = "\(my_ratings.count) Ratings."
            if my_ratings.count == 1 {
                ratingsLabel.text = "\(my_ratings.count) Rating."
            }
        }
        
        //set job amount and currency
        amountLabel.text = "\(job!.pay_amount)"
        currencyLabel.text = "\(job!.pay_currency!)"
        
        if job!.pay_amount == 0 {
            amountView.isHidden = true
        }else{
            amountView.isHidden = false
        }
        
        var hr = Int(job!.time_hour)
        if job!.am_pm == "PM" {
            hr += 12
        }
        
        let date = DateComponents(calendar: .current, year: Int(job!.start_year), month: Int(job!.start_month)+1, day: Int(job!.start_day), hour: hr, minute: Int(job!.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day), hour: hr, minute: Int(job!.time_minute)).date!
        
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
            durFromNowLabel.text = "\(timeOffset) ago."
        }else{
            durFromNowLabel.text = "In \(timeOffset)"
        }
        
        //set job date
        dateLabel.text = "On \(gett("EEEE", date)), \(job!.start_day) \(gett("MMM", date)) \(job!.start_year)"
        
        //set job time
        var min = "\(job!.time_minute)"
        if job!.time_minute < 10 {
            min = "0\(job!.time_minute)"
        }
        timeLabel.text = "@\(job!.time_hour):\(min)\(self.gett("a", date).lowercased())"
        
        //set job duration
        if job!.work_duration == "" {
            timeOffset = end_date.offset(from: date)
            if timeOffset == "" {
                timeOffset = date.offset(from: end_date)
            }
            durationLabel.text = "\(timeOffset)"
            
        }else{
            if job!.work_duration == constants.durationless {
                durationLabel.text = " "
            }else{
                durationLabel.text = "\(job!.work_duration!)"
            }
            
        }
        
        //set job location
        if job!.location_desc != nil && job!.location_desc! != ""{
            if !has_loaded_map {
                
                self.publicUsersToShow.removeAll()
                self.publicUsersToShow = self.getAppropriateUsers()
                
                print("Location: \(job!.location_desc)")
                locationLabel.text = job!.location_desc
                locationView.isHidden = false
                locationView.alpha = 0
                
                do {
                     if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                        if UITraitCollection.current.userInterfaceStyle == .dark {
                            locationMap.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                        }else{
                            if let styleURL2 = Bundle.main.url(forResource: "light-style", withExtension: "json") {
                                locationMap.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL2)
                            }
                            
                        }
                     } else {
                       NSLog("Unable to find style.json")
                     }
                } catch {
                     NSLog("One or more of the map styles failed to load. \(error)")
                }
                
                locationMap.layer.cornerRadius = 15
                locationMap.isUserInteractionEnabled = false
            
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `2.0` to the desired number of seconds.
                   // Code you want to be delayed
                    let camera = GMSCameraPosition.camera(withLatitude: self.job!.location_lat, longitude: self.job!.location_long, zoom: 15.0)
                    self.locationMap.camera = camera
                    self.locationView.alpha = 1
                    
                    self.jobsViews.removeAll()
                    self.jobApplicantsUids.removeAll()
                    
                    let view_objs = self.getJobViewsIfExists(job_id: self.job_id)
                    for item in view_objs {
                        self.jobsViews.append(item.viewer_id!)
                    }
                    
                    let applicant_objs = self.getJobApplicantsIfExists(job_id: self.job_id)
                    for item in applicant_objs {
                        self.jobApplicantsUids.append(item.applicant_uid!)
                    }
                    
                    if self.job!.selected_workers != nil {
                        var selected_users_json = self.job!.selected_workers!
                        let decoder = JSONDecoder()
                        let jsonData = selected_users_json.data(using: .utf8)!
                        
                        do{
                            var selected_users = selected_workers()
                            
                            if selected_users_json != "" {
                                selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                            }
                            //if applicant has been selected
                            if !selected_users.worker_list.isEmpty {
                                //lets show the first person picked instead
                                self.pickedApplicantsUids.removeAll()
                                for item in applicants {
                                    self.pickedApplicantsUids.append(item.applicant_uid!)
                                    
                                }
                                
                            }
                        }catch{
                            print("error loading job applicants")
                        }
                    }
                    
                    if self.amIAirworker(){
                        //we just load the job location, and its directions to user
                        self.locationManager.requestAlwaysAuthorization()
                        self.locationManager.requestWhenInUseAuthorization()
                        
                        if CLLocationManager.locationServicesEnabled() {
                            self.locationManager.delegate = self
                            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                            self.locationManager.startUpdatingLocation()
                        }
                        
                    }else{
                        self.setAllUsersOnMap(myLat: self.job!.location_lat, myLong: self.job!.location_long)
                    }
                }
                
                let position = CLLocationCoordinate2D(latitude: job!.location_lat, longitude: job!.location_long)
                let marker = GMSMarker(position: position)
                marker.icon = self.imageWithImage(image: UIImage(named: "JobLocation")!, scaledToSize: CGSize(width: 30.0, height: 60.0))
                marker.map = locationMap
                
                has_loaded_map = true
            }
            
        }else{
            locationView.isHidden = true
        }
        
        if amIAirworker() {
            takeDownContainer.isHidden = true
            if self.canIApplyForJob(){
                applyForJobContainer.isHidden = false
            }
            rateWorkersContainer.isHidden = true
            rateOwnerView.isHidden = true
            jobOwnerRatingsContainer.isHidden = false
            
            editButton.isEnabled = false
            
            applicantsView.isHidden = true
            noApplicationsView.isHidden = true
            
            loadMyApplicationDetails()
            
            jobOwnerRatingsExplanation.text = "View how \(job!.uploader_name!) has worked with others."
            
            let my_application = self.getAppliedJobIfExists(job_id: job_id)
            
            if my_application == nil {
                rateWorkersContainer.isHidden = true
                rateOwnerView.isHidden = true
                
                applyJobTitle.text = "Apply for job."
                applyJobDetail.text = "You want to do this job."
                
            }else{
                applyJobTitle.text = "Remove Application"
                applyJobDetail.text = "You don't want to do the job"
                
                var selected_users_json = job!.selected_workers
                if selected_users_json != nil {
                    let decoder = JSONDecoder()
                    let jsonData = selected_users_json!.data(using: .utf8)!
                    
                    do{
                        var selected_users = selected_workers()
                        
                        if selected_users_json != "" {
                            selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                        }
                        if !selected_users.worker_list.isEmpty {
                            let my_id = Auth.auth().currentUser!.uid
                            if selected_users.worker_list.contains(my_id){
                                //if ive been picked
                                rateWorkersContainer.isHidden = false
                                rateOwnerView.isHidden = false
                                
                                print("I was picked for this job")
                                applyForJobContainer.isHidden = true
                            }else{
                                rateWorkersContainer.isHidden = true
                                rateOwnerView.isHidden = true
                            }
                        }
                    }catch{
                        print("error loading selected users")
                    }
                }
            }
            
            
            self.getPendingJobs()
            if self.myJobs.isEmpty{
                self.openPendingRatingsButton.isHidden = true
            }else{
                self.openPendingRatingsButton.isHidden = false
            }
            
        }
        else{
            editButton.isEnabled = true
            rateWorkersContainer.isHidden = true
            rateApplicantView.isHidden = true
            rateOwnerView.isHidden = true
            
            //set an applicant if any
            if applicants.isEmpty {
                applicantsView.isHidden = true
                noApplicationsView.isHidden = false
                
            }else{
                applicantsView.isHidden = false
                noApplicationsView.isHidden = true
                
                var firstApplicant = applicants[0]
                var theirAcc = self.getApplicantAccount(user_id: firstApplicant.applicant_uid!)
                
                
                var selected_users_json = job!.selected_workers
                let decoder = JSONDecoder()
                
                
                do{
                    var selected_users = selected_workers()
                    
                    if selected_users_json != nil && selected_users_json != "" {
                        let jsonData = selected_users_json!.data(using: .utf8)!
                        selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                    }
                    //if applicant has been selected
                    if !selected_users.worker_list.isEmpty {
                        rateWorkersContainer.isHidden = false
                        rateApplicantView.isHidden = false
                        //lets show the first person picked instead
                        let first = selected_users.worker_list[0]
                        for item in applicants {
                            if item.applicant_uid == first{
                                firstApplicant = item
                                theirAcc = self.getApplicantAccount(user_id: firstApplicant.applicant_uid!)
                            }
                        }
                        
                    }
                    
                    //set the applicants name
                    applicantNameLabel.text = theirAcc!.name
                    firstApplicantId = theirAcc!.uid!
                    
                    if self.isApplicantVerified(user: theirAcc!){
                        applicantVerifiedImage.isHidden = false
                    }else {
                        applicantVerifiedImage.isHidden = true
                    }
                    
                    var app_date = Date(timeIntervalSince1970: TimeInterval(firstApplicant.application_time) / 1000)
                
                    timeOffset = app_date.offset(from: Date())
                    if timeOffset == "" {
                        timeOffset = Date().offset(from: app_date)
                        applicationTimeLabel.text = "\(timeOffset)."
                    }else{
                        applicationTimeLabel.text = "\(timeOffset)"
                    }
                    
                    var ratings = self.getAccountRatings(theirAcc!.uid!)
                    
                    //set the applicants number of ratings
                    applicantsRatingsLabel.text = "\(ratings.count) Ratings."
                    if ratings.count == 1 {
                        applicantsRatingsLabel.text = "\(ratings.count) Rating."
                    }else if ratings.count == 0 {
                        applicantsRatingsLabel.text = "New!"
                    }
                    
                    //set their application amount
                    if firstApplicant.application_pay_currency != nil {
                        if firstApplicant.application_pay_amount != job!.pay_amount {
                            applicantAmountLabel.text = "For  \(firstApplicant.application_pay_currency!)  \(firstApplicant.application_pay_amount)"
                            applicantAmountLabel.textColor = UIColor(named: "CustomAmountColor")
                            
                        }else{
                            applicantAmountLabel.text = "For your amount."
                            applicantAmountLabel.textColor = UIColor.secondaryLabel
                        }
                    }else{
                        applicantAmountLabel.text = "For your amount."
                        applicantAmountLabel.textColor = UIColor.secondaryLabel
                    }
                    
                    //if applicant has been selected part
                    selectedLabel.isHidden = true
                    applicantSelectedImage.isHidden = true
                    applicantHistoryView.isHidden = true
                    rateApplicantView.isHidden = true
                    
                    if selected_users.worker_list.contains(firstApplicant.applicant_uid!){
                        //the user has been selected!
                        selectedLabel.isHidden = false
                        applicantSelectedImage.isHidden = false
                        rateApplicantView.isHidden = false
                        self.loadPickedWorker(user: firstApplicant.applicant_uid!)
                        
                        let ratings = getAccountRatings(firstApplicant.applicant_uid!)
                        if !ratings.isEmpty {
                            applicantHistoryView.isHidden = false
                            
                            jobCountLabel.text = "\(ratings.count)"
                            if ratings.count == 1 {
                                jobSubscriptLabel.text = "Job"
                            }
                            
                            if ratings.count > 3 {
                                var last3 = Array(ratings.suffix(3))
                                var total = 0.0
                                for item in last3 {
                                    total += Double(item.rating)
                                }
                                averageRatingLabel.text = "\(round(10 * total/3.0)/10)"
                            }else{
                                //less than 3
                                var total = 0.0
                                for item in ratings {
                                    total += Double(item.rating)
                                }
                                averageRatingLabel.text = "\(round(10 * total/Double(ratings.count))/10)"
                                lastRatingNumberLabel.text = "Last \(ratings.count)."
                            }
                            
                            let my_id = Auth.auth().currentUser?.uid
                            for item in ratings{
                                if (item.job_id! == job_id){
                                    print("changin selected word with \(item.rating)")
                                    selectedLabel.text = "Rated: \(round(10 * item.rating)/10)"
                                    break
                                }
                            }
                        }
                        
                    }else{
                        let my_id = Auth.auth().currentUser?.uid
                        let ratings = getAccountRatings(my_id!)
                        for item in ratings{
                            if item.user_id! == firstApplicant.applicant_uid!{
                                selectedLabel.isHidden = false
                                selectedLabel.text = "You last rated: \(round(10 * item.rating)/10)"
                                
                                break
                            }
                        }
                    }
                    
                    
                    let uid = firstApplicant.applicant_uid!
                    
                    let storageRef = Storage.storage().reference()
                    let ref = storageRef.child(constants.users_data)
                        .child(uid)
                        .child("avatar.jpg")
                    
                    if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
                        let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
                        let im = UIImage(data: resource.data!)
                        self.userIconImage.image = im
                          
                        let image = self.userIconImage!
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
                                self.userIconImage.image = im
                                
                                let image = self.userIconImage!
                                image.layer.borderWidth = 1
                                image.layer.masksToBounds = false
                                image.layer.borderColor = UIColor.white.cgColor
                                image.layer.cornerRadius = image.frame.height/2
                                image.clipsToBounds = true
                                
                                self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: uid)
                            }
                          }
                    }
                    
                
                }catch{
                    print("error loading selected users")
                }
                
                
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(JobDetailsViewController.whenViewApplicantTapped))
            applicantCard.addGestureRecognizer(tap)
            
            
            
            if job!.taken_down == true {
                takeDownTitleLabel.text = "Restore"
                takeDownDetailsLabel.text = "Make this job visible again."
                takenDownDotImage.isHidden = false
            }else{
                takeDownTitleLabel.text = "Take Down"
                takeDownDetailsLabel.text = "Make this job not visible to others."
                takenDownDotImage.isHidden = true
            }
            
            //check if we can show rating and take down parts
            let today = Date()
            
            let end_date_for_visibility = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day)).date!
            
            if today > end_date_for_visibility {
                takeDownContainer.isHidden = true
                editButton.isEnabled = false
            }else{
                takeDownContainer.isHidden = false
//                editButton.isEnabled = true
            }
        
        }
        self.loadJobOwner()
        
        let job_applicants = self.getJobApplicantsIfExists(job_id: job_id)
        self.jobApplicants.removeAll()
        for item in job_applicants {
            self.jobApplicants.append(item.applicant_uid!)
        }
        
        if self.jobApplicants.isEmpty{
            applicantImagesContainer.isHidden = true
        }else{
            applicantImagesContainer.isHidden = false
        }
        
        if amIAirworker(){
            applicantImagesContainer.isHidden = true
        }
        
        applicantsImagesCollection.delegate = self
        applicantsImagesCollection.dataSource = self
        
        
        let uploader = job!.uploader_id!
        let storageRef = Storage.storage().reference()
        
        let ref = storageRef.child(constants.users_data)
            .child(uploader)
            .child(constants.job_document)
            .child("\(job_id).pdf")
        
        ViewAttachedDoc.isHidden = true
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            ViewAttachedDoc.isHidden = false
        }else{
            ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                  // Uh-oh, an error occurred!
                    print("loading doc from cloud failed \(error.localizedDescription)")
                    self.ViewAttachedDoc.isHidden = true
                } else {
                  // Data for "images/island.jpg" is returned
                    self.ViewAttachedDoc.isHidden = false
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: uploader)
                }
              }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        if(self.myLat == 0.0){
            self.myLat = -1.286389
//                locValue.latitude
            self.myLong = 36.817223
//                locValue.longitude
            
            self.moveCamera(self.myLat, self.myLong)
            self.setMyLocation(self.myLat, self.myLong)
            
            if (self.job!.location_lat != 0.0 && self.job!.location_long != 0.0) {
                self.getRoadPathToUser(self.job!.uploader_id!, self.myLat, self.myLong, self.job!.location_lat, self.job!.location_long)
                
                var bounds = GMSCoordinateBounds()
                bounds = bounds.includingCoordinate(CLLocationCoordinate2DMake(self.myLat, self.myLong))
                bounds = bounds.includingCoordinate(CLLocationCoordinate2DMake(self.job!.location_lat, self.job!.location_long))
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
                    self.locationMap.animate(with: update)
                }
            }
        }
        self.myLat = -1.286389
//                locValue.latitude
        self.myLong = 36.817223
//                locValue.longitude

    }
    
    func setMyLocation(_ lat: Double,_ long: Double){
        var position = CLLocationCoordinate2DMake(lat, long)
        var marker = GMSMarker(position: position)
        
        let circleCenter = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let circle = GMSCircle(position: circleCenter, radius: 1000)
        
        circle.fillColor = UIColor(red: 113, green: 204, blue: 231, alpha: 0.1)
        circle.strokeColor = .none
        
        circle.map = locationMap
        
        marker.icon = UIImage(named: "MyLocationIcon")
        marker.map = locationMap
        
        self.myLocationMarker = marker
        self.myLocationCircle = circle
    
    }
    
    func runAnimationForDirection(_ polyline_list : [GMSPolyline], _ delay: Double){
        for item in polyline_list {
            item.map = nil
        }
        pos = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.startAnimation(polyline_list)
        }
    }
    
    var pos = 0
    func startAnimation(_ polyline_list : [GMSPolyline]){
        polyline_list[pos].map = locationMap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            print("running animation")
            self.pos += 1
            if polyline_list.count >= self.pos + 1 {
                self.startAnimation(polyline_list)
            }
        }
    }
    
    func setAllUsersOnMap(myLat: Double, myLong: Double){
        var bounds = GMSCoordinateBounds()
        for user in publicUsersToShow{
            var their_loc = getPubUsersLocation(user)
            
            if their_loc != nil {
                var user_ratings = self.getAccountRatings(user)
                var position = CLLocationCoordinate2DMake(their_loc!.latitude, their_loc!.longitude)
                var marker = GMSMarker(position: position)
                
                if user_ratings.isEmpty{
                    marker.title = "New!."
                }else if user_ratings.count == 1 {
                    marker.snippet = "\(user_ratings.count) Rating."
                    marker.title = "★\(self.getAverage(user_ratings))"
                }else{
                    marker.snippet = "\(user_ratings.count) Ratings."
                    marker.title = "★\(self.getAverage(user_ratings))"
                }
                
                marker.icon = UIImage(named: "PickUserIcon")
                marker.map = locationMap
                
                let coordinate₀ = CLLocation(latitude: myLat, longitude: myLong)
                let coordinate₁ = CLLocation(latitude: their_loc!.latitude, longitude: their_loc!.longitude)
                
                if (self.getDistance(loc1: coordinate₀, loc2: coordinate₁) < self.MAX_DISTANCE_TRHESHOLD) {
                    print("adding item to bounds")
                    bounds = bounds.includingCoordinate(marker.position)
                }
                
                self.setLineToUser(user, myLat, myLong, their_loc!.latitude, their_loc!.longitude)
                
                addedMarkers[user] = marker
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
            self.locationMap.animate(with: update)
        }
    }
    
    func getLineColorForUser(user_id: String) -> UIColor {
        var color = UIColor(red: 40, green: 40, blue: 40, alpha: 0.2)
        color = UIColor(named: "JobUnseen")!
        if amIAirworker(){
            color = UIColor(named: "JobSeen")!
        }
        
        if pickedApplicantsUids.contains(user_id){
            //picked line is a blue
//            color = UIColor(red: 0, green: 122, blue: 255, alpha: 0.7)
            color = UIColor(named: "JobApplied")!
        }else if jobApplicantsUids.contains(user_id) {
//            color = UIColor(red: 40, green: 40, blue: 40, alpha: 0.7)
            color = UIColor(named: "JobApplied")!
        }else if jobsViews.contains(user_id) {
//            color = UIColor(red: 40, green: 40, blue: 40, alpha: 0.3)
            color = UIColor(named: "JobSeen")!
        }
        
        return color
    }
    
    
    func getAverage(_ ratings: [Rating]) -> Double{
        var total = 0.0
        for item in ratings {
            total += Double(item.rating)
        }
        return round(10 * total/Double(ratings.count))/10
    }
    
    func setLineToUser(_ user: String,_ start_lat: Double,_ start_long: Double,_ end_lat: Double,_ end_long: Double){
        var path = addedLines[user]
        
        var new_path = GMSMutablePath()
        
        new_path.add(CLLocationCoordinate2D(latitude: start_lat, longitude: start_long))
        new_path.add(CLLocationCoordinate2D(latitude: end_lat, longitude: end_long))
        
        if path != nil {
            for item in path! {
                item.map = nil
            }
            
            path?.removeAll()
        }
        
        var polyline_list = [GMSPolyline]()
        
        let polyline = GMSPolyline(path: new_path)
        polyline.geodesic = true
        let color = self.getLineColorForUser(user_id: user)
        polyline.strokeColor = color
        polyline.strokeWidth = 3
        polyline.map = self.locationMap
        
        polyline_list.append(polyline)
        self.addedLines[user] = polyline_list
        
        if jobsViews.contains(user) || jobApplicantsUids.contains(user){
            let coordinate₀ = CLLocation(latitude: start_lat, longitude: start_long)
            let coordinate₁ = CLLocation(latitude: end_lat, longitude: end_long)
            
            if (self.getDistance(loc1: coordinate₀, loc2: coordinate₁) < self.MAX_DISTANCE_TRHESHOLD) {
                //I only want to show directions for people close to me
                self.getRoadPathToUser(user, start_lat, start_long, end_lat, end_long)

            }
            
        }
        
    }
    
    func getDistance( loc1: CLLocation, loc2: CLLocation) -> Double {
        return loc2.distance(from: loc1)
    }
    
    func getRoadPathToUser(_ user: String,_ start_lat: Double,_ start_long: Double,_ end_lat: Double,_ end_long: Double){
        guard let filePath = Bundle.main.path(forResource: "maps-Info", ofType: "plist") else {
              fatalError("Couldn't find file 'maps-Info.plist'.")
            }
            // 2
            let plist = NSDictionary(contentsOfFile: filePath)
            guard let value = plist?.object(forKey: "DIRECTIONS_API_KEY") as? String else {
              fatalError("Couldn't find key 'DIRECTIONS_API_KEY' in 'maps-Info.plist'.")
            }
        
        var url: String = "https://maps.googleapis.com/maps/api/directions/json?origin=\(start_lat),\(start_long)&destination=\(end_lat),\(end_long)&key=\(value)"
        
        var request : NSMutableURLRequest = NSMutableURLRequest()
        request.url = NSURL(string: url) as URL?
        request.httpMethod = "GET"

        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse!, data: Data!, error: Error!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
            do{
                let jsonResult: NSDictionary! = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary

                if (jsonResult != nil) {
                    let routes = jsonResult["routes"] as! NSArray
                    let picked_route = routes[0] as! NSDictionary
                    let legs = picked_route["legs"] as! NSArray
                    
                    DispatchQueue.main.async {
                        var polyline_list = [GMSPolyline]()
                        for leg in legs {
                            let steps = (leg as! NSDictionary)["steps"] as! NSArray
                            
                            for step in steps{
                                let path = ((step as! NSDictionary)["polyline"] as! NSDictionary)["points"] as! String
                                let dec_path = GMSMutablePath(fromEncodedPath: path)!
                                
                                let polyline = GMSPolyline(path: dec_path)
                                let color = self.getLineColorForUser(user_id: user)
                                polyline.strokeColor = color
                                polyline.strokeWidth = 3
                                polyline.map = self.locationMap
                                
                                
                                polyline_list.append(polyline)
                                
                            }
                        }
                    
                        if !polyline_list.isEmpty {
                            var drawn_paths = self.addedLines[user]
                            
                            if drawn_paths == nil {
                                print("drawn path is nil--------")
                                self.addedLines[user] = []
                            }else{
                                print("drawn path is not nil--------")
                            }
                            
                            drawn_paths = self.addedLines[user]
                            
                            if drawn_paths!.isEmpty {
                                self.addedLines[user] = polyline_list
                                
                            }else{
                                for item in drawn_paths! {
                                    print("deleting a drawn path--------")
                                    item.map = nil
                                }
                                
                                self.addedLines.removeValue(forKey: user)
                                self.addedLines[user] = polyline_list
                            }
                            
                            self.runAnimationForDirection(polyline_list, 1.0)
                        }
                    }
                                        
                    
                } else {
                   // couldn't load JSON, look at error
                }
            }catch {
            
            }


        })
    }
    
    func getPubUsersLocation(_ user_id: String) -> LatLng? {
        var pub_user = self.getSharedLocationUserIfExists(user_id: user_id)
        var json = pub_user!.loc_pack!
        
//        print("json : \(json)")
        
        let decoder = JSONDecoder()
        let jsonData = json.data(using: .utf8)!
        
        do{
            let shared_user_ld: location_packet =  try decoder.decode(location_packet.self, from: jsonData)
            
            if !shared_user_ld.received_locations.isEmpty{
                let picked_loc = shared_user_ld.received_locations[0].lat
                
                return picked_loc
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    struct shared_user_location_data: Codable{
        var creation_time = 0
        var uid = ""
        var loc_pack = location_packet()
    }
    
    struct location_packet: Codable{
        var received_locations = [Location_Item]()
        var geo_string = ""
        var location_desc = ""
    }
    
    struct Location_Item: Codable{
        var creation_time = 0
        var lat = LatLng()
    }
    
    struct LatLng: Codable{
        var latitude = 0.0
        var longitude = 0.0
    }
    
    func getAppropriateUsers() -> [String]{
        self.publicUsersToShow.removeAll()
        let pub_users = self.getSharedLocationUsersIfExists()
        var picked_users = [String]()
        
        for item in pub_users{
            picked_users.append(item.uid!)
        }
        return picked_users
        
        
        return picked_users
    }
    
    func loadJobOwner(){
        let the_job = self.getJobIfExists(job_id: job_id)!
        let owner_id = the_job.uploader_id!
        let owner_acc = self.getApplicantAccount(user_id: owner_id)
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(owner_id)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            self.jobOwnerImage.image = im
              
            let image = self.jobOwnerImage!
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
                self.jobOwnerImage.image = im
                
                let image = self.jobOwnerImage!
                image.layer.borderWidth = 1
                image.layer.masksToBounds = false
                image.layer.borderColor = UIColor.white.cgColor
                image.layer.cornerRadius = image.frame.height/2
                image.clipsToBounds = true
                
                self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: owner_id)
            }
          }
        }
        
        ownerNameLabel.text = owner_acc!.name!
        
        var ratings = self.getAccountRatings(owner_acc!.uid!)
        
        //set the job owners number of ratings
        ownerRatingsLabel.text = "\(ratings.count) Ratings."
        if ratings.count == 1 {
            ownerRatingsLabel.text = "\(ratings.count) Rating."
        }else if ratings.count == 0 {
            ownerRatingsLabel.text = "New!"
        }
        
        
        setRatingView.settings.fillMode = .precise
        setRatingView.didTouchCosmos = { rating in
            self.setRatingNumberLabel.text = "\(round(10 * rating)/10)"
            self.job_owner_rating = (round(10 * rating)/10)
        }
        
        setRatingView.didFinishTouchingCosmos = { rating in
            print("send \(rating) to the db")
            self.set_rating()
        }
        
        
        var my_id = Auth.auth().currentUser!.uid
        var rating_id = my_id+job_id
        print("checking for rating \(rating_id)")
        var existing_rating = self.getRatingIfExists(rating_id: rating_id)
        
        if existing_rating != nil {
            removeRatingButton.isHidden = false
            setRatingView.rating = existing_rating!.rating
            setRatingNumberLabel.text = "\(round(10 * existing_rating!.rating)/10)"
        }else{
            removeRatingButton.isHidden = true
        }
        
    }
    
    func loadPickedWorker(user: String){
        ratings.removeAll()
        rated_users.removeAll()
        
        ratings[user] = 4.2
        rated_users.append(user)
        
        setApplicantRatingView.settings.fillMode = .precise
        setApplicantRatingView.didTouchCosmos = { rating in
            self.setApplicantRatingNumberLabel.text = "\(round(10 * rating)/10)"
            self.ratings[user] = (round(10 * rating)/10)
        }
        
        setApplicantRatingView.didFinishTouchingCosmos = { rating in
            print("send \(rating) to the db")
            self.set_rating()
        }
        
        let me = Auth.auth().currentUser?.uid
        
        var account = self.getApplicantAccount(user_id: user)
        var rating_id = me!+job_id
        var existing_rating = self.getRatingIfExists(rating_id: rating_id)
        var account_ratings = self.getAccountRatings(user)
        
        setApplicantRatingView.rating = ratings[user] ?? 4.0
        setApplicantRatingNumberLabel.text = "4.0"
        
        removeApplicantRatingButton.isHidden = true
        if existing_rating != nil{
            print("loaded a rating: \(round(10 * existing_rating!.rating)/10)")
            setApplicantRatingView.rating = round(10 * existing_rating!.rating)/10
            setApplicantRatingNumberLabel.text = "\(round(10 * existing_rating!.rating)/10)"
            removeApplicantRatingButton.isHidden = false
        }
    }
    
    func loadMyApplicationDetails(){
        var my_id = Auth.auth().currentUser!.uid
        var myAccount = self.getApplicantAccount(user_id: my_id)
        myapplicantNameLabel.text = myAccount!.name
        
        let my_application = self.getAppliedJobIfExists(job_id: job_id)
        
        if my_application != nil {
            //ive applied already
            myselectedLabel.isHidden = false
            myselectedLabel.text = "Applied!"
        }
        
        
        var ratings = self.getAccountRatings(myAccount!.uid!)
        
        //set the applicants number of ratings
        myapplicantsRatingsLabel.text = "\(ratings.count) Ratings."
        if ratings.count == 1 {
            myapplicantsRatingsLabel.text = "\(ratings.count) Rating."
        }else if ratings.count == 0 {
            myapplicantsRatingsLabel.text = "New!"
        }
        
        if job!.selected_workers != nil {
            var selected_users_json = job!.selected_workers!
            
            let decoder = JSONDecoder()
            let jsonData = selected_users_json.data(using: .utf8)!
            do{
                var selected_users = selected_workers()
                
                if selected_users_json != "" {
                    selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                }
                
                if selected_users.worker_list.contains(my_id){
                    //ive been selected
                    myselectedLabel.isHidden = false
                    myselectedLabel.text = "Selected!"
                }else{
                    if my_application == nil {
                        myselectedLabel.isHidden = true
                    }
                }
                
            }catch{
                print("error loading selected users")
            }
        }
        
        if !ratings.isEmpty {
            myapplicantHistoryView.isHidden = false
            
            myjobCountLabel.text = "\(ratings.count)"
            if ratings.count == 1 {
                myjobSubscriptLabel.text = "Job"
            }
            
            if ratings.count > 3 {
                var last3 = Array(ratings.suffix(3))
                var total = 0.0
                for item in last3 {
                    total += Double(item.rating)
                }
                myaverageRatingLabel.text = "\(round(10 * total/3.0)/10)"
            }else{
                //less than 3
                var total = 0.0
                for item in ratings {
                    total += Double(item.rating)
                }
                myaverageRatingLabel.text = "\(round(10 * total/Double(ratings.count))/10)"
                mylastRatingNumberLabel.text = "Last \(ratings.count)."
            }
            
            let my_id = Auth.auth().currentUser?.uid
            for item in ratings{
                if (item.job_id! == job_id){
                    print("changin selected word with \(item.rating)")
                    myselectedLabel.text = "Rated: \(round(10 * item.rating)/10)"
                    break
                }
            }
        }else{
            myapplicantHistoryView.isHidden = true
        }
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(my_id)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            self.myuserIconImage.image = im
              
            let image = self.myuserIconImage!
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
                    self.myuserIconImage.image = im
                    
                    let image = self.myuserIconImage!
                    image.layer.borderWidth = 1
                    image.layer.masksToBounds = false
                    image.layer.borderColor = UIColor.white.cgColor
                    image.layer.cornerRadius = image.frame.height/2
                    image.clipsToBounds = true
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: my_id)
                }
              }
        }
        
    }
    
    
    @IBAction func removeJobOwnerRatingTapped(_ sender: Any) {
        delete_rating("")
    }
    
    @IBAction func removeApplicantRatingTapped(_ sender: Any) {
        removeApplicantRatingButton.isHidden = true
        let me = Auth.auth().currentUser?.uid
        
        var account = self.getApplicantAccount(user_id: self.firstApplicantId)
        var rating_id = me!+job_id
        var existing_rating = self.getRatingIfExists(rating_id: rating_id)
        self.delete_rating(self.firstApplicantId)
        
        self.context.delete(existing_rating!)
        
        NotificationCenter.default.post(name: NSNotification.Name(self.constants.refresh_job), object: "listener")
    }
    
    
    func set_rating(){
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
        
        if amIAirworker(){
            let job_owner_acc = self.getApplicantAccount(user_id: job!.uploader_id!)
            let uploader_id = job!.uploader_id!
            var my_id = Auth.auth().currentUser!.uid
            
            let data: [String : Any] = [
                "rating": job_owner_rating,
                "rating_explanation": "",
                "user_id" : job!.uploader_id!,
                "job_country" : jobbo.country_name,
                "job_id" : job_id,
                "rating_time" : t_mills,
                "job_object" : job_json,
                "language" : jobbo.language
            ]
            
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
                        
                    }
                    
                }
            
        }
        else{
            for applicant in rated_users{
                let app_acc = self.getApplicantAccount(user_id: applicant)
                
                let data: [String : Any] = [
                    "rating": ratings[applicant]!,
                    "rating_explanation": "",
                    "user_id" : applicant,
                    "job_country" : jobbo.country_name,
                    "job_id" : job_id,
                    "rating_time" : t_mills,
                    "job_object" : job_json,
                    "language" : jobbo.language
                ]
                
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
                            
                            if self.rated_users.last == applicant{
                            }
                        }
                        
                    }
            }
            
            print("updated rating objects for each user")
        }
        
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
    
    func delete_rating(_ applicant: String){
        let jobbo = jobAsInCodable(job_id)
        let job_ob = self.getJobIfExists(job_id: job_id)
        let t_mills = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        if self.amIAirworker(){
            let uploader_id = job!.uploader_id!
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
                    
                    }
                    
                }
        }
    }
    
    func jobAsInCodable(_ job_id: String) -> encodable_job{
        let job = self.getJobIfExists(job_id: job_id)
        
        var enc_job = encodable_job()
        enc_job.job_title = job!.job_title!
        enc_job.job_details = job!.job_details!
        enc_job.job_worker_count = Int(job!.job_worker_count)
        
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
    
    struct selected_workers: Codable{
        var worker_list = [String]()
    }
    
    
    
    @objc func whenViewApplicantTapped(sender:UITapGestureRecognizer) {
        viewApplicantButton.sendActions(for: .touchUpInside)
    }
    
    func moveCamera(_ lat: Double,_ long: Double){
        locationMap.animate(to: GMSCameraPosition(latitude: lat, longitude: long, zoom: 15))
        
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch(segue.identifier ?? "") {
                        
        case "viewTopApplicant":
            guard let applicantDetailViewController = segue.destination as? ApplicantViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            var applicants = self.getJobApplicantsIfExists(job_id: job!.job_id!)
            
            applicantDetailViewController.applicant_id = applicants[0].applicant_uid!
            
            applicantDetailViewController.job_id = job_id
            
        case "jobApplicantsSegue":
            guard let allApplicantsViewController = segue.destination as? AllApplicantsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            allApplicantsViewController.job_id = job_id
        
        case "takeDownSegue":
            guard let takeDownViewController = segue.destination as? TakeDownViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            takeDownViewController.job_id = job_id
            
        case "editJobSegue":
            guard let editViewController = segue.destination as? EditJobViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            editViewController.job_id = job_id
            
        case "rateWorkersSegue":
            guard let rateWorkersViewController = segue.destination as? RateWorkersViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            rateWorkersViewController.job_id = job_id
            
        case "showJobOwnerRatings":
            guard let jobHistoryViewController = segue.destination as? JobHistoryViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            jobHistoryViewController.applicant_id = job!.uploader_id!
            jobHistoryViewController.job_id = job!.job_id!
            
        case "applyForJobSegue":
            guard let applyViewController = segue.destination as? ApplyForJobViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            applyViewController.job_id = job_id
            
        case "showPendingRatingsFirst":
            guard let pendingVC = segue.destination as? PendingRatingsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            pendingVC.hideSkipButton = true
            
        case "showPdfDoc":
            guard let pdfVc = segue.destination as? ViewPdfViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let user_id = job!.uploader_id!
            let storageRef = Storage.storage().reference()
            
            let ref = storageRef.child(constants.users_data)
                .child(user_id)
                .child(constants.job_document)
                .child("\(job_id).pdf")
            
            pdfVc.picked_doc = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!.data
            
        default:
            print("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == jobImagesCollectionView {
            return job_images.count
        } else if collectionView == jobTagsCollectionView {
            return jobTags.count
        }else if collectionView == applicantsImagesCollection{
            return self.jobApplicants.count
        }else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == jobImagesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "viewJobImage", for: indexPath) as! viewJobImageCollectionViewCell
            
            let uid = job!.uploader_id!
            
            let storageRef = Storage.storage().reference()
            let ref = storageRef.child(constants.users_data)
                .child(uid)
                .child(constants.job_images)
                .child("\(job_images[indexPath.row].name).jpg")
            
            if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
                let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
                let im = UIImage(data: resource.data!)
                cell.job_image.image = im
                  
                let image = cell.job_image!
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
                        cell.job_image.image = im
                        
                        let image = cell.job_image!
                        image.layer.borderWidth = 1
                        image.layer.masksToBounds = false
                        image.layer.borderColor = UIColor.white.cgColor
                        image.layer.cornerRadius = image.frame.height/2
                        image.clipsToBounds = true
                        
                        self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: uid)
                    }
                  }
            }
            
            
            return cell
        }
        else if collectionView == jobTagsCollectionView {
            let reuseIdentifier = "HomeViewJobTagCell"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ViewJobTagCollectionViewCell
            let tag = jobTags[indexPath.row]
            cell.view_job_tag.text = tag.title
            
            return cell
        }else if collectionView == applicantsImagesCollection{
            let reuseIdentifier = "JobDetailsApplicantImageCell"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ViewJobApplicantImageCollectionViewCell
            
            let applicant = jobApplicants[indexPath.row]
            
            let storageRef = Storage.storage().reference()
            let ref = storageRef.child(constants.users_data)
                .child(applicant)
                .child("avatar.jpg")
            
            if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
                let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
                let im = UIImage(data: resource.data!)
                cell.applicantImage.image = im
                  
                let image = cell.applicantImage!
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
                        cell.applicantImage.image = im
                        
                        let image = cell.applicantImage!
                        image.layer.borderWidth = 1
                        image.layer.masksToBounds = false
                        image.layer.borderColor = UIColor.white.cgColor
                        image.layer.cornerRadius = image.frame.height/2
                        image.clipsToBounds = true
                        
                        self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: applicant)
                    }
                  }
            }
            
            
            return cell
        }
        else{
            fatalError("Unexpected collection")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         // handle tap events
         print("You selected cell \(indexPath.item)!")
        
        if collectionView == applicantsImagesCollection{
            var user_id = self.jobApplicants[indexPath.row]
            var drawn_paths = self.addedLines[user_id]
            
//            print("drawn paths count: \(drawn_paths!.count)")
            
            if drawn_paths != nil {
                self.runAnimationForDirection(drawn_paths!, 0.1)
            }
        }
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
    
    func getJobImages(images_json: String) -> [job_image]{
        let decoder = JSONDecoder()
        
        do{
            let jsonData = images_json.data(using: .utf8)!
            let job_images =  try decoder.decode(job_image_list.self, from: jsonData)
            
            return job_images.set_images
        }catch{
            print("error loading job images")
        }
        
        return job_image_list().set_images
    }
    
    struct job_image_list: Codable {
        var set_images = [job_image]()
    }
    
    struct job_image: Codable{
        var name = ""
        var is_new_item = false
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
    
    func getSharedLocationUserIfExists(user_id: String) -> SharedLocationUser? {
        do{
            let request = SharedLocationUser.fetchRequest() as NSFetchRequest<SharedLocationUser>
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
    

    func isAccountVerified(user: Account) -> Bool{
        if user.email_verification_obj == nil || user.email_verification_obj! == "" {
            print("user.email_verification_obj is empy or nil")
            return false
        }
        
        if user.phone_verification_obj == nil || user.phone_verification_obj! == "" {
            print("user.phone_verification_obj is empy or nil")
            return false
        }
        
        return true
    }
    
    func isApplicantVerified(user: Account) -> Bool {
        if user.email_verification_obj == nil || user.email_verification_obj! == "" {
            print("user.email_verification_obj is empy or nil")
            return false
        }
        
        if user.phone_verification_obj == nil || user.phone_verification_obj! == "" {
            print("user.phone_verification_obj is empy or nil")
            return false
        }
        
        if user.scan_id_data == nil || user.scan_id_data! == "" {
            print("user.scan_id_data is empy or nil")
            return false
        }
        
        return true
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

            var req_id_format = "\(job!.uploader_id!)\(job_id!)"
            if amIAirworker(){
                var unreq_id_format = "\(job_id!)"
                if item.rating_id! != unreq_id_format{
                    filtered_items.append(item)
                }
            }else{
                if item.rating_id! != req_id_format{
                    filtered_items.append(item)
                }
            }
        }

        return filtered_items
    }
    
//    func filterRatings(ratings: [Rating]) -> [Rating] {
//        var filtered_items = [Rating]()
//
//        for item in ratings {
//            let job_id = item.job_id
//            let job = self.getJobIfExists(job_id: job_id!)
//
//            let req_id_format = "\(job!.uploader_id!)\(job!.job_id!)"
//            if item.rating_id! == req_id_format{
//                filtered_items.append(item)
//            }
//        }
//
//        return filtered_items
//    }
    
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
    
    func getSharedLocationUsersIfExists() -> [SharedLocationUser] {
        do{
            let request = SharedLocationUser.fetchRequest() as NSFetchRequest<SharedLocationUser>
//            let predic = NSPredicate(format: "user_id == %@", user_id)
//            request.predicate = predic
            
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
