//
//  HomeViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 29/12/2020.
//

import UIKit
import Firebase
import CoreData
import GoogleMaps
import MapKit
import CoreLocation

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GMSMapViewDelegate, CLLocationManagerDelegate,  UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate{
    @IBOutlet weak var newJobCardView: UIView!
    @IBOutlet weak var homePageScrollView: UIScrollView!
    
    @IBOutlet weak var openPendingRatingsButton: UIButton!
    @IBOutlet weak var openNewJobsButton: UIButton!
    @IBOutlet weak var requestDeliveryView: UIView!
    @IBOutlet weak var pickPersonView: UIView!
    @IBOutlet weak var pickPersonButton: UIButton!
    
    //part for interacting with map
    @IBOutlet weak var appliedJobsTableView: UITableView!
    @IBOutlet weak var appliedJobsContainer: UIView!
    @IBOutlet weak var jobsMapContainer: UIView!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var jobsCollectionView: UICollectionView!
    @IBOutlet weak var newJobIconsContainer: UIView!
    @IBOutlet weak var pickUserContainer: UIView!
    @IBOutlet weak var publicUsersCollection: UICollectionView!
    @IBOutlet weak var sendQuickJobContainer: CardView!
    @IBOutlet weak var sendCustomJobContainer: CardView!
    
    
    //parts for airwork user
    @IBOutlet weak var quickJobsContainer: UIView!
    @IBOutlet weak var quickJobsTableView: UITableView!
    @IBOutlet weak var quickJobButton: UIButton!
    
    
    //extras
    @IBOutlet weak var openQuickJobDetailsButton: UIButton!
    @IBOutlet weak var openQuickJobApplicantsButton: UIButton!
    @IBOutlet weak var openFirstQuickJobApplicantButton: UIButton!
    
    //part for airworker account info
    @IBOutlet weak var myAccountContainer: UIView!
    @IBOutlet weak var myAccountName: UILabel!
    @IBOutlet weak var myAccountRatingsLabel: UILabel!
    @IBOutlet weak var myAccountJobsCount: UILabel! //used for account age instead...
    @IBOutlet weak var myAccountAvatar: UIImageView!
    
    //part for selected job
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var jobDateLabel: UILabel!
    @IBOutlet weak var jobAmountLabel: UILabel!
    @IBOutlet weak var tagsCollection: UICollectionView!
    @IBOutlet weak var jobTimeLabel: UILabel!
    @IBOutlet weak var jobDurationLabel: UILabel!
    @IBOutlet weak var jobOwnerImage: UIImageView!
    @IBOutlet weak var ownerNameLabel: UILabel!
    @IBOutlet weak var ownerRatingsLabel: UILabel!
    
    //part for create job from tags
    @IBOutlet weak var searchTagContainer: UIView!
    @IBOutlet weak var searchTagField: UITextField!
    @IBOutlet weak var quckJobTagsCollection: UICollectionView!
    @IBOutlet weak var createJobFromTagsButton: UIButton!
    @IBOutlet weak var createJobFromTagsButtonContainer: CardView!
    @IBOutlet weak var jobTagPrices: UILabel!
    @IBOutlet weak var createNewTagButton: UIButton!
    
    
    @IBOutlet weak var switchAccountContainer: UIView!
    @IBOutlet weak var switchTitleLabel: UILabel!
    @IBOutlet weak var switchDetailsLabel: UILabel!
    @IBOutlet weak var pendingRatingsContainer: UIView!
    
    @IBOutlet weak var createAccountContainer: UIView!
    @IBOutlet weak var verifyIdentityContainer: UIView!
    @IBOutlet weak var verifyEmailContainer: UIView!
    @IBOutlet weak var addCertificateContainer: UIView!
    
    @IBOutlet weak var hiddenSignUpButton: UIButton! //above request custom job container
    @IBOutlet weak var hiddenSignUpButton2: UIButton! //above create job from picked tags button
    @IBOutlet weak var hiddenSignUpButton3: UIButton! //above the send quick job button
    @IBOutlet weak var hiddenSignUpButton4: UIButton! // above the send custom job button
    @IBOutlet weak var hiddenViewPendingRatingsButton: UIButton!
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let db = Firestore.firestore()
    var constants = Constants.init()
    
    var setAccountListners: [ListenerRegistration] = [ListenerRegistration]()
    var setContactListners = [String : [ListenerRegistration]]()
    var setJobListeners = [String : [ListenerRegistration]]()
    var setOtherAccountListeners = [String : [ListenerRegistration]]()
    var setTagListeners = [String : [ListenerRegistration]]()
    var setPublicDataListeners: [ListenerRegistration] = [ListenerRegistration]()
    var newJobDataListener: ListenerRegistration?
    

    var myJobs = [Job]()
    var my_applied_jobs = [Job]()
    var selectedQuickJob = ""
    var pickedQuickJob = "" //for quick job picked
    var new_jobs = [String]()
    
    
    let locationManager = CLLocationManager()
    var myLat = 0.0
    var myLong = 0.0
    var myLocationMarker: GMSMarker?
    var myLocationCircle: GMSCircle?
    var addedMarkers = [String : GMSMarker]()
    var addedLines = [String : [GMSPolyline]]()
    
    let MAX_DISTANCE_TRHESHOLD = 7000.0
    var has_loaded_map = false
    
    var jobTags = [JobTag]()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        print("is account type airworker? \(self.amIAirworker())")
        setUpViews()
    }
    
    
    @objc func whenAppTerminated(){
        print("app is being terminated")
        removeFirebaseListeners()
    }
    
    @objc func didGetNotification(_ notification: Notification){
//        let text = notification.object as! String
        
    }
    
    @IBAction func whenHiddenSignUpButtonTapped(_ sender: Any) {
        self.hiddenSignUpButton.sendActions(for: .touchUpInside)
    }
    
    @IBAction func whenHiddenSignUpButton2Tapped(_ sender: Any) {
        self.hiddenSignUpButton.sendActions(for: .touchUpInside)
    }
    
    @IBAction func whenHiddenSignUpButton3Tapped(_ sender: Any) {
        self.hiddenSignUpButton.sendActions(for: .touchUpInside)
    }
    
    @IBAction func whenHiddenViewPendingRatingsTapped(_ sender: Any) {
        openPendingRatingsButton.sendActions(for: .touchUpInside)
    }
    
    
    
    func setUpViews(){
        removeFirebaseListeners()
        setMyAccountDataListeners()
        listenForPublicLocationData()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.whenAppTerminated), name: UIApplication.willTerminateNotification, object:nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: "name"), object: nil)
        
        setUpAppliedJobs()
        setUpQuickJobs()
        setUpQuickTags()
        
        pendingRatingsContainer.isHidden = true
        
        
        
        if amIAirworker(){
            self.title = "Airworker"
            switchTitleLabel.text = "Switch To Airwork"
            switchDetailsLabel.text = "Use the fastest job network to find and hire people on demand."
            setAccountInfo()
            
            newJobCardView.isHidden = true
            appliedJobsContainer.isHidden = false
//            jobsMapContainer.isHidden = false
            pickUserContainer.isHidden = true
            quickJobsContainer.isHidden = true
            myAccountContainer.isHidden = false
            searchTagContainer.isHidden = true
            
            
            getUnpaidJobs()
            setUpJobMap()
            
        }else{
            self.title = "Home"
            switchTitleLabel.text = "Switch To Airworker"
            switchDetailsLabel.text = "Access the fastest job network to find job opportunities and be productive."
            
            
            newJobCardView.isHidden = false
            appliedJobsContainer.isHidden = true
//            jobsMapContainer.isHidden = true
            pickUserContainer.isHidden = false
            quickJobsContainer.isHidden = false
            myAccountContainer.isHidden = true
            searchTagContainer.isHidden = false
            
            pendingRatingsContainer.isHidden = true
            getPendingJobs()
            
            
            if !myJobs.isEmpty{
                openPendingRatingsButton.isHidden = false
                openNewJobsButton.isHidden = true
            }else{
                openPendingRatingsButton.isHidden = true
                openNewJobsButton.isHidden = false
            }
            
            
            let new_job_tap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.whenNewJobViewTapped))
            let pick_user_tap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.whenViewPeopleViewTapped))

            requestDeliveryView.addGestureRecognizer(new_job_tap)
            pickPersonView.addGestureRecognizer(pick_user_tap)
            
            setPublicUsers()
        }
        
        self.updateLinks()
    }
    
    func updateViews(){
        pendingRatingsContainer.isHidden = true
        
        
        if amIAirworker(){
            self.title = "Airworker"
            switchTitleLabel.text = "Switch To Airwork"
            switchDetailsLabel.text = "Use the fastest job network to find and hire people on demand."
            setAccountInfo()
            
            newJobCardView.isHidden = true
            appliedJobsContainer.isHidden = false
//            jobsMapContainer.isHidden = false
            quickJobsContainer.isHidden = true
            myAccountContainer.isHidden = false
            searchTagContainer.isHidden = true
            
            
//            getUnpaidJobs()
//            setUpJobMap()
//            setUpAppliedJobs()
            appliedJobsTableView.reloadData()
            
        }else{
            self.title = "Home"
            switchTitleLabel.text = "Switch To Airworker"
            switchDetailsLabel.text = "Access the fastest job network to find job opportunities and be productive."
            
            
            newJobCardView.isHidden = false
            appliedJobsContainer.isHidden = true
//            jobsMapContainer.isHidden = true
            quickJobsContainer.isHidden = false
            myAccountContainer.isHidden = true
            searchTagContainer.isHidden = false
            
            pendingRatingsContainer.isHidden = true
//            getPendingJobs()
//            setUpQuickJobs()
//            setUpQuickTags()
            
            if !myJobs.isEmpty{
                openPendingRatingsButton.isHidden = false
                hiddenViewPendingRatingsButton.isHidden = false
                openNewJobsButton.isHidden = true
            }else{
                openPendingRatingsButton.isHidden = true
                hiddenViewPendingRatingsButton.isHidden = true
                openNewJobsButton.isHidden = false
            }
            
        }
        
        self.updateLinks()
    }
    
    func updateLinks(){
        let uid = Auth.auth().currentUser?.uid
        var account = self.getAccountIfExists(uid: uid!)
        var app = self.getAppDataIfExists()
        let time = Int(round(NSDate().timeIntervalSince1970 * 1000))
        if app == nil {
            app = AppData(context: self.context)
            app?.global_tag_data_update_time = Int64(time)
        }
        if account != nil {
            
            self.verifyIdentityContainer.isHidden = true
            if Auth.auth().currentUser!.isAnonymous {
                self.addCertificateContainer.isHidden = true
                self.verifyEmailContainer.isHidden = true
                self.verifyIdentityContainer.isHidden = true
                self.createAccountContainer.isHidden = false
                
                self.hiddenSignUpButton.isHidden = false
                self.hiddenSignUpButton2.isHidden = false
                self.hiddenSignUpButton3.isHidden = false
                self.hiddenSignUpButton4.isHidden = false
            }else{
                self.createAccountContainer.isHidden = true
                self.hiddenSignUpButton.isHidden = true
                self.hiddenSignUpButton2.isHidden = true
                self.hiddenSignUpButton3.isHidden = true
                self.hiddenSignUpButton4.isHidden = true
                
                if amIAirworker(){
                    self.addCertificateContainer.isHidden = false
                    
                    if (account?.scan_id_data != nil && account?.scan_id_data != ""){
                        self.verifyIdentityContainer.isHidden = true
                    }else{
                        self.verifyIdentityContainer.isHidden = false
                    }
                }else{
                    self.addCertificateContainer.isHidden = true
                }
                
                if (self.isEmailVerified()){
                    self.verifyEmailContainer.isHidden = true
                }else{
                    self.verifyEmailContainer.isHidden = false
                }
                
               
                
            }
        }
    }
    
    
    var my_jobs = [String]()
    var my_job_ratings: [String: Double] = [String: Double]()
    func getUnpaidJobs(){
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
        
        if !my_received_ratings_jobs.isEmpty {
            self.pendingRatingsContainer.isHidden = false
        }else{
            self.pendingRatingsContainer.isHidden = true
        }
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
    
    
    
    
    
    
    func setAccountInfo(){
        var my_id = Auth.auth().currentUser!.uid
        var myAccount = self.getAccountIfExists(uid: my_id)!
        
        myAccountName.text = myAccount.name!
        
        var ratings = self.getAccountRatings(myAccount.uid!)
        
        //set the applicants number of ratings
        myAccountRatingsLabel.text = "\(ratings.count) Ratings."
        if ratings.count == 1 {
            myAccountRatingsLabel.text = "\(ratings.count) Rating."
        }else if ratings.count == 0 {
            myAccountRatingsLabel.text = "New!"
        }
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(my_id)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            self.myAccountAvatar.image = im
              
            let image = self.myAccountAvatar!
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
                    self.myAccountAvatar.image = im
                    
                    let image = self.myAccountAvatar!
                    image.layer.borderWidth = 1
                    image.layer.masksToBounds = false
                    image.layer.borderColor = UIColor.white.cgColor
                    image.layer.cornerRadius = image.frame.height/2
                    image.clipsToBounds = true
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: my_id)
                }
              }
        }
        
        let unixTimestamp = Double(myAccount.sign_up_time)/1000
        let date = Date(timeIntervalSince1970: unixTimestamp)
        
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
            myAccountJobsCount.text = "\(timeOffset) old."
        }else{
            myAccountJobsCount.text = "\(timeOffset) old."
        }
    }
    
    var pickedUsers: [String] = []
    var selectedUsers: [String] = []
    var addedCircles = [String : GMSCircle]()
    
    func setPublicUsers(){
        pickedUsers = getAppropriateUsers()
        publicUsersCollection.delegate = self
        publicUsersCollection.dataSource = self
        
        if pickedUsers.isEmpty{
            publicUsersCollection.isHidden = true
        }else{
            publicUsersCollection.isHidden = false
        }
        
        setUpJobMap()
    }
    
    func getAppropriateUsers() -> [String]{
        self.pickedUsers.removeAll()
        let pub_users = self.getSharedLocationUsersIfExists()
        var picked_users = [String]()
        var picked_users_and_ratings: [users_and_ratings] = [users_and_ratings]()
        
        if selectedTags.isEmpty{
            for item in pub_users{
                picked_users.append(item.uid!)
            }
            let sorted_users = picked_users.sorted { getRatingsMatchingPickedTags($0).count > getRatingsMatchingPickedTags($1).count }
           
            return sorted_users
        }
        
        for user in pub_users{
            let matching_ratings = getRatingsMatchingPickedTags(user.uid!)
            let matching_jobs = getApplicationsMatchingPickedTags(user_id: user.uid!)
            
            if !matching_jobs.isEmpty || !matching_ratings.isEmpty{
                if(!picked_users.contains(user.uid!)){
                    picked_users.append(user.uid!)
                }
            }
        }
        
        if !selectedUsers.isEmpty{
            for user in selectedUsers{
                if(!picked_users.contains(user)){
                    picked_users.append(user)
                    
                }
            }
        }
        
        let sorted_users = picked_users.sorted { getRatingsMatchingPickedTags($0).count > getRatingsMatchingPickedTags($1).count }
        
        return sorted_users
    }
    
    struct users_and_ratings{
        var uid  = ""
        var rating = 0
    }
    
    func getRatingsMatchingPickedTags(_ user_id: String) -> [Rating]{
        var user_ratings = self.getAccountRatings(user_id)
        for r in user_ratings{
//            print("\(user_id) sent rating to \(r.user_id)")
        }
        
//        var added_rating_job_ids = [String]()
//        for r in self.getAccountRatings(user_id){
//            if !added_rating_job_ids.contains(r.job_id!) {
//                print("\(user_id) : adding rating: \(r.job_id!)")
//                user_ratings.append(r)
//                added_rating_job_ids.append(r.job_id!)
//            }
//        }
        
        let user = self.getAccountIfExists(uid: user_id)
        
        let uploaded_jbs = self.getUploadedJobsIfExists()
        var up_job_ids = [String]()
        for item in uploaded_jbs {
            up_job_ids.append(item.job_id!)
        }
        
        let me_uid = Auth.auth().currentUser!.uid
        var picked_ratings = [Rating]()

        
        if selectedTags.isEmpty{
            for rating in user_ratings{
                let job_id = rating.job_id
                let job = self.getJobIfExists(job_id: job_id!)
                
                if (job != nil) {
                    let correct_id = "\(job!.uploader_id!)\(job!.job_id!)"
                    if (rating.rating_id! == correct_id) {
                        picked_ratings.append(rating)
                    }else{
                        print("Rating_id -> \(rating.rating_id!) : correct id -> \(correct_id)")
                    }
                    
                }else{
                    
                }
            }
            return picked_ratings
        }else{
            for item in user_ratings{
                let job_id = item.job_id
                let job = self.getJobIfExists(job_id: job_id!)
                
                if (job != nil) {
                    if job!.uploader_id! != me_uid{
                        var jobTags = [JobTag]()
                        for tag in job!.tags! {
                            jobTags.append(tag as! JobTag)
                        }
                        
                        for tag in jobTags{
                            if selectedTags.contains(tag.title!) {
                                //the rating can be used
                                picked_ratings.append(item)
                                break
                            }
                        }
                    }
                }
            }
            
            return picked_ratings
        }
    }
    
    func getApplicationsMatchingPickedTags(user_id: String) -> [JobApplications]{
        let user_applications = self.getJobApplicationsIfExists(user_id: user_id)
        var picked_applications = [JobApplications]()
        
        if selectedTags.isEmpty{
            return user_applications
        }else{
            for item in user_applications {
                let job = self.getJobIfExists(job_id: item.job_id!)
                
                if job != nil {
                    var jobTags = [JobTag]()
                    for tag in job!.tags! {
                        jobTags.append(tag as! JobTag)
                    }
                    
                    for tag in jobTags{
                        if selectedTags.contains(tag.title!) {
                            //the rating can be used
                            picked_applications.append(item)
                            break
                        }
                    }
                }
            }
            
            return picked_applications
        }
        
    }
    
    func getPubUsersLocation(_ user_id: String) -> LatLng? {
        var pub_user = self.getSharedLocationUserIfExists(user_id: user_id)
        var json = pub_user!.loc_pack!
        
        print("json : \(json)")
        
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
    
    func getJobApplicationsIfExists(user_id: String) -> [JobApplications] {
        do{
            let request = JobApplications.fetchRequest() as NSFetchRequest<JobApplications>
            let predic = NSPredicate(format: "user_id == %@ ", user_id)
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
    
    
    
    
    
    // MARK: - Job Map Parts
    func setUpJobMap(){
        if amIAirworker() {
            let newJobs = self.getNewJobsIfExists()
            new_jobs.removeAll()
            
            for item in newJobs{
                if (isJobOk(job: item) && item.location_desc != nil && item.location_desc! != ""){
                    new_jobs.append(item.job_id!)
                }
            }
        }else{
            
        }
        
                
        //lets load the map
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
            
            if !has_loaded_map {
                has_loaded_map = true
                
                do {
                     if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                        if UITraitCollection.current.userInterfaceStyle == .dark {
                            mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                        }else{
                            if let styleURL2 = Bundle.main.url(forResource: "light-style", withExtension: "json") {
                                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL2)
                            }
                            
                        }
                     } else {
                       NSLog("Unable to find style.json")
                     }
                } catch {
                     NSLog("One or more of the map styles failed to load. \(error)")
                }
                
                mapView.layer.cornerRadius = 15
                mapView.isUserInteractionEnabled = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `2.0` to the desired number of seconds.
                   // Code you want to be delayed
                    
//                    self.addJobsOnMap()
                }
                
                
            }
            
        }
        
        if amIAirworker(){
            jobsCollectionView.delegate = self
            jobsCollectionView.dataSource = self
            
            jobsCollectionView.reloadData()
            
            if new_jobs.isEmpty{
                newJobIconsContainer.isHidden = true
            }else{
                newJobIconsContainer.isHidden = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        if amIAirworker(){
            if(self.myLat == 0.0){
                self.myLat = -1.286389
    //                locValue.latitude
                self.myLong = 36.817223
    //                locValue.longitude
                
                self.moveCamera(self.myLat, self.myLong)
                self.setMyLocation(self.myLat, self.myLong)
                self.addJobsOnMap()
            }
            self.myLat = -1.286389
    //                locValue.latitude
            self.myLong = 36.817223
    //                locValue.longitude
        }else{
            if(self.myLat == 0.0){
                self.myLat = locValue.latitude
                self.myLong = locValue.longitude
                
                self.moveCamera(self.myLat, self.myLong)
                self.setMyLocation(self.myLat, self.myLong)
                self.setAllUsersOnMap()
            }
            self.myLat = locValue.latitude
            self.myLong = locValue.longitude
        }
    }
    
    func moveCamera(_ lat: Double,_ long: Double){
        mapView.animate(to: GMSCameraPosition(latitude: lat, longitude: long, zoom: 15))
    }
    
    func setMyLocation(_ lat: Double,_ long: Double){
        var position = CLLocationCoordinate2DMake(lat, long)
        var marker = GMSMarker(position: position)
        
        let circleCenter = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let circle = GMSCircle(position: circleCenter, radius: 600)
        
        circle.fillColor = UIColor(red: 113, green: 204, blue: 231, alpha: 0.1)
        circle.strokeColor = .none
        
        circle.map = mapView
        
        marker.icon = UIImage(named: "MyLocationIcon")
        marker.map = mapView
        
        self.myLocationMarker = marker
        self.myLocationCircle = circle
    
    }
    
    func addJobsOnMap(){
        var bounds = GMSCoordinateBounds()
        for item in new_jobs {
            //these are new jobs with a location
            let job = self.getJobIfExists(job_id: item)
            let user = job!.uploader_id!
            var user_ratings = self.getAccountRatings(user)
            var position = CLLocationCoordinate2DMake(job!.location_lat, job!.location_long)
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
            
            marker.icon = UIImage(named: "JobLocation")
            marker.map = mapView
            
            let coordinate₀ = CLLocation(latitude: myLat, longitude: myLong)
            let coordinate₁ = CLLocation(latitude: job!.location_lat, longitude: job!.location_long)
            
            if (self.getDistance(loc1: coordinate₀, loc2: coordinate₁) < self.MAX_DISTANCE_TRHESHOLD) {
                print("adding item to bounds")
                bounds = bounds.includingCoordinate(marker.position)
            }
            
            
        }
        
        
        if !new_jobs.isEmpty{
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//                let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
//                self.mapView.animate(with: update)
//            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.showJobOnMap(job_id: self.new_jobs[0])
            }
        }
    }
    
    func getDistance( loc1: CLLocation, loc2: CLLocation) -> Double {
        return loc2.distance(from: loc1)
    }
    
    func getAverage(_ ratings: [Rating]) -> Double{
        var total = 0.0
        for item in ratings {
            total += Double(item.rating)
        }
        return round(10 * total/Double(ratings.count))/10
    }
    
    
    var map_job_id = ""
    func showJobOnMap(job_id: String){
        print("showing job \(job_id) on map ~~~~~~~~~~~~")
        
        var path = addedLines[job_id]
        let job = self.getJobIfExists(job_id: job_id)
        
        self.setJobInfoForPickedNewJob(job: job!)
        self.map_job_id = job_id
        
        if path == nil {
            var new_path = GMSMutablePath()
            
            new_path.add(CLLocationCoordinate2D(latitude: self.myLat, longitude: self.myLong))
            new_path.add(CLLocationCoordinate2D(latitude: job!.location_lat, longitude: job!.location_long))
            
            
            var polyline_list = [GMSPolyline]()
            
            let polyline = GMSPolyline(path: new_path)
            polyline.geodesic = true
            let color = self.getLineColorForUser(job_id: job_id)
            polyline.strokeColor = color
            polyline.strokeWidth = 3
            polyline.map = mapView
            
            polyline_list.append(polyline)
            self.addedLines[job_id] = polyline_list
            
            let coordinate₀ = CLLocation(latitude: self.myLat, longitude: self.myLong)
            let coordinate₁ = CLLocation(latitude: job!.location_lat, longitude: job!.location_long)
            
            if (self.getDistance(loc1: coordinate₀, loc2: coordinate₁) < self.MAX_DISTANCE_TRHESHOLD) {
                //I only want to show directions for people close to me
                self.getRoadPathToUser(job_id, self.myLat, self.myLong, job!.location_lat, job!.location_long)

            }
        }else{
            print("removing drawn paths-------")
            for item in path! {
                item.map = nil
            }
            path!.removeAll()
            
            let coordinate₀ = CLLocation(latitude: self.myLat, longitude: self.myLong)
            let coordinate₁ = CLLocation(latitude: job!.location_lat, longitude: job!.location_long)
            
            if (self.getDistance(loc1: coordinate₀, loc2: coordinate₁) < self.MAX_DISTANCE_TRHESHOLD) {
                //I only want to show directions for people close to me
                self.getRoadPathToUser(job_id, self.myLat, self.myLong, job!.location_lat, job!.location_long)

            }
        }
        

        
        var bounds = GMSCoordinateBounds()
        var position = CLLocationCoordinate2DMake(self.myLat, self.myLong)
        var position2 = CLLocationCoordinate2DMake(job!.location_lat, job!.location_long)
        bounds = bounds.includingCoordinate(position)
        bounds = bounds.includingCoordinate(position2)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
            self.mapView.animate(with: update)
        }
        
        
        
    }
    
    func getRoadPathToUser(_ job_id: String,_ start_lat: Double,_ start_long: Double,_ end_lat: Double,_ end_long: Double){
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
                                var color = UIColor(named: "JobSeen")!
                                if self.amIAirworker(){
                                    color = self.getLineColorForUser(job_id: job_id)
                                }
                                
                                polyline.strokeColor = color
                                polyline.strokeWidth = 3
                                
                                polyline_list.append(polyline)
                                
                            }
                        }
                    
                        if !polyline_list.isEmpty {
                            var drawn_paths = self.addedLines[job_id]

                            if drawn_paths == nil {
                                print("drawn path is nil--------")
                                self.addedLines[job_id] = []
                            }else{
                                print("drawn path is not nil--------")
                            }

                            drawn_paths = self.addedLines[job_id]

                            if !drawn_paths!.isEmpty {
                                for item in drawn_paths! {
                                    print("deleting a drawn path--------")
                                    item.map = nil
                                }
                                self.addedLines.removeValue(forKey: job_id)
                            }
                            
                            self.addedLines[job_id] = polyline_list
                            self.runAnimationForDirection(polyline_list)
                        }
                    }
                                        
                    
                } else {
                   // couldn't load JSON, look at error
                }
            }catch {
            
            }


        })
    }
    
    var pos = 0
    func runAnimationForDirection(_ polyline_list : [GMSPolyline]){
        for item in polyline_list {
            item.map = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.pos == 0 {
                self.startAnimation(polyline_list)
            }
        }
    }
    
    func startAnimation(_ polyline_list : [GMSPolyline]){
        polyline_list[pos].map = mapView
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            print("running animation")
            self.pos += 1
            if polyline_list.count >= self.pos + 1 {
                self.startAnimation(polyline_list)
            }else{
                self.pos = 0
            }
        }
    }
    
    
    func getLineColorForUser(job_id: String) -> UIColor {
        var color = UIColor(red: 40, green: 40, blue: 40, alpha: 0.2)
//        color = UIColor(named: "JobUnseen")!
        color = UIColor(named: "JobSeen")!
        
        let me = Auth.auth().currentUser!.uid
        let job = self.getJobIfExists(job_id: job_id)
        var applied_users = [String]()
        var selected_users = [String]()
        
        if job!.selected_workers != nil {
            var selected_users_json = job!.selected_workers!
            let decoder = JSONDecoder()
            let jsonData = selected_users_json.data(using: .utf8)!
            
            do{
                if selected_users_json != "" {
                    selected_users = try decoder.decode(selected_workers.self ,from: jsonData).worker_list
                }
                
            }catch{
                print("error loading selected users")
            }
        }
        
        let applicant_objs = self.getJobApplicantsIfExists(job_id: job_id)
        for item in applicant_objs {
            applied_users.append(item.applicant_uid!)
        }
        
        if selected_users.contains(me){
            //picked line is a blue
//            color = UIColor(red: 0, green: 122, blue: 255, alpha: 0.7)
            color = UIColor(named: "JobApplied")!
        }else if applied_users.contains(me) {
//            color = UIColor(red: 40, green: 40, blue: 40, alpha: 0.3)
            color = UIColor(named: "JobSeen")!
        }
        
        return color
    }

    
    func setJobInfoForPickedNewJob(job: Job){
        jobTags.removeAll()
        for tag in job.tags! {
            jobTags.append(tag as! JobTag)
        }
        
        tagsCollection.delegate = self
        tagsCollection.dataSource = self
        tagsCollection.reloadData()
        
        jobTitleLabel.text = job.job_title!
        
        var hr = Int(job.time_hour)
        if job.am_pm == "PM" {
            hr += 12
        }
        
        let date = DateComponents(calendar: .current, year: Int(job.start_year), month: Int(job.start_month)+1, day: Int(job.start_day), hour: hr, minute: Int(job.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job.end_year), month: Int(job.end_month)+1, day: Int(job.end_day), hour: hr, minute: Int(job.time_minute)).date!
        
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
            jobDateLabel.text = "\(timeOffset) ago."
        }else{
            jobDateLabel.text = "In \(timeOffset)"
        }
        
        if job.work_duration! == "" {
            timeOffset = end_date.offset(from: date)
            if timeOffset == "" {
                timeOffset = date.offset(from: end_date)
            }
            jobDurationLabel.text = "\(timeOffset)"
            
        }else{
            if job.work_duration! == constants.durationless {
                jobDurationLabel.text = " "
            }else{
                jobDurationLabel.text = "\(job.work_duration!)"
            }
            
        }
        
        jobAmountLabel.text = "\(job.pay_currency!) \(job.pay_amount) Quoted."
        if job.pay_amount == 0 {
            jobAmountLabel.isHidden = true
        }else{
            jobAmountLabel.isHidden = false
        }
        
        jobTimeLabel.text = "At \(job.time_hour):\(job.time_minute)\(self.gett("a", date).lowercased())"
        
        //job owner part
        let owner_id = job.uploader_id!
        let owner_acc = self.getAccountIfExists(uid: owner_id)
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(owner_id)
            .child("avatar.jpg")
        
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
    }
    
    
    func setAllUsersOnMap(){
        var bounds = GMSCoordinateBounds()
        var position = CLLocationCoordinate2DMake(self.myLat, self.myLong)
        
        for user in pickedUsers{
            var their_loc = getPubUsersLocation(user)
            
            if their_loc != nil {
                var user_ratings = self.getRatingsMatchingPickedTags(user)
                var position = CLLocationCoordinate2DMake(their_loc!.latitude, their_loc!.longitude)
                var marker = GMSMarker(position: position)
                
                if user_ratings.isEmpty{
                    marker.title = "New!."
                }else if user_ratings.count == 1 {
                    marker.snippet = "\(user_ratings.count)"
                    marker.title = "★\(self.getAverage(user_ratings))"
                }else{
                    marker.snippet = "\(user_ratings.count)"
                    marker.title = "★\(self.getAverage(user_ratings))"
                }
                
                marker.icon = UIImage(named: "PickUserIcon")
                marker.map = mapView
                
                addedMarkers[user] = marker
                
                var position2 = CLLocationCoordinate2DMake(their_loc!.latitude, their_loc!.longitude)
                bounds = bounds.includingCoordinate(position2)
            }
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
            self.mapView.animate(with: update)
        }
    }
    
    func showAllPickedUsers(){
        var bounds = GMSCoordinateBounds()
        var position = CLLocationCoordinate2DMake(self.myLat, self.myLong)
        bounds = bounds.includingCoordinate(position)
        
        for user in selectedUsers{
            var their_loc = getPubUsersLocation(user)
            
            if their_loc != nil {
                var position2 = CLLocationCoordinate2DMake(their_loc!.latitude, their_loc!.longitude)
                bounds = bounds.includingCoordinate(position2)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if !self.selectedUsers.isEmpty{
                let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
                self.mapView.animate(with: update)
            }
        }
    }
    
    func drawLineToPickedUsers(){
        for item in addedLines.values {
            for line in item {
                line.map = nil
            }
            
        }
        for user in selectedUsers{
            var path = addedLines[user]
            var their_loc = getPubUsersLocation(user)
            self.map_job_id = user
            
            if their_loc != nil {
                if path == nil {
                    var new_path = GMSMutablePath()
                    
                    new_path.add(CLLocationCoordinate2D(latitude: self.myLat, longitude: self.myLong))
                    new_path.add(CLLocationCoordinate2D(latitude: their_loc!.latitude, longitude: their_loc!.longitude))
                    
                    
                    var polyline_list = [GMSPolyline]()
                    
                    let polyline = GMSPolyline(path: new_path)
                    polyline.geodesic = true
                    let color = UIColor(named: "JobApplied")!
                    polyline.strokeColor = color
                    polyline.strokeWidth = 3
                    polyline.map = mapView
                    
                    polyline_list.append(polyline)
                    self.addedLines[user] = polyline_list
                    
                    let coordinate₀ = CLLocation(latitude: self.myLat, longitude: self.myLong)
                    let coordinate₁ = CLLocation(latitude: their_loc!.latitude, longitude: their_loc!.longitude)
                    
                    if (self.getDistance(loc1: coordinate₀, loc2: coordinate₁) < self.MAX_DISTANCE_TRHESHOLD) {
                        //I only want to show directions for people close to me
                        self.getRoadPathToUser(user, self.myLat, self.myLong, their_loc!.latitude, their_loc!.longitude)

                    }
                }else{
                    print("removing drawn paths-------")
//                    for item in path! {
//                        item.map = nil
//                    }
//                    path!.removeAll()
//
//                    let coordinate₀ = CLLocation(latitude: self.myLat, longitude: self.myLong)
//                    let coordinate₁ = CLLocation(latitude: their_loc!.latitude, longitude: their_loc!.longitude)
//
//
//
//                    if (self.getDistance(loc1: coordinate₀, loc2: coordinate₁) < self.MAX_DISTANCE_TRHESHOLD) {
//                        //I only want to show directions for people close to me
//                        self.getRoadPathToUser(user, self.myLat, self.myLong, their_loc!.latitude, their_loc!.longitude)
//
//                    }
                    
                    self.runAnimationForDirection(path!)
                }
            }
        }
    }
    
  
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagsCollection {
            return jobTags.count
        }else if collectionView == quckJobTagsCollection{
            return tags_to_show.count
        }else if collectionView == publicUsersCollection{
            return pickedUsers.count
        }
        return new_jobs.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == tagsCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewJobTagItemCell", for: indexPath) as! NewJobTagCollectionViewCell
            
            let tag = jobTags[indexPath.row]
            cell.tagTitleLabel.text = "\(tag.title!)"
            
            return cell
        }
        
        if collectionView == quckJobTagsCollection {
            let reuseIdentifier = "QuickTagJobItem"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! QuickTagJobCollectionViewCell
            
            let tag = tags_to_show[indexPath.row]
            
            cell.tagTitleLabel.text = tag
            if selectedTags.contains(tag){
                cell.tagBackView.backgroundColor = UIColor.darkGray
            }else {
                let c = UIColor(named: "TagBackColor")
                cell.tagBackView.backgroundColor = c
            }
            
            return cell
        }
        
        if collectionView == publicUsersCollection{
            let reuseIdentifier = "QuickUserCell"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! QuickUserCollectionViewCell
            
            let uid = pickedUsers[indexPath.row]
            let user = self.getAccountIfExists(uid: uid)
            let user_ratings = self.getRatingsMatchingPickedTags(uid)
            let users_applications = self.getApplicationsMatchingPickedTags(user_id: uid)
            let shared_pub_user = self.getSharedLocationUserIfExists(user_id: uid)
            
            
            if user_ratings.isEmpty{
                cell.ratingsLabel.text = "New!."
            }else if user_ratings.count == 1 {
                cell.ratingsLabel.text = "\(user_ratings.count) Rated."
            }else{
                cell.ratingsLabel.text = "\(user_ratings.count) Rated."
            }
            
            if users_applications.isEmpty{
                cell.applicationsLabel.text = "New!."
            }else if users_applications.count == 1 {
                cell.applicationsLabel.text = "\(users_applications.count) Applied."
            }else{
                cell.applicationsLabel.text = "\(users_applications.count) Applied."
            }
            
//            var date = Date(timeIntervalSince1970: TimeInterval(shared_pub_user!.last_online) / 1000)
//            var timeOffset = date.offset(from: Date())
//            if timeOffset == "" {
//                timeOffset = Date().offset(from: date)
//                cell.lastOnlineLabel.text = "Active: \(timeOffset) ago."
//            }else{
//                cell.lastOnlineLabel.text = "Active: \(timeOffset) ago."
//            }
            
            print("user \(uid) : ratings: \(user_ratings.count) , applications: \(users_applications.count)")
            
            if selectedUsers.contains(uid){
                cell.containerCardView.backgroundColor = UIColor.darkGray
                
//                cell.mapIconView.image = UIImage(named: "PickedUserIcon")
            }else{
//                cell.mapIconView.image = UIImage(named: "PickUserIcon")
                
                let c = UIColor(named: "JobCardColor")
                cell.containerCardView.backgroundColor = c
            }
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewJobIconItemCell", for: indexPath) as! NewJobItemCollectionViewCell
        
        return cell

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         // handle tap events
        if collectionView == jobsCollectionView{
            print("You selected cell \(indexPath.item)!")
            let job_id = new_jobs[indexPath.row]
            self.showJobOnMap(job_id: job_id)
        }
        
        if collectionView == quckJobTagsCollection {
            var selected_t = tags_to_show[indexPath.row]
            if !selectedTags.contains(selected_t){
                selectedTags.append(selected_t)
            }else{
                selectedTags.remove(at: indexPath.row)
            }
            searchTagField.text = ""
            typedItem = ""
            
            tags_to_show = getTheTagsToShow()
            quckJobTagsCollection.reloadData()
            
            pickedUsers = getAppropriateUsers()
            publicUsersCollection.reloadData()
            drawLineToPickedUsers()
            showAllPickedUsers()
            
            if pickedUsers.isEmpty{
                publicUsersCollection.isHidden = true
            }else{
                publicUsersCollection.isHidden = false
            }
            
            if selectedTags.isEmpty {
                createJobFromTagsButton.isEnabled = false
                createJobFromTagsButtonContainer.isHidden = true
                if selectedUsers.isEmpty{
                    sendQuickJobContainer.isHidden = true
                    sendCustomJobContainer.isHidden = true
                }else{
                    if selectedTags.isEmpty {
                        sendQuickJobContainer.isHidden = true
                    }else{
                        sendQuickJobContainer.isHidden = false
                    }
                    sendCustomJobContainer.isHidden = false
                }
                jobTagPrices.text = "Pick a tag..."
            }else{
                createJobFromTagsButton.isEnabled = true
                createJobFromTagsButtonContainer.isHidden = false
                if selectedUsers.isEmpty{
                    sendQuickJobContainer.isHidden = true
                    sendCustomJobContainer.isHidden = true
                }else{
                    if selectedTags.isEmpty {
                        sendQuickJobContainer.isHidden = true
                    }else{
                        sendQuickJobContainer.isHidden = false
                    }
                    sendCustomJobContainer.isHidden = false
                }
                calculatePriceFromTag()
            }
            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//
//            }
        }
        
        if collectionView == publicUsersCollection{
            var picked_user = pickedUsers[indexPath.row]
            var their_loc = getPubUsersLocation(picked_user)
            
            
            let marker = addedMarkers[picked_user]!
            if(selectedUsers.contains(picked_user)){
                let pos = selectedUsers.firstIndex(of: picked_user)!
                selectedUsers.remove(at: pos)
                marker.icon = UIImage(named: "PickUserIcon")
                
                if addedCircles[picked_user] != nil {
                    addedCircles[picked_user]!.map = nil
                    addedCircles.removeValue(forKey: picked_user)
                }
            }else{
                selectedUsers.append(picked_user)
                marker.icon = UIImage(named: "PickedUserIcon")
                
                let circleCenter = CLLocationCoordinate2D(latitude: marker.position.latitude, longitude: marker.position.longitude)
                let circle = GMSCircle(position: circleCenter, radius: 200)
                
                circle.fillColor = UIColor(red: 113, green: 204, blue: 231, alpha: 0.1)
                circle.strokeColor = .none
                
                circle.map = mapView
                addedCircles[picked_user] = circle
                
                if their_loc != nil {
                    mapView.animate(to: GMSCameraPosition(latitude: their_loc!.latitude, longitude: their_loc!.longitude, zoom: mapView.camera.zoom))
                }
            }
            
            pickedUsers = getAppropriateUsers()
            publicUsersCollection.reloadData()
            drawLineToPickedUsers()
            showAllPickedUsers()
            
            if pickedUsers.isEmpty{
                publicUsersCollection.isHidden = true
        
            }else{
                publicUsersCollection.isHidden = false

            }
            
            if selectedUsers.isEmpty{
                sendQuickJobContainer.isHidden = true
                sendCustomJobContainer.isHidden = true
            }else{
                if selectedTags.isEmpty {
                    sendQuickJobContainer.isHidden = true
                }else{
                    sendQuickJobContainer.isHidden = false
                }
                sendCustomJobContainer.isHidden = false
            }
           
        }
     }
    
    
    @IBAction func whenSendQuickJobTapped(_ sender: Any) {
        var job_item = quickJobItem()
        job_item.jobTitle = "\(selectedTags[0]) work."
        job_item.tags_to_use.append(contentsOf: selectedTags)
        
        let similar_job = self.checkForSimilarRecentJob(job_item: job_item)
        if similar_job == nil {
            self.uploadJobFromSuggestion(job_item: job_item)
        }else{
            self.pickedQuickJob = similar_job!
            self.quickJobButton.sendActions(for: .touchUpInside)
        }
        
        for picked_user in selectedUsers{
            let marker = addedMarkers[picked_user]!
            let pos = selectedUsers.firstIndex(of: picked_user)!
            selectedUsers.remove(at: pos)
            marker.icon = UIImage(named: "PickUserIcon")
            
            if addedCircles[picked_user] != nil {
                addedCircles[picked_user]!.map = nil
                addedCircles.removeValue(forKey: picked_user)
            }
        }
        selectedUsers.removeAll()
        if selectedUsers.isEmpty{
            sendQuickJobContainer.isHidden = true
            sendCustomJobContainer.isHidden = true
        }else{
            if selectedTags.isEmpty {
                sendQuickJobContainer.isHidden = true
            }else{
                sendQuickJobContainer.isHidden = false
            }
            sendCustomJobContainer.isHidden = false
        }
        
        pickedUsers = getAppropriateUsers()
        publicUsersCollection.reloadData()
        drawLineToPickedUsers()
        showAllPickedUsers()
    }
    
    
    @IBAction func whenNewJobFromTagTapped(_ sender: Any) {
        var job_item = quickJobItem()
        job_item.jobTitle = "\(selectedTags[0]) work."
        job_item.tags_to_use.append(contentsOf: selectedTags)
        
        let similar_job = self.checkForSimilarRecentJob(job_item: job_item)
        if similar_job == nil {
            self.uploadJobFromSuggestion(job_item: job_item)
        }else{
            self.pickedQuickJob = similar_job!
            self.quickJobButton.sendActions(for: .touchUpInside)
        }
    }
    
    
    @IBAction func whenSearchTyped(_ sender: UITextField) {
        if !sender.hasText{
            createJobFromTagsButton.isEnabled = false
            createJobFromTagsButtonContainer.isHidden = true
        }else{
            typedItem = sender.text!

            tags_to_show = getTheTagsToShow()
            quckJobTagsCollection.reloadData()

            if selectedTags.isEmpty {
                createJobFromTagsButton.isEnabled = false
                createJobFromTagsButtonContainer.isHidden = true
                jobTagPrices.text = "Pick a tag..."
            }else{
                createJobFromTagsButton.isEnabled = true
                createJobFromTagsButtonContainer.isHidden = false
                calculatePriceFromTag()
            }
        }
    }
    
    
    var at_most_2 = "At most 2 hours."
    var two_to_four = "Around 2 to 4 hours."
    var whole_day = "The whole day."
    
    func calculatePriceFromTag(){
        let prices = getTagPricesForTags(selected_tags: selectedTags)
        
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        let curr = me?.phone?.country_currency as! String
        
        if !prices.isEmpty {
            print("prices being used for calculation:--------------> \(prices.count)")
           
            var top = Int(getTopAverage(prices))
            var bottom = Int(getBottomAverage(prices))
            
            if prices.count == 1 {
                top = Int(prices[0])
                bottom = Int(prices[0])
            }
            
            if (top != 0  && top != bottom) {
                jobTagPrices.text = "\(bottom) - \(top) \(curr), for ~2hrs"
            }else if (top != 0  && top == bottom) {
                jobTagPrices.text = "~ \(top) \(curr)"
            }else{
                jobTagPrices.text = ""
            }
        }else{
            jobTagPrices.text = ""
        }
    }
    
    func getTagPricesForTags(selected_tags: [String]) -> [Double]{
        var tag_with_prices = [Double]()
        
        for selected_tag in selected_tags {
            var global_t = self.getGlobalTagIfExists(tag_title: selected_tag)
            if global_t != nil {
                var associated_tag_prices = getAssociatedTagPrices(global_t!, selected_tags)
                print("tag prices for: \(global_t!.title!) -------------------------> \(associated_tag_prices.count)")
                if tag_with_prices.count < associated_tag_prices.count {
                    tag_with_prices.removeAll()
                    tag_with_prices.append(contentsOf: associated_tag_prices)
                }
            }
        }
        
        return tag_with_prices
    }
    
    func getAssociatedTagPrices(_ global_tag: GlobalTag,_ selected_tags: [String]) -> [Double] {
        var prices: [Double] = []
        var price_ids: [String] = []
        
        var associates = self.getGlobalTagAssociatesIfExists(tag_title: global_tag.title!)
//        print("tag associates for tag: \(global_tag.title!) -------------------------> \(associates.count)")
        if !associates.isEmpty{
            for associateTag in associates{
                var price = Double(associateTag.pay_amount)
                
                
                var json = associateTag.tag_associates
                let decoder = JSONDecoder()
                let jsonData = json!.data(using: .utf8)!
                
                do{
                    let tags: [json_tag] =  try decoder.decode(json_tag_array.self, from: jsonData).tags
                    var shared_tags: [String] = []
                    for item in tags{
                        if selected_tags.contains(item.tag_title) {
                            if(!shared_tags.contains(item.tag_title)){
                                shared_tags.append(item.tag_title)
                            }
                        }
                    }
                    
                    print("shared tags for fumigate: \(associateTag.job_id!): \(shared_tags)")
                    
                    if (shared_tags.count == 1 && selected_tags.count == 1) || (shared_tags.count >= 2) {
                        //associated tag obj works
                        var price = Double(associateTag.pay_amount)
//                        print("set \(price) for tag \(associateTag.title!)")

                        if associateTag.no_of_days > 0 {
                            price = price / Double(associateTag.no_of_days)
                        }
                        if associateTag.work_duration != nil {
                            switch associateTag.work_duration {
                                case two_to_four:
                                    price = price / 2
                                case two_to_four:
                                    price = price / 4
                                default:
                                    price = price / 1
                            }
                        }
                        
                        if(!price_ids.contains(associateTag.job_id!)){
                            prices.append(price)
                            price_ids.append(associateTag.job_id!)
                        }
                    }
                    
                }catch {
                    
                }
            }
        }
        
        
        return prices
    }
    
    func getTopAverage(_ prices: [Double]) -> Double {
        let sortedPrices = prices.sorted(by: >)
        
        var number_of_items = Int(Double(prices.count) * 0.6)
        
        var total = 0.0
        for price in sortedPrices.prefix(number_of_items) {
            total += price
        }
        
        if total.isZero {
            return 0.0
        }
        
        return total / Double(number_of_items)
    }
    
    
    func getBottomAverage(_ prices: [Double]) -> Double {
        let sortedPrices = prices.sorted(by: <)
        
        var number_of_items = Int(Double(prices.count) * 0.6)
        
        var total = 0.0
        for price in sortedPrices.prefix(number_of_items) {
            total += price
        }
        
        if total.isZero {
            return 0.0
        }
        
        return total / Double(number_of_items)
    }
    
    
    func getGlobalTagsIfExists() -> [GlobalTag]{
        do{
            let request = GlobalTag.fetchRequest() as NSFetchRequest<GlobalTag>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
        }catch {
            
        }
        
        return []
    }
    
    
    
    func getGlobalTagAssociatesIfExists(tag_title: String) -> [JobTag]{
        do{
            let request = JobTag.fetchRequest() as NSFetchRequest<JobTag>
            let predic = NSPredicate(format: "title == %@ && global == \(NSNumber(value: true))", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    
//    struct json_tag_array: Codable{
//        var tags: [json_tag] = []
//    }
    
    struct json_tag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    func setUpAppliedJobs(){
        my_applied_jobs.removeAll()
        print("applied jobs loading")
        let my_applied_job_objs = self.getAppliedJobsIfExists()
        for item in my_applied_job_objs{
            my_applied_jobs.append(self.getJobIfExists(job_id: item.job_id!)!)
        }
        
        print("applied jobs \(my_applied_jobs.count)")
        
        appliedJobsTableView.delegate = self
        appliedJobsTableView.dataSource = self
        appliedJobsTableView.reloadData()
    }
    
    func setUpQuickJobs(){
        quickJobsTableView.delegate = self
        quickJobsTableView.dataSource = self
    }
    
    var selectedTags: [String] = []
    var tags_to_show: [String] = []
    var typedItem = ""
    
    func setUpQuickTags(){
        tags_to_show = getTheTagsToShow()
        
        self.quckJobTagsCollection.delegate = self
        self.quckJobTagsCollection.dataSource = self
        self.quckJobTagsCollection.reloadData()
        
        if !selectedTags.isEmpty{
            calculatePriceFromTag()
        }else{
            jobTagPrices.text = "Pick a tag..."
        }
        
        self.searchTagField.delegate = self
    }
    
    func getTheTagsToShow() -> [String] {
        var other_suggestions: [String] = []
        
        other_suggestions.append(contentsOf: selectedTags)
        
        if typedItem != "" {
            let all_g_tags = getGlobalTagsIfExists()
            for tag in all_g_tags {
                if tag.title!.starts(with: typedItem.lowercased()){
                    other_suggestions.append(tag.title!)
                }
            }
        }
        else
        if !selectedTags.isEmpty{
            for tag in selectedTags {
                let tag_associates = self.getQuickJobTagGlobalTagIfExists(tag_title: tag)
//                print("associates for \(tag) are \(tag_associates[0].tag_associates)")
                if !tag_associates.isEmpty {
                    for associateTag in tag_associates{
//                        print("attemting to decode \(associateTag.title) : \(associateTag.tag_associates)")
                        var json = associateTag.tag_associates
                        let decoder = JSONDecoder()
                        let jsonData = json!.data(using: .utf8)!
                        
                        do{
                            let tags: [json_tag] =  try decoder.decode(json_tag_array.self, from: jsonData).tags
                            for item in tags{
//                                print("decoded item: \(item.tag_title)")
                                if !other_suggestions.contains(item.tag_title){
                                    other_suggestions.append(item.tag_title)
                                }
                            }
                        }catch {
                            
                        }
                    }
                }
            }
        } else {
            let all_g_tags = getGlobalTagsIfExists()
            for tag in all_g_tags {
                if !other_suggestions.contains(tag.title!){
                    other_suggestions.append(tag.title!)
                }
            }
        }
                
        return other_suggestions
    }
    
    func getQuickJobTagGlobalTagIfExists(tag_title: String) -> [JobTag]{
        do{
            let request = JobTag.fetchRequest() as NSFetchRequest<JobTag>
            let predic = NSPredicate(format: "title == %@ && global == \(NSNumber(value: true))", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    
    struct json_tag_array: Codable{
        var tags: [json_tag] = []
    }
    
    
    func updateAppliedJobs(){
        my_applied_jobs.removeAll()
        let my_applied_job_objs = self.getAppliedJobsIfExists()
        for item in my_applied_job_objs{
            my_applied_jobs.append(self.getJobIfExists(job_id: item.job_id!)!)
        }
        
        appliedJobsTableView.reloadData()
    }
    
    struct quickJobGroup: Codable{
        var title = ""
        var items = [quickJobItem]()
        
    }
    
    struct quickJobItem: Codable {
        var jobTitle = ""
        var tags_to_use  = [String]()
    }
    
    func getJobSuggestions() -> [quickJobGroup]{
        var group1 = quickJobGroup()
        group1.title = "Cleaning Services"
        
        var g1item1 = quickJobItem()
        g1item1.jobTitle = "House Cleaning"
        g1item1.tags_to_use = ["cleaning","house","washing"]
        var g1item2 = quickJobItem()
        g1item2.jobTitle = "Laundry Work"
        g1item2.tags_to_use = ["cleaning","laundry","washing","clothes"]
        var g1item3 = quickJobItem()
        g1item3.jobTitle = "Car Cleaning"
        g1item3.tags_to_use = ["cleaning","car","carwash"]
        var g1item4 = quickJobItem()
        g1item4.jobTitle = "Compound Cleaning"
        g1item4.tags_to_use = ["cleaning","compound"]
        var g1item5 = quickJobItem()
        g1item5.jobTitle = "Decluttering Work"
        g1item5.tags_to_use = ["cleaning","decluttering"]
        group1.items = [g1item1,g1item2,g1item3,g1item4,g1item5]
        
        
        var group2 = quickJobGroup()
        group2.title = "I.T Services"
        
        var g2item1 = quickJobItem()
        g2item1.jobTitle = "Logo Designing"
        g2item1.tags_to_use = ["illustration","design","graphics","logo"]
        var g2item2 = quickJobItem()
        g2item2.jobTitle = "Program Debugging"
        g2item2.tags_to_use = ["software","debugging","engineer"]
        var g2item3 = quickJobItem()
        g2item3.jobTitle = "App Developer"
        g2item3.tags_to_use = ["developer","android","ios","mobile","app"]
        group2.items = [g2item1,g2item2,g2item3]

        
        var group3 = quickJobGroup()
        group3.title = "Delivery Services"
        
        var g3item1 = quickJobItem()
        g3item1.jobTitle = "Kiosk Dropships"
        g3item1.tags_to_use = ["pickup","shop","delivery","ship"]
        var g3item2 = quickJobItem()
        g3item2.jobTitle = "Quick Delivery"
        g3item2.tags_to_use = ["ship","item","delivery","take"]
        group3.items = [g3item1,g3item2]
        
        
        return [group1,group2,group3]
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == quickJobsTableView{
            return self.getJobSuggestions().count
        }else {
            if my_applied_jobs.count > 1 {
                return 1
            }
            return my_applied_jobs.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == quickJobsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "quickJobsCell", for: indexPath) as! QuickJobTableViewCell
            
            let group = self.getJobSuggestions()[indexPath.row]
            
            cell.pos = indexPath.row
            cell.groupTitleLabel.text = group.title
            cell.job_group = group
            
            cell.whenQuickJobTapped = { value in
                print("loading job from clicked item \(group.items[value].jobTitle)")
                let job_item = group.items[value]
                let similar_job = self.checkForSimilarRecentJob(job_item: job_item)
                if similar_job == nil {
                    self.uploadJobFromSuggestion(job_item: job_item)
                }else{
                    self.pickedQuickJob = similar_job!
                    self.quickJobButton.sendActions(for: .touchUpInside)
                }
            }
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "appliedJobsCell", for: indexPath) as! AppliedJobTableViewCell
    //        print("loaded job item: \(indexPath.row)")
            let job = my_applied_jobs[indexPath.row]
            
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
            
    //        var job_views = self.getJobViewsIfExists(job_id: job.job_id!)
    //        var applicants = self.getJobApplicantsIfExists(job_id: job.job_id!)
            
    //        if job.job_title == "Food" {
    //            print("\(job_views.count) job views for: \(job.job_title!)")
    //        }
            
    //        var t = ""
    //        var a = ""
    //
    //        if !job_views.isEmpty{
    //            t = "\(job_views.count) views"
    //            if job_views.count == 1 {
    //                t = "1 view"
    //            }
    //        }
    //
    //        if !applicants.isEmpty{
    //            a = "\(applicants.count) applicants"
    //            if applicants.count == 1 {
    //                a = "1 applicant"
    //            }
    //        }
            
    //        let views_applicants = "\(t) \(a)"
            
            cell.jobTimeLabel.text = "@\(job.time_hour):\(job.time_minute)\(self.gett("a", date).lowercased())"
            
            
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
            
    //        if (job_views.isEmpty && applicants.isEmpty){
    //            cell.timeDurationView.isHidden = true
    //        }else{
    //            cell.timeDurationView.isHidden = false
    //        }
            
            cell.takenDownImage.isHidden = !job.taken_down
            
            
            return cell
        }
    }
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
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
    
    func checkForSimilarRecentJob(job_item: quickJobItem) -> String? {
        let my_uploadeds = self.getUploadedJobsIfExists()
        for item in my_uploadeds {
            let its_job = self.getJobIfExists(job_id: item.job_id!)
            if its_job != nil {
//                print("checking uploaded job --------------- \(its_job?.job_title)")

                let today = Date()
                let end_date_for_visibility = DateComponents(calendar: .current, year: Int(its_job!.end_year), month: Int(its_job!.end_month)+1, day: Int(its_job!.end_day)).date!
                
                if today <= end_date_for_visibility {
                    //job is yet to expire
                    var its_tags = [String]()
                    for tag in its_job!.tags! {
                        its_tags.append((tag as! JobTag).title!)
                    }
                    
                    var list:Array<String> = its_tags
                    var findList:Array<String> = job_item.tags_to_use

                    let listSet = Set(list)
                    let findListSet = Set(findList)

                    let allElemtsEqual = findListSet.isSubset(of: listSet)
                    
                    if allElemtsEqual {
                        print("found a similar job!")
                        if !its_job!.is_job_private{
                            
                            return its_job!.job_id!
                        }else{
                            //check if invited users match
                            print("similar job is private! - checking if invited users match")
                            var selected_users_json = its_job!.selected_users_for_job
                            let decoder = JSONDecoder()
                            
                            do{
                                var selected_users = selected_users_class()
                                
                                if selected_users_json != nil && selected_users_json != "" {
                                    let jsonData = selected_users_json!.data(using: .utf8)!
                                    selected_users = try decoder.decode(selected_users_class.self ,from: jsonData)
                                }
                                
                                if !selected_users.selected_users_for_job.isEmpty {
                                    var list:Array<String> = selectedUsers
                                    var findList:Array<String> = selected_users.selected_users_for_job

                                    let listSet = Set(list)
                                    let findListSet = Set(findList)

                                    let allElemtsEqual = findListSet.isSubset(of: listSet)
                                    
                                    if allElemtsEqual {
                                        print("found similar private job -------- \(its_job!.job_id!)")
                                        return its_job!.job_id!
                                    }
                                }
                            }catch{
                                print("\(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            
        }
        
        return nil
    }
    
    func uploadJobFromSuggestion(job_item: quickJobItem){
        //we post a job quick
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        var titleText = job_item.jobTitle
        var details = ""
        var pickedImages: [UIImage] = []
        var number = constants.maxNumber
        var selectedTags: [String] = job_item.tags_to_use
        var date = Date()
        var time_duration = constants.durationless
        var days_duration = 0
        var location_desc = ""
        var lat = 0.0
        var lng = 0.0
        var amount = 0
        var is_job_private = !selectedUsers.isEmpty
        var pickedUsers: [String] = []
        
        pickedUsers.append(contentsOf: selectedUsers)
        
        let newJobRef = db.collection(constants.jobs)
            .document(me!.phone!.country_name!)
            .collection("country_jobs")
            .document()
        
        let key  = newJobRef.documentID as String
        
        var job_tags = [[String: Any]]()
        
        for tag_title in selectedTags {
            var tag: [String: Any] = [
                "tag_title" : tag_title,
                "tag_class" : "custom"
            ]
            
            job_tags.append(tag)
        }
       
        let upload_time = Int64((date.timeIntervalSince1970 * 1000.0).rounded())
        let year: Int = Int(gett("yyyy", date))!
        let month: Int = Int(gett("MM", date))!-1
        let day: Int = Int(gett("dd", date))!
        let hour: Int = Int(gett("hh", date))!
        let min: Int = Int(gett("mm", date))!
        var am_pm: String = gett("a", date)
        var day_of_week: String = gett("EEEE", date)
        var month_of_year: String = gett("MMM", date)
        
        var dateComponent = DateComponents()
        dateComponent.day = 1
        
        var end_day = Calendar.current.date(byAdding: dateComponent, to: date)!
        let expiry_date = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end_day)!
        var expiry_date_mills = Int64((expiry_date.timeIntervalSince1970 * 1000.0).rounded())
        
        let pay: [String : Any] = [
            "amount" : amount,
            "currency" : me!.phone!.country_currency!,
            "applicant_set" : false
        ]
        
        let uploader: [String: Any] = [
            "id" : me!.uid!,
            "email" : me!.email!,
            "name" : me!.name!,
            "phone-number" : me!.phone!.digit_number,
            "country_number_code" : me!.phone!.country_number_code!
        ]
        
        let time: [String: Any] = [
            "hour" : hour,
            "minute" : min,
            "am_pm" : am_pm
        ]
        
        let location: [String: Any] = [
            "latitude" : lat,
            "longitude" : lng,
            "description" : location_desc
        ]
        
        let selected_date: [String: Any] = [
            "day" : day,
            "month" : month,
            "year" : year,
            "day_of_week" : day_of_week,
            "month_of_year" : month_of_year
            
        ]
        
        let start_date: [String: Any] = [
            "day" : day,
            "month" : month,
            "year" : year,
            "day_of_week" : day_of_week,
            "month_of_year" : month_of_year
        ]
        
        let end_date: [String: Any] = [
            "day" : Int(gett("dd", end_day))!,
            "month" : Int(gett("MM", end_day))!-1,
            "year" : Int(gett("yyyy", end_day))!,
            "day_of_week" : gett("EEEE", end_day),
            "month_of_year" : gett("MMM", end_day)
        ]
        
        var job_list = job_image_list()
        for image in pickedImages {
            var job_im = job_image()
            job_im.name = constants.randomString(16)
            
            let storageRef = Storage.storage().reference()
            let ref = storageRef.child(constants.users_data)
                .child(uid)
                .child(constants.job_images)
                .child("\(job_im.name).jpg")
            
            let uploadTask = ref.putData(image.resized(toWidth: 600.0)!.pngData()!, metadata: nil) { (metadata, error) in
              guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
              }
              // Metadata contains file metadata such as size, content-type.
              let size = metadata.size
            }
            
            job_list.set_images.append(job_im)
        }
        
        var selected_users = selected_users_class()
        for user_id in pickedUsers {
            selected_users.selected_users_for_job.append(user_id)
        }
        
        var job_image_list_json = ""
        var selected_users_json = ""
        let encoder = JSONEncoder()
        
        do {
            let json_string = try encoder.encode(job_list)
            let selected_users_string = try encoder.encode(selected_users)
            job_image_list_json = String(data: json_string, encoding: .utf8)!
            selected_users_json = String(data: selected_users_string, encoding: .utf8)!
        }catch {
           
        }
        
        var isJobOk = true
        
        let docData: [String: Any] = [
            "expiry_date" : expiry_date_mills,
            "job_title" : titleText,
            "job_details" : details,
            "job_worker_count" : number,
            "selected_tags" : job_tags,
            "is_asap" : false,
            "work_duration" : time_duration,
            "country_name" : me!.phone!.country_name!,
            "country_name_code" : me!.phone!.country_name_code,
            "upload_time" : upload_time,
            "job_id" : key,
            "pay" : pay,
            "uploader" : uploader,
            "language": me!.language,
            "time" : time,
            "location" : location,
            "selected_date" : selected_date,
            "start_date" : start_date,
            "end_date" : end_date,
            "images" : job_image_list_json,
            "is_job_private" : is_job_private,
            "selected_users_for_job" : selected_users_json,
            "taken_down": false,
            "auto_taken_down" : false
        ]
        
        let refData: [String: Any] = [
            "job_id" : key,
            "country_name" : me!.phone!.country_name!,
            "location" : location,
            "pay" : pay,
            "upload_time" : upload_time,
            "selected_date" : selected_date
        ]
        
        var job = Job(context: self.context)
       
        job.job_title = titleText
        job.job_details = details
        job.is_asap = false
        job.work_duration = time_duration
        job.job_worker_count = Int64(number)
        job.country_name = me!.phone!.country_name!
        job.country_name_code = me!.phone!.country_name_code!
        job.language = me!.language
        job.upload_time = Int64(upload_time)
        job.job_id = key
        
        job.selected_workers = selected_users_json
        job.pay_amount = Int64(amount)
        job.pay_currency = me!.phone!.country_currency!
        job.applicant_set_pay = false
        job.uploader_id = me!.uid!
        job.uploader_name = me!.name!
        job.uploader_email = me!.email!
        job.uploader_phone_number = Int64(me!.phone!.digit_number)
        job.uploader_phone_number_code = me!.phone!.country_number_code!
        job.time_hour = Int64(hour)
        job.time_minute = Int64(min)
        job.am_pm = am_pm
        job.location_lat = lat
        job.location_long = lng
        job.location_desc = location_desc
        
        job.selected_day = Int64(day)
        job.selected_month = Int64(month)
        job.selected_year = Int64(year)
        job.selected_day_of_week = day_of_week
        job.selected_month_of_year = month_of_year
        job.start_day = Int64(day)
        job.start_month = Int64(month)
        job.start_year = Int64(year)
        job.start_day_of_week = day_of_week
        job.start_month_of_year = month_of_year
        job.end_day = Int64(Int(gett("dd", end_day))!)
        job.end_month = Int64(Int(gett("MM", end_day))!-1)
        
        job.end_year = Int64(Int(gett("yyyy", end_day))!)
        job.end_day_of_week = gett("EEEE", end_day)
        job.end_month_of_year = gett("MMM", end_day)
        
        for title in selectedTags {
            var tag = self.getTagIfExists(job_id: key, tag_title: title)
            if tag == nil {
                tag = JobTag(context: self.context)
            }
            tag?.title = title
            tag?.job = job
        }
        
        job.taken_down = false
        job.images = job_image_list_json
        job.is_job_private = false
        job.selected_users_for_job = selected_users_json
        job.auto_taken_down = false
        
        self.saveContext(constants.refresh_job)
        pickedQuickJob = key
        
        
        print("starting upload ...")
        db.collection(constants.users_ref)
            .document(uid)
            .collection(constants.job_history)
            .document(key)
            .setData(refData)
        
        newJobRef.setData(docData){ err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
        
        
        for user_id in pickedUsers {
            let ref = db.collection(constants.airworkers_ref)
                .document(user_id)
                .collection(constants.notifications)
                .document()
            ref.setData([
                "message" : "\(me!.name!) has invited you to do a job.",
                "time" : upload_time,
                "user_name" : me!.name!,
                "user_id" : user_id,
                "job_id" : key,
                "pending" : isJobOk,
                "notif_id" : ref.documentID
            ])
        }
        
        
        
        self.quickJobButton.sendActions(for: .touchUpInside)
    }
    
    struct job_tag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
        var job_id = ""
    }
    
    struct job_image_list: Codable {
        var set_images = [job_image]()
    }
    
    struct job_image: Codable{
        var name = ""
        var is_new_item = false
    }

    
    
    
    
    
    // MARK: - Swap user for airworker
    @IBAction func whenSwapUserTapped(_ sender: Any) {
        swapUserType()
    }
    
    func swapUserType(){
        let app_data = self.getAppDataIfExists()
        app_data!.is_airworker = !amIAirworker()
        
        clear_data_for_account_switch()
        saveContext(constants.swapped_account_type)
        removeFirebaseListeners()
        setUpViews()
        
        homePageScrollView.setContentOffset(.zero, animated: false)
        
    }
    
    func amIAirworker() -> Bool{
        let app_data = self.getAppDataIfExists()
        
        if app_data!.is_airworker {
            return true
        }
        
        return false
    }
    
    func clear_data_for_account_switch(){
        //clear contacts
        //clear notifications
        //clear complaints
        //clear accounts
        
        let contactRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Contact")
        let contactDeleteRequest = NSBatchDeleteRequest( fetchRequest: contactRequest)
        
        let NotificationRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notification")
        let NotificationDeleteRequest = NSBatchDeleteRequest( fetchRequest: NotificationRequest)
        
        let ComplaintRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Complaint")
        let ComplaintDeleteRequest = NSBatchDeleteRequest( fetchRequest: ComplaintRequest)
        
        let RatingRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Rating")
        let RatingDeleteRequest = NSBatchDeleteRequest( fetchRequest: RatingRequest)
        
        let AccountRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Account")
        let AccountDeleteRequest = NSBatchDeleteRequest( fetchRequest: RatingRequest)

        do{
            try context.execute(contactDeleteRequest)
            try context.execute(NotificationDeleteRequest)
            try context.execute(ComplaintDeleteRequest)
            try context.execute(RatingDeleteRequest)
            try context.execute(AccountDeleteRequest)
        }catch let error as NSError {
            print("error clearing data for account switch")
        }
    }
    
    
    
    @objc func whenNewJobViewTapped(sender:UITapGestureRecognizer) {
        getPendingJobs()
        
        if !myJobs.isEmpty{
            openPendingRatingsButton.sendActions(for: .touchUpInside)
        }else{
            openNewJobsButton.sendActions(for: .touchUpInside)
        }
        
    }
    
    @objc func whenViewPeopleViewTapped(sender:UITapGestureRecognizer) {
        pickPersonButton.sendActions(for: .touchUpInside)
        
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
    
    

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//         Get the new view controller using segue.destination.
//         Pass the selected object to the new view controller.
        //quickJobSegue
        switch(segue.identifier ?? "") {
                        
        case "quickJobSegue":
            let quickJob = segue.destination as? QuickJobViewController
            quickJob?.job_id = pickedQuickJob
            //"mYWiUZLwcTO8y8DzoyKl"
            
        
        case "viewAppliedJob":
            guard let jobDetailViewController = segue.destination as? JobDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let jobItemTableViewCell = sender as? AppliedJobTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = appliedJobsTableView.indexPath(for: jobItemTableViewCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedJob = my_applied_jobs[indexPath.row]
            print("notif item: \(selectedJob.job_title)")
            jobDetailViewController.job_id = selectedJob.job_id!
//            jobDetailViewController = selectedNotif
            
        case "openQuickJobDetail":
            guard let jobDetailViewController = segue.destination as? JobDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            jobDetailViewController.job_id = selectedQuickJob
            
        case "openQuickJobApplicantsSegue":
            guard let allApplicantsViewController = segue.destination as? AllApplicantsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            allApplicantsViewController.job_id = selectedQuickJob
            
        case "viewFirstApplicant":
            guard let applicantDetailViewController = segue.destination as? ApplicantViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            var applicants = self.getJobApplicantsIfExists(job_id: selectedQuickJob)
            
            applicantDetailViewController.applicant_id = applicants[0].applicant_uid!
            applicantDetailViewController.job_id = selectedQuickJob
            
        case "viewAppliedJobs":
            guard let jobsViewController = segue.destination as? JobsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            jobsViewController.viewAppliedJobs = true
            
        case "viewMapJobSegue":
            guard let jobDetailViewController = segue.destination as? JobDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            jobDetailViewController.job_id = map_job_id
            
        case "viewMyAccountSkills":
            guard let skillsViewController = segue.destination as? SkillsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            let me = Auth.auth().currentUser!.uid
            let myAcc = getAccountIfExists(uid: me)
            
            skillsViewController.applicant_id = me
            skillsViewController.title = myAcc!.name!
            
        case "openCustomNewJobSegue":
            let navVC = segue.destination as? UINavigationController
            let titleVC = navVC?.viewControllers.first as! NewJobTitleViewController
            
            titleVC.pickedUsers = selectedUsers
            
        default:
            print("Unexpected Segue Identifier; \(segue.identifier)")
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
    
    
    
    
    
    
    // MARK: -My Account Listeners
    func setMyAccountDataListeners(){
        let uid = Auth.auth().currentUser!.uid
        
        var accountReference = db.collection(constants.users_ref).document(uid)
        var phoneReference = db.collection(constants.users_ref).document(uid).collection(constants.meta_data)
            .document(constants.phone)
        var contactsReference = db.collection(constants.users_ref).document(uid).collection(constants.my_contacts)
        var ratingsReference = db.collection(constants.users_ref).document(uid).collection(constants.all_my_ratings)
        var notificationsReference = db.collection(constants.users_ref).document(uid).collection(constants.notifications)
        var complaintsReference = db.collection(constants.users_ref).document(uid).collection(constants.complaints)
        
        if amIAirworker(){
            accountReference = db.collection(constants.airworkers_ref).document(uid)
            phoneReference = db.collection(constants.airworkers_ref).document(uid).collection(constants.meta_data)
                .document(constants.phone)
            contactsReference = db.collection(constants.airworkers_ref).document(uid).collection(constants.my_contacts)
            ratingsReference = db.collection(constants.airworkers_ref).document(uid).collection(constants.all_my_ratings)
            notificationsReference = db.collection(constants.airworkers_ref).document(uid).collection(constants.notifications)
            complaintsReference = db.collection(constants.airworkers_ref).document(uid).collection(constants.complaints)
        }
        
        var account = self.getAccountIfExists(uid: uid)
        var app = self.getAppDataIfExists()
        let time = Int(round(NSDate().timeIntervalSince1970 * 1000))
        if app == nil {
            app = AppData(context: self.context)
            app?.global_tag_data_update_time = Int64(time)
        }
        if account != nil {
            self.listenForGlobalTagData(country: account!.country!, last_update_time: Int(app!.global_tag_data_update_time))
            
            self.verifyIdentityContainer.isHidden = true
            if Auth.auth().currentUser!.isAnonymous {
                self.addCertificateContainer.isHidden = true
                self.verifyEmailContainer.isHidden = true
                self.verifyIdentityContainer.isHidden = true
                self.createAccountContainer.isHidden = false
            }else{
                self.createAccountContainer.isHidden = true
                if amIAirworker(){
                    self.addCertificateContainer.isHidden = false
                    
                    if (account?.scan_id_data != nil && account?.scan_id_data != ""){
                        self.verifyIdentityContainer.isHidden = true
                    }else{
                        self.verifyIdentityContainer.isHidden = false
                    }
                }else{
                    self.addCertificateContainer.isHidden = true
                }
                
                if (self.isEmailVerified()){
                    self.verifyEmailContainer.isHidden = true
                }else{
                    self.verifyEmailContainer.isHidden = false
                }
                
               
                
            }
        }
        
        var accountRef = accountReference
            .addSnapshotListener{ documentSnapshot, error in
                //if fetching the doc failed
                guard let document = documentSnapshot else {
                  print("Error fetching document: \(error!)")
                  return
                }
                //if no data was in document
                guard let data = document.data() else {
                  print("Document data was empty.")
                  return
                }
                
                let email = data["email"] as! String
                let country = data["country"] as! String
                let email_vo = data["email_verification_obj"] as? String
                let gender = data["gender"] as! String
                let language = data["language"] as! String
                let name = data["name"] as! String
                let phone_verification_obj = data["phone_verification_obj"] as? String
                let sign_up_time = data["sign_up_time"] as! Int
                let user_type = data["user_type"] as! String
                
//                print(email_vo)
//                print(email)
//                print("sign up time \(sign_up_time)")
                
                var account = self.getAccountIfExists(uid: uid)
                print("locally stored email \(account?.email)")
                if account == nil {
                    account = Account(context: self.context)
                }
                account?.email = email
                account?.country = country
                account?.email_verification_obj = email_vo
                account?.gender = gender
                account?.language = language
                account?.name = name
                account?.phone_verification_obj = phone_verification_obj
                account?.sign_up_time = Int64(sign_up_time)
                account?.user_type = user_type
                account?.uid = uid
                                
                
                var app = self.getAppDataIfExists()
                let time = Int(round(NSDate().timeIntervalSince1970 * 1000))
                if app == nil {
                    app = AppData(context: self.context)
                    app?.global_tag_data_update_time = Int64(time)
                }
                self.saveContext(self.constants.refresh_app)
                
                let uid = Auth.auth().currentUser!.uid
                
                if account != nil {
                    self.listenForGlobalTagData(country: account!.country!, last_update_time: Int(app!.global_tag_data_update_time))
                }
                
                self.saveContext(self.constants.refresh_account)

                if self.amIAirworker(){
                    self.listenForNewJobs(country: country)
                }
          }
        
        setAccountListners.append(accountRef)
        
        var accountPhoneRef = phoneReference
            .addSnapshotListener{ documentSnapshot, error in
                //if fetching the doc failed
                guard let document = documentSnapshot else {
                  print("Error fetching document: \(error!)")
                  return
                }
                //if no data was in document
                guard let data = document.data() else {
                  print("Document data was empty.")
                  return
                }
                let country_currency = data["country_currency"] as! String //KES
                let country_name = data["country_name"] as! String //Kenya
                let country_name_code = data["country_name_code"] as! String //KE
                let country_number_code = data["country_number_code"] as! String //+254
                let digit_number = data["digit_number"] as! Int //799123456
                
//                print("number: \(digit_number)")
                
                var account = self.getAccountIfExists(uid: uid)
                if account == nil {
                    account = Account(context: self.context)
                    account?.uid = uid
                }
                if account?.phone == nil {
                    account?.phone = Phone(context: self.context)
                }
                account?.phone?.country_currency = country_currency
                account?.phone?.country_name = country_name
                account?.phone?.country_name_code = country_name_code
                account?.phone?.country_number_code = country_number_code
                account?.phone?.digit_number = Int64(digit_number)
                
//                self.saveContext(self.constants.refresh_account)
            }
        setAccountListners.append(accountPhoneRef)
        
        var accountContactsRef = contactsReference
            .addSnapshotListener{ querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    let rated_user_id = diff.document.data()["rated_user"] as! String
                    let last_update = diff.document.data()["last_update"] as! Int
                    
                    var contact = self.getContactIfExists(uid: rated_user_id)
                    if contact == nil {
                        contact = Contact(context: self.context)
                        contact?.rated_user = rated_user_id
                    }
                    
                    
                    
                    if (diff.type == .added) {
//                        print("New item")
                        if !self.setContactListners.keys.contains(rated_user_id) {
                            self.listenForContactInfo(user_id: rated_user_id)
                        }
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                        self.saveContext(self.constants.refresh_account)
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                        self.context.delete(contact!)
                    }
                    
//                    self.saveContext(self.constants.refresh_account)
                }

                
            }
        setAccountListners.append(accountContactsRef)
        
        
        var accountRatingsRef = ratingsReference
            .addSnapshotListener{ querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    let rating_val = diff.document.data()["rating"] as! Double //convert to float
                    let rating_time = diff.document.data()["rating_time"] as! Int
                    let job_id = diff.document.data()["job_id"] as! String
                    let user_id = diff.document.data()["user_id"] as! String //the person who sent the rating
                    let job_country = diff.document.data()["job_country"] as! String
                    let rating_explanation = diff.document.data()["rating_explanation"] as? String
                    let language = diff.document.data()["language"] as? String
                    let job_object = diff.document.data()["job_object"] as? String
                    let rating_id = diff.document.documentID
                    
                    var rating = self.getRatingIfExists(rating_id: rating_id)
                    if rating == nil {
                        rating = Rating(context: self.context)
                    }
                    
//                    print("loaded rating-----------------: \(rating_id)")
                    rating?.rating = rating_val
                    rating?.rating_time = Int64(rating_time)
                    rating?.job_id = job_id
                    rating?.user_id = user_id
                    rating?.job_country = job_country
                    rating?.rating_explanation = rating_explanation
                    rating?.language = language
                    rating?.job_object = job_object
                    rating?.rated_user_id = uid
                    rating?.rating_id = rating_id
                    
                    
                    
                    if (diff.type == .added) {
//                        print("New item")
                        if self.getRatingIfExists(rating_id: rating_id) == nil{
                            self.saveContext(self.constants.refresh_account)
                        }
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                        self.saveContext(self.constants.refresh_account)
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                    }
                }
                
//                print("loaded \(snapshot.documentChanges.count) ratings")
            
                
            }
        setAccountListners.append(accountRatingsRef)
        
        if !amIAirworker(){
            //only for ordinary job posters
            var accountUploadedJobsRef = db
                .collection(constants.users_ref)
                .document(uid)
                .collection(constants.job_history)
                .addSnapshotListener{querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error fetching snapshots: \(error!)")
                        return
                    }
                    snapshot.documentChanges.forEach { diff in
                        let job_id = diff.document.data()["job_id"] as! String
                        print("job_id: \(job_id)")
                        let country_name = diff.document.data()["country_name"] as! String
                        
                        let location = diff.document.data()["location"] as! [String: AnyObject]
                        let location_lat = location["latitude"] as! Double
                        let location_long = location["longitude"] as! Double
                        let location_desc = location["description"] as? String
                        
                        let pay = diff.document.data()["pay"] as! [String: AnyObject]
                        let pay_amount = pay["amount"] as! Int
                        let pay_currency = pay["currency"] as! String
                        
                        let upload_time = diff.document.data()["upload_time"] as! Int
                        
                        let selected_date = diff.document.data()["selected_date"] as! [String: AnyObject]
                        print("day: \(selected_date["day"])")
                        let selected_date_day = selected_date["day"] as! Int
                        let selected_date_month = selected_date["month"] as! Int
                        let selected_date_year = selected_date["year"] as! Int
                        let selected_day_of_week = selected_date["day_of_week"] as! String
                        let selected_month_of_year = selected_date["month_of_year"] as! String
                        let applicant_set_pay = pay["applicant_set"] as! Bool
                        
                        var uploaded_job = self.getUploadedJobIfExists(job_id: job_id)
                        if uploaded_job == nil {
                            uploaded_job = UploadedJob(context: self.context)
                        }
                        uploaded_job?.job_id = job_id
                        uploaded_job?.country_name = country_name
                        uploaded_job?.location_lat = location_lat
                        uploaded_job?.location_long = location_long
                        uploaded_job?.location_desc = location_desc
                        uploaded_job?.pay_amount = Int64(pay_amount)
                        uploaded_job?.pay_currency = pay_currency
                        uploaded_job?.upload_time = Int64(upload_time)
                        uploaded_job?.selected_date_day = Int64(selected_date_day)
                        uploaded_job?.selected_date_month = Int64(selected_date_month)
                        uploaded_job?.selected_date_year = Int64(selected_date_year)
                        uploaded_job?.selected_day_of_week = selected_day_of_week
                        uploaded_job?.selected_month_of_year = selected_month_of_year
                        uploaded_job?.applicant_set_pay = applicant_set_pay
                        
                        
                        
                        if (diff.type == .added) {
    //                        print("New item")
                            
                            let app_job = self.getJobIfExists(job_id: job_id)
                            if app_job != nil {
                                if self.isJobAFutureJob(job: app_job!) {
                                    if !self.setJobListeners.keys.contains(job_id) {
                                        self.listenForJobInfo(job_id: job_id, country: country_name, include_metas: true)
                                    }
                                }
                            }else{
                                if !self.setJobListeners.keys.contains(job_id) {
                                    self.listenForJobInfo(job_id: job_id, country: country_name, include_metas: true)
                                }
                            }
                        }
                        if (diff.type == .modified) {
    //                        print("Modified item")
                            self.saveContext(self.constants.refresh_account)
                        }
                        if (diff.type == .removed) {
    //                        print("Removed item")
                        }
                    }
                    
    //                print("loaded \(snapshot.documentChanges.count) jobs uploaded")
                    
                }
            setAccountListners.append(accountUploadedJobsRef)
        }
        else {
            //for airworkers
            var accountAppliedJobsRef = db
                .collection(constants.airworkers_ref)
                .document(uid)
                .collection(constants.my_applied_jobs)
                .addSnapshotListener{querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error fetching snapshots: \(error!)")
                        return
                    }
                    snapshot.documentChanges.forEach { diff in
                        let job_id = diff.document.data()["job_id"] as! String
                        let applicant_uid = diff.document.data()["applicant_uid"] as! String
                        let job_country = diff.document.data()["job_country"] as! String
                        let application_time = diff.document.data()["application_time"] as! Int
                        
                        let pay = diff.document.data()["application_pay"] as? [String: AnyObject]
                        let pay_amount = pay?["amount"] as? Int
                        let pay_currency = pay?["currency"] as? String
                        let applicant_set = pay?["applicant_set"] as? Bool
                        
                        print("loaded an applied job : \(job_id)")
                        
                        var job_application = self.getAppliedJobIfExists(job_id: job_id)
                        if job_application == nil {
                            job_application = AppliedJob(context: self.context)
                        }
                        
                        
                        job_application?.job_id = job_id
                        job_application?.applicant_uid = applicant_uid
                        job_application?.job_country = job_country
                        job_application?.application_time = Int64(application_time)
                        job_application?.application_pay_amount = Int64(pay_amount ?? 0)
                        job_application?.application_pay_currency = pay_currency
                        job_application?.applicant_set_pay = applicant_set ?? false
                        
                        
                        
                        if (diff.type == .added) {
    //                        print("New item")
                            
                            let app_job = self.getJobIfExists(job_id: job_id)
                            if app_job != nil {
                                if self.isJobAFutureJob(job: app_job!) {
                                    if !self.setJobListeners.keys.contains(job_id) {
                                        self.listenForJobInfo(job_id: job_id, country: job_country, include_metas: true)
                                    }
                                }
                            }else{
                                if !self.setJobListeners.keys.contains(job_id) {
                                    self.listenForJobInfo(job_id: job_id, country: job_country, include_metas: true)
                                }
                            }
                            
                            
                        }
                        if (diff.type == .modified) {
    //                        print("Modified item")
                            
                        }
                        if (diff.type == .removed) {
    //                        print("Removed item")
                            self.context.delete(job_application!)
                        }
                        
                        
                        
                    }
                    self.saveContext(self.constants.refresh_account)
                }
            setAccountListners.append(accountAppliedJobsRef)
            
            var accountPaymentReceipts = db
                .collection(constants.airworkers_ref)
                .document(uid)
                .collection(constants.job_payments)
                .addSnapshotListener{querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error fetching snapshots: \(error!)")
                        return
                    }
                    snapshot.documentChanges.forEach { diff in
                        let transaction_id = diff.document.data()["transaction_id"] as! String
                        let receipt_time = diff.document.data()["receipt_time"] as! Int
                        let payment_receipt = diff.document.data()["payment_receipt"] as! String
                        let payment_id = diff.document.documentID
                        
                        var job_payment = self.getJobPaymentIfExists(payment_id: payment_id)
                        
                        if job_payment == nil {
                            job_payment = JobPayment(context: self.context)
                        }
                        
                        job_payment?.transaction_id = transaction_id
                        job_payment?.receipt_time = Int64(receipt_time)
                        job_payment?.payment_receipt = payment_receipt
                        job_payment?.payment_id = payment_id
                        
                        
                        
                    }
                    self.saveContext(self.constants.refresh_account)
                }
            
            setAccountListners.append(accountPaymentReceipts)
            
        }
        
        
        var accountNotificationsRef = notificationsReference
            .addSnapshotListener{querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    let message = diff.document.data()["message"] as! String
                    let time = diff.document.data()["time"] as! Int
                    let user_name = diff.document.data()["user_name"] as! String
                    let user_id = diff.document.data()["user_id"] as! String
                    let job_id = diff.document.data()["job_id"] as! String
                    let notif_id = diff.document.data()["notif_id"] as! String
                    let seen = diff.document.data()["seen"] as? Int
                    
                    var notification = self.getNotificationIfExists(notif_id: notif_id)
                    if notification == nil {
                        notification = Notification(context: self.context)
                    }
                    notification?.message = message
                    notification?.time = Int64(time)
                    notification?.user_name = user_name
                    notification?.user_id = user_id
                    notification?.job_id = job_id
                    notification?.notif_id = notif_id
                    notification?.seen = Int64(seen ?? 0)
                    
//                    self.saveContext(self.constants.refresh_account)
                    
                    if (diff.type == .added) {
//                        print("New item")
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                    }
                }
                
//                print("loaded \(snapshot.documentChanges.count) notifications")
                self.saveContext(self.constants.refresh_account)
            }
        
        setAccountListners.append(accountNotificationsRef)
        
        var accountComplaintsRef = complaintsReference
            .addSnapshotListener{querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let id = diff.document.data()["id"] as! String
                    let message = diff.document.data()["message"] as! String
                    let reporter_id = diff.document.data()["reporter_id"] as! String
                    let reported_id = diff.document.data()["reported_id"] as! String
                    let timestamp = diff.document.data()["timestamp"] as! Int
                    
                    var complaint = self.getComplaintsIfExists(id: id)
                    if complaint == nil {
                        complaint = Complaint(context: self.context)
                    }
                    
                    complaint?.id = id
                    complaint?.message = message
                    complaint?.reporter_id = reporter_id
                    complaint?.reported_id = reported_id
                    complaint?.timestamp = Int64(timestamp)
                    
                    
                    
                    if (diff.type == .added) {
//                        print("New item")
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                    }
                }
                
//                print("loaded \(snapshot.documentChanges.count) complaints")
                self.saveContext(self.constants.refresh_account)
            }
        
        setAccountListners.append(accountComplaintsRef)
        
    }
    
    func listenForNewJobs(country: String){
        if newJobDataListener != nil {
            newJobDataListener!.remove()
        }
        
        print("loading new jobs --------------------")
        let now = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        newJobDataListener = db.collection(constants.jobs_ref)
            .document(country)
            .collection(constants.country_jobs)
            
            .whereField("expiry_date", isGreaterThan: now)
            .addSnapshotListener{ querySnapshot, error in
                //if fetching the doc failed
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                print("loaded \(snapshot.documentChanges.count) new documents")
                
                snapshot.documentChanges.forEach { diff in
                    var data = diff.document.data()
                    
                    if data.isEmpty{
                        print("Error loading null document")
                    }else{
                        let job_title = data["job_title"] as! String
                        let job_details = data["job_details"] as! String
                        let is_asap = data["is_asap"] as! Bool
                        let work_duration = data["work_duration"] as! String
                        let job_worker_count = data["job_worker_count"] as! Int
                        let country_name = data["country_name"] as! String
                        let country_name_code = data["country_name_code"] as! String
                        var language = "en"
                        if data["language"] != nil {
                            language = data["language"] as! String
                        }
                        let upload_time = data["upload_time"] as! Int
                        let job_id = data["job_id"] as! String
                        
                        //do selected workers
                        let selected_workers = data["selected_workers"] as? String
                        
                        let pay = data["pay"] as! [String: AnyObject]
                        let pay_amount = pay["amount"] as! Int
                        let pay_currency = pay["currency"] as! String
                        let applicant_set_pay = pay["applicant_set"] as? Bool
                        
                        let uploader = data["uploader"] as! [String: AnyObject]
                        let uploader_id = uploader["id"] as! String
                        let uploader_name = uploader["name"] as! String
                        let uploader_email = uploader["email"] as! String
                        let uploader_phone_number = uploader["phone-number"] as! Int
                        let uploader_phone_number_code = uploader["country_number_code"] as! String
                        
                        let time = data["time"] as! [String: AnyObject]
                        let time_hour = time["hour"] as! Int
                        let time_minute = time["minute"] as! Int
                        let am_pm = time["am_pm"] as! String
                        
                        let location = data["location"] as! [String: AnyObject]
                        let location_lat = location["latitude"] as! Double
                        let location_long = location["longitude"] as! Double
                        let location_desc = location["description"] as! String
                        
                        let selected_date = data["selected_date"] as! [String: AnyObject]
                        let selected_day = selected_date["day"] as! Int
                        let selected_month = selected_date["month"] as! Int
                        let selected_year = selected_date["year"] as! Int
                        let selected_day_of_week = selected_date["day_of_week"] as! String
                        let selected_month_of_year = selected_date["month_of_year"] as! String
                        
                        let start_date = data["start_date"] as! [String: AnyObject]
                        let start_day = start_date["day"] as! Int
                        let start_month = start_date["month"] as! Int
                        let start_year = start_date["year"] as! Int
                        let start_day_of_week = start_date["day_of_week"] as! String
                        let start_month_of_year = start_date["month_of_year"] as! String
                        
                        let end_date = data["end_date"] as! [String: AnyObject]
                        let end_day = end_date["day"] as! Int
                        let end_month = end_date["month"] as! Int
                        let end_year = end_date["year"] as! Int
                        let end_day_of_week = end_date["day_of_week"] as! String
                        let end_month_of_year = end_date["month_of_year"] as! String
                        
                        //do tags
                        let job_tags = data["selected_tags"] as! [[String: AnyObject]]
                        var loaded_tag_titles = [String]()
                        for item in job_tags {
                            loaded_tag_titles.append(item["tag_title"] as! String)
                        }
                        
                        let taken_down = data["taken_down"] as? Bool
                        
                        //do images
                        let job_images = data["images"] as? String
                        
                        let is_private = data["is_job_private"] as? Bool
                        
                        //do selected users for job
                        let selected_users_for_job = data["selected_users_for_job"] as? String
                        
                        let auto_taken_down = data["auto_taken_down"] as? Bool
                        
                        
        //                print("loaded job title: \(job_title)")
                        
                        var job = self.getJobIfExists(job_id: job_id)
                        if job == nil {
                            job = Job(context: self.context)
                        }
                        job?.job_title = job_title
                        job?.job_details = job_details
                        job?.is_asap = is_asap
                        job?.work_duration = work_duration
                        job?.job_worker_count = Int64(job_worker_count)
                        job?.country_name = country_name
                        job?.country_name_code = country_name_code
                        job?.language = language
                        job?.upload_time = Int64(upload_time)
                        job?.job_id = job_id
                        
                        job?.selected_workers = selected_workers
                        job?.pay_amount = Int64(pay_amount)
                        job?.pay_currency = pay_currency
                        job?.applicant_set_pay = applicant_set_pay ?? false
                        job?.uploader_id = uploader_id
                        job?.uploader_name = uploader_name
                        job?.uploader_email = uploader_email
                        job?.uploader_phone_number = Int64(uploader_phone_number)
                        job?.uploader_phone_number_code = uploader_phone_number_code
                        job?.time_hour = Int64(time_hour)
                        job?.time_minute = Int64(time_minute)
                        job?.am_pm = am_pm
                        job?.location_lat = location_lat
                        job?.location_long = location_long
                        job?.location_desc = location_desc
                        
                        job?.selected_day = Int64(selected_day)
                        job?.selected_month = Int64(selected_month)
                        job?.selected_year = Int64(selected_year)
                        job?.selected_day_of_week = selected_day_of_week
                        job?.selected_month_of_year = selected_month_of_year
                        job?.start_day = Int64(start_day)
                        job?.start_month = Int64(start_month)
                        job?.start_year = Int64(start_year)
                        job?.start_day_of_week = start_day_of_week
                        job?.start_month_of_year = start_month_of_year
                        job?.end_day = Int64(end_day)
                        job?.end_month = Int64(end_month)
                        
                        job?.end_year = Int64(end_year)
                        job?.end_day_of_week = end_day_of_week
                        job?.end_month_of_year = end_month_of_year
                        
                        for title in loaded_tag_titles {
                            var tag = self.getTagIfExists(job_id: job_id, tag_title: title)
                            if tag == nil {
                                tag = JobTag(context: self.context)
                            }
                            tag?.title = title
                            tag?.job = job
                        }
                        
                        job?.taken_down = taken_down ?? false
                        job?.images = job_images
                        job?.is_job_private = is_private ?? false
                        job?.selected_users_for_job = selected_users_for_job
                        job?.auto_taken_down = auto_taken_down ?? false
                        
                        if job_id == "btj9unphI6l64eOSpE9e"{
                            print("loaded the job --------------- isOk? \(self.isJobOk(job: job!))")
                        }
                        
                        if self.isJobOk(job: job!){
                            print("adding \(job?.job_id!) since its ok")
                            self.saveContext(self.constants.refresh_job)
                            
                            if self.setOtherAccountListeners[uploader_id] == nil {
                                if self.getAccountIfExists(uid: uploader_id) == nil {
                                    self.listenForAnotherUserInfo(user_id: uploader_id)
                                }
                            }
                        }else{
//                            print("\(job?.job_id!) is not ok!!")
                        }
                    }
                }
                
            }
        
    }
    
    func isEmailVerified() -> Bool{
        let me = Auth.auth().currentUser!
        me.reload { (e: Error?) in
            
        }
        
        return me.isEmailVerified
        
    }
    
    func isJobAFutureJob(job: Job) -> Bool {
        let today = Date()
        
        let month: Int = Int(gett("MM", today))!
        
        let start_date = DateComponents(calendar: .current, year: Int(job.start_year), month: Int(job.start_month)+1, day: Int(job.start_day)+1).date!
        
        if job.job_id! == "btj9unphI6l64eOSpE9e" {
            print("job start day \(job.start_day)")
            print("set job start date -- \(start_date), today is \(today)")
        }
        
        //compare the two dates
        if (start_date >= today) {
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
            if job.job_id! == "btj9unphI6l64eOSpE9e" {
                print("job was taken down")
            }
            return false
        }
        
        if job.auto_taken_down {
            if job.job_id! == "btj9unphI6l64eOSpE9e" {
                print("job was auto taken down")
            }
            return false
        }
        
        if !isJobAFutureJob(job: job){
            if job.job_id! == "btj9unphI6l64eOSpE9e" {
                print("the job is not a future job!!")
            }
            return false
        }
        
        if job.is_job_private{
            if !am_i_picked_for_job(job: job){
                //if private job is not for user
                if job.job_id! == "btj9unphI6l64eOSpE9e" {
                    print("i wasnt picked for the job")
                }
                return false
            }
        }
        let uid = Auth.auth().currentUser!.uid
        if job.uploader_id == uid {
            if job.job_id! == "btj9unphI6l64eOSpE9e" {
                print("I cant be shown my own job")
            }
            return false
        }
        
        return true
    }
    
    func am_i_picked_for_job(job: Job) -> Bool{
        let uid = Auth.auth().currentUser!.uid
        var selected_users_json = job.selected_users_for_job ?? ""
        let decoder = JSONDecoder()
        let jsonData = selected_users_json.data(using: .utf8)!
        
        do{
            var selected_users = selected_users_class()
            
            if selected_users_json != "" {
                selected_users = try decoder.decode(selected_users_class.self ,from: jsonData)
                if selected_users.selected_users_for_job.contains(uid){
                    return true
                }
            }
        }catch{
            print("error loading selected users for job")
        }
        
        return false
    }
    
    struct selected_users_class: Codable{
        var selected_users_for_job = [String]()
    }
    
    
    
    // MARK: -My Contacts Listeners
    func listenForContactInfo(user_id: String){
        //listen for changes in contacts ratings and personal info
        print("listening in for contact: \(user_id)")
        let uid = Auth.auth().currentUser!.uid
        
        var accountReference = db.collection(constants.airworkers_ref).document(user_id)
        var phoneReference = db.collection(constants.airworkers_ref).document(user_id).collection(constants.meta_data)
            .document(constants.phone)
        var ratingsReference = db.collection(constants.users_ref).document(uid).collection(constants.my_contacts)
            .document(user_id).collection(constants.contact_ratings)
        
        if amIAirworker() {
            accountReference = db.collection(constants.users_ref).document(user_id)
            phoneReference = db.collection(constants.users_ref).document(user_id).collection(constants.meta_data)
                .document(constants.phone)
            ratingsReference = db.collection(constants.airworkers_ref).document(uid).collection(constants.my_contacts)
                .document(user_id).collection(constants.contact_ratings)
        }
        
        setContactListners[user_id] = []
        
        var contactAccountRef = accountReference
            .addSnapshotListener{ documentSnapshot, error in
                //if fetching the doc failed
                guard let document = documentSnapshot else {
                  print("Error fetching document: \(error!)")
                  return
                }
                //if no data was in document
                guard let data = document.data() else {
                  print("Document data was empty.")
                  return
                }
                
                let email = data["email"] as! String
                let country = data["country"] as! String
                let email_vo = data["email_verification_obj"] as? String //could be nil
                let gender = data["gender"] as! String
                let language = data["language"] as! String
                let name = data["name"] as! String
                let phone_verification_obj = data["phone_verification_obj"] as? String //could be nil
                let sign_up_time = data["sign_up_time"] as! Int
                let user_type = data["user_type"] as! String
                let scan_id_data = data["scan_id_data"] as? String //could be nil
            
//                print("loaded contact email: \(email)")
                
                var account = self.getAccountIfExists(uid: uid)
                if account == nil {
                    account = Account(context: self.context)
                }
                account?.email = email
                account?.country = country
                account?.email_verification_obj = email_vo
                account?.gender = gender
                account?.language = language
                account?.name = name
                account?.phone_verification_obj = phone_verification_obj
                account?.sign_up_time = Int64(sign_up_time)
                account?.user_type = user_type
                account?.uid = uid
                account?.scan_id_data = scan_id_data
                
                self.saveContext(self.constants.refresh_account)
          }
        
        setContactListners[user_id]?.append(contactAccountRef)
        
        var contactAccountPhoneRef = phoneReference
            .addSnapshotListener{ documentSnapshot, error in
                //if fetching the doc failed
                guard let document = documentSnapshot else {
                  print("Error fetching document: \(error!)")
                  return
                }
                //if no data was in document
                guard let data = document.data() else {
                  print("Document data was empty.")
                  return
                }
                let country_currency = data["country_currency"] as! String //KES
                let country_name = data["country_name"] as! String //Kenya
                let country_name_code = data["country_name_code"] as! String //KE
                let country_number_code = data["country_number_code"] as! String //+254
                let digit_number = data["digit_number"] as! Int //799123456
                
//                print("loaded contact phone: \(digit_number)")
                
                var account = self.getAccountIfExists(uid: uid)
                if account == nil {
                    account = Account(context: self.context)
                    account?.uid = uid
                }
                if account?.phone == nil {
                    account?.phone = Phone(context: self.context)
                }
                account?.phone?.country_currency = country_currency
                account?.phone?.country_name = country_name
                account?.phone?.country_name_code = country_name_code
                account?.phone?.country_number_code = country_number_code
                account?.phone?.digit_number = Int64(digit_number)
                
                self.saveContext(self.constants.refresh_account)
                
            }
        
        setContactListners[user_id]?.append(contactAccountPhoneRef)
        
        
        var contactRatingsRef = ratingsReference
            .addSnapshotListener{ querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    let rating_val = diff.document.data()["rating"] as! Double //convert to float
                    let rating_time = diff.document.data()["rating_time"] as! Int
                    let job_id = diff.document.data()["job_id"] as! String
                    let rated_user_id = diff.document.data()["user_id"] as! String
                    let job_country = diff.document.data()["job_country"] as! String
                    let rating_explanation = diff.document.data()["rating_explanation"] as? String
                    let language = diff.document.data()["language"] as? String
                    let job_object = diff.document.data()["job_object"] as? String
                    let rating_id = diff.document.documentID as String
                
                    print("loaded contact rating \(rating_id) for \(user_id)")
                    
                    var rating = self.getRatingIfExists(rating_id: rating_id)
                    if rating == nil {
                        rating = Rating(context: self.context)
                    }
                    rating?.rating = rating_val
                    rating?.rating_time = Int64(rating_time)
                    rating?.job_id = job_id
                    rating?.user_id = rated_user_id
                    rating?.job_country = job_country
                    rating?.rating_explanation = rating_explanation
                    rating?.language = language
                    rating?.job_object = job_object
                    rating?.rated_user_id = user_id
                    rating?.rating_id = rating_id
                    
                    
                    
                    if (diff.type == .added) {
//                        print("New item")
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                    }
                }
                self.saveContext(self.constants.refresh_account)
//                print("loaded \(snapshot.documentChanges.count) contact ratings")
                
            }
        
        setContactListners[user_id]?.append(contactRatingsRef)
        
    }

    // MARK: -My Jobs Listeners
    func listenForJobInfo(job_id: String, country: String, include_metas: Bool){
        print("listening in for job: \(job_id)")
        
        setJobListeners[job_id] = []
        
        var jobRef = db.collection(constants.jobs_ref)
            .document(country)
            .collection(constants.country_jobs)
            .document(job_id)
            .addSnapshotListener{ documentSnapshot, error in
                //if fetching the doc failed
                guard let document = documentSnapshot else {
                  print("Error fetching document: \(error!)")
                  return
                }
                //if no data was in document
                guard let data = document.data() else {
                  print("Document data was empty.")
                  return
                }
                
                let job_title = data["job_title"] as! String
                let job_details = data["job_details"] as! String
                let is_asap = data["is_asap"] as! Bool
                let work_duration = data["work_duration"] as! String
                let job_worker_count = data["job_worker_count"] as! Int
                let country_name = data["country_name"] as! String
                let country_name_code = data["country_name_code"] as! String
                var language = "en"
                if data["language"] != nil {
                    language = data["language"] as! String
                }
                let upload_time = data["upload_time"] as! Int
                let job_id = data["job_id"] as! String
                
                //do selected workers
                let selected_workers = data["selected_workers"] as? String
                
                let pay = data["pay"] as! [String: AnyObject]
                let pay_amount = pay["amount"] as! Int
                let pay_currency = pay["currency"] as! String
                let applicant_set_pay = pay["applicant_set"] as! Bool
                
                let uploader = data["uploader"] as! [String: AnyObject]
                let uploader_id = uploader["id"] as! String
                let uploader_name = uploader["name"] as! String
                let uploader_email = uploader["email"] as! String
                let uploader_phone_number = uploader["phone-number"] as! Int
                let uploader_phone_number_code = uploader["country_number_code"] as! String
                
                let time = data["time"] as! [String: AnyObject]
                let time_hour = time["hour"] as! Int
                let time_minute = time["minute"] as! Int
                let am_pm = time["am_pm"] as! String
                
                let location = data["location"] as! [String: AnyObject]
                let location_lat = location["latitude"] as! Double
                let location_long = location["longitude"] as! Double
                let location_desc = location["description"] as! String
                
                let selected_date = data["selected_date"] as! [String: AnyObject]
                let selected_day = selected_date["day"] as! Int
                let selected_month = selected_date["month"] as! Int
                let selected_year = selected_date["year"] as! Int
                let selected_day_of_week = selected_date["day_of_week"] as! String
                let selected_month_of_year = selected_date["month_of_year"] as! String
                
                let start_date = data["start_date"] as! [String: AnyObject]
                let start_day = start_date["day"] as! Int
                let start_month = start_date["month"] as! Int
                let start_year = start_date["year"] as! Int
                let start_day_of_week = start_date["day_of_week"] as! String
                let start_month_of_year = start_date["month_of_year"] as! String
                
                let end_date = data["end_date"] as! [String: AnyObject]
                let end_day = end_date["day"] as! Int
                let end_month = end_date["month"] as! Int
                let end_year = end_date["year"] as! Int
                let end_day_of_week = end_date["day_of_week"] as! String
                let end_month_of_year = end_date["month_of_year"] as! String
                
                //do tags
                let job_tags = data["selected_tags"] as! [[String: AnyObject]]
                var loaded_tag_titles = [String]()
                for item in job_tags {
                    loaded_tag_titles.append(item["tag_title"] as! String)
                }
                
                let taken_down = data["taken_down"] as? Bool
                
                //do images
                let job_images = data["images"] as? String
                
                let is_private = data["is_job_private"] as? Bool
                
                //do selected users for job
                let selected_users_for_job = data["selected_users_for_job"] as? String
                
                let auto_taken_down = data["auto_taken_down"] as? Bool
                
                
//                print("loaded job title: \(job_title)")
                
                var job = self.getJobIfExists(job_id: job_id)
                if job == nil {
                    job = Job(context: self.context)
                }
                job?.job_title = job_title
                job?.job_details = job_details
                job?.is_asap = is_asap
                job?.work_duration = work_duration
                job?.job_worker_count = Int64(job_worker_count)
                job?.country_name = country_name
                job?.country_name_code = country_name_code
                job?.language = language
                job?.upload_time = Int64(upload_time)
                job?.job_id = job_id
                
                job?.selected_workers = selected_workers
                job?.pay_amount = Int64(pay_amount)
                job?.pay_currency = pay_currency
                job?.applicant_set_pay = applicant_set_pay
                job?.uploader_id = uploader_id
                job?.uploader_name = uploader_name
                job?.uploader_email = uploader_email
                job?.uploader_phone_number = Int64(uploader_phone_number)
                job?.uploader_phone_number_code = uploader_phone_number_code
                job?.time_hour = Int64(time_hour)
                job?.time_minute = Int64(time_minute)
                job?.am_pm = am_pm
                job?.location_lat = location_lat
                job?.location_long = location_long
                job?.location_desc = location_desc
                
                job?.selected_day = Int64(selected_day)
                job?.selected_month = Int64(selected_month)
                job?.selected_year = Int64(selected_year)
                job?.selected_day_of_week = selected_day_of_week
                job?.selected_month_of_year = selected_month_of_year
                job?.start_day = Int64(start_day)
                job?.start_month = Int64(start_month)
                job?.start_year = Int64(start_year)
                job?.start_day_of_week = start_day_of_week
                job?.start_month_of_year = start_month_of_year
                job?.end_day = Int64(end_day)
                job?.end_month = Int64(end_month)
                
                job?.end_year = Int64(end_year)
                job?.end_day_of_week = end_day_of_week
                job?.end_month_of_year = end_month_of_year
                
                for title in loaded_tag_titles {
                    var tag = self.getTagIfExists(job_id: job_id, tag_title: title)
                    if tag == nil {
                        tag = JobTag(context: self.context)
                    }
                    tag?.title = title
                    tag?.job = job
                }
                
                job?.taken_down = taken_down ?? false
                job?.images = job_images
                job?.is_job_private = is_private ?? false
                job?.selected_users_for_job = selected_users_for_job
                job?.auto_taken_down = auto_taken_down ?? false
                
                self.saveContext(self.constants.refresh_job)
                
                if self.setOtherAccountListeners[uploader_id] == nil {
                    var uploader_acc = self.getAccountIfExists(uid: uploader_id)
                    if uploader_acc == nil {
                        if self.getAccountIfExists(uid: uploader_id) == nil {
                            print("listening into account: \(uploader_id)")
                            self.listenForAnotherUserInfo(user_id: uploader_id)
                        }
                    }
                }
                
            }
        
        setJobListeners[job_id]?.append(jobRef)
        
        if include_metas{
            var jobViewsRef = db.collection(constants.jobs_ref)
                .document(country)
                .collection(constants.country_jobs)
                .document(job_id)
                .collection(constants.views)
                .addSnapshotListener{ querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error fetching snapshots: \(error!)")
                        return
                    }
                    snapshot.documentChanges.forEach { diff in
                        let job_id = diff.document.data()["job_id"] as! String
                        let view_id = diff.document.data()["view_id"] as! String
                        let view_time = diff.document.data()["view_time"] as! Int
                        let viewer_id = diff.document.data()["viewer_id"] as! String
                        
    //                    print("loaded view for: \(job_id) : \(viewer_id)")
                        
                        var view = self.getJobViewIfExists(viewer_id: viewer_id, job_id: job_id)
                        if view == nil {
                            print("view from \(viewer_id) for \(job_id) is nil")
                            view = JobView(context: self.context)
                        }
                        view?.job_id = job_id
                        view?.view_id = view_id
                        view?.view_time = Int64(view_time)
                        view?.viewer_id = viewer_id
                        
                        
                        
                        if (diff.type == .added) {
    //                        print("New item")
                        }
                        if (diff.type == .modified) {
    //                        print("Modified item")
                        }
                        if (diff.type == .removed) {
    //                        print("Removed item")
                        }
                    }
                    self.saveContext(self.constants.refresh_job)
    //                print("loaded \(snapshot.documentChanges.count) views for job: \(job_id)")
                    
                }
            
            setJobListeners[job_id]?.append(jobViewsRef)
            
            var jobApplicantsRef = db.collection(constants.jobs_ref)
                .document(country)
                .collection(constants.country_jobs)
                .document(job_id)
                .collection(constants.applicants)
                .addSnapshotListener{ querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error fetching snapshots: \(error!)")
                        return
                    }
                    
                    snapshot.documentChanges.forEach { diff in
                        let applicant_uid = diff.document.data()["applicant_uid"] as! String
                        let job_id = diff.document.data()["job_id"] as! String
                        let application_time = diff.document.data()["application_time"] as! Int
                        let job_country = diff.document.data()["job_country"] as! String
                        
                        let application_pay = diff.document.data()["application_pay"] as? [String: AnyObject]
                        let application_pay_amount = application_pay?["amount"] as? Int
                        let application_pay_currency = application_pay?["currency"] as? String
                        
                        var applicant = self.getJobApplicantIfExists(applicant_uid: applicant_uid)
                        if applicant == nil {
                            applicant = JobApplicant(context: self.context)
                        }
                        applicant?.applicant_uid = applicant_uid
                        applicant?.job_id = job_id
                        applicant?.application_time = Int64(application_time)
                        applicant?.job_country = job_country
                        applicant?.application_pay_amount = Int64(application_pay_amount ?? 0)
                        applicant?.application_pay_currency = application_pay_currency
                        
                        
                        
                        if (diff.type == .added) {
    //                        print("New item")
                            
                            if self.setOtherAccountListeners[applicant_uid] == nil {
                                print("adding listener for user: \(applicant_uid) from job applicants ref")
                                if self.getAccountIfExists(uid: applicant_uid) == nil {
                                    print("listening into account: \(applicant_uid)")
                                    self.listenForAnotherUserInfo(user_id: applicant_uid)
                                }
                            }
                        }
                        if (diff.type == .modified) {
    //                        print("Modified item")
                        }
                        if (diff.type == .removed) {
    //                        print("Removed item")
                            self.context.delete(applicant!)
                        }
                        
                        
                    }
                    self.saveContext(self.constants.refresh_job)
    //                print("loaded \(snapshot.documentChanges.count) applicants for job: \(job_id)")
                    
                }
            
            setJobListeners[job_id]?.append(jobApplicantsRef)
        }
        
    }
    
    
    // MARK: -Another Account Listeners
    func listenForAnotherUserInfo(user_id: String){
        print("listening in for another user: \(user_id)")
        
        var accountReference = db.collection(constants.airworkers_ref)
            .document(user_id)
        
        var phoneReference = db.collection(constants.airworkers_ref).document(user_id)
            .collection(constants.meta_data).document(constants.phone)
        
        var ratingsReference = db.collection(constants.airworkers_ref)
            .document(user_id).collection(constants.all_my_ratings)
        
        var complaintsReference = db.collection(constants.airworkers_ref)
            .document(user_id).collection(constants.complaints)
        
        if amIAirworker(){
            accountReference = db.collection(constants.users_ref)
                .document(user_id)
            
            phoneReference = db.collection(constants.users_ref).document(user_id)
                .collection(constants.meta_data).document(constants.phone)
            
            ratingsReference = db.collection(constants.users_ref)
                .document(user_id).collection(constants.all_my_ratings)
            
            complaintsReference = db.collection(constants.users_ref)
                .document(user_id).collection(constants.complaints)
        }
        
        
        setOtherAccountListeners[user_id] = []

        var accountRef = accountReference
            .addSnapshotListener{ documentSnapshot, error in
                //if fetching the doc failed
                guard let document = documentSnapshot else {
                  print("Error fetching document: \(error!)")
                  return
                }
                //if no data was in document
                guard let data = document.data() else {
                  print("Document data was empty.")
                  return
                }
                
                let email = data["email"] as! String
                let country = data["country"] as! String
                let email_vo = data["email_verification_obj"] as? String
                let gender = data["gender"] as! String
                let language = data["language"] as! String
                let name = data["name"] as! String
                let phone_verification_obj = data["phone_verification_obj"] as? String
                let sign_up_time = data["sign_up_time"] as! Int
                let user_type = data["user_type"] as! String
                let scan_id_data = data["scan_id_data"] as? String
                
            
//                print("loaded another user email: \(email)")
                
                var account = self.getAccountIfExists(uid: user_id)
                if account == nil {
                    account = Account(context: self.context)
                }
                account?.email = email
                account?.country = country
                account?.email_verification_obj = email_vo
                account?.gender = gender
                account?.language = language
                account?.name = name
                account?.phone_verification_obj = phone_verification_obj
                account?.sign_up_time = Int64(sign_up_time)
                account?.user_type = user_type
                account?.uid = user_id
                account?.scan_id_data = scan_id_data
                
                self.saveContext(self.constants.refresh_account)
          }
        
        setOtherAccountListeners[user_id]?.append(accountRef)
        
        var accountPhoneRef = phoneReference
            .addSnapshotListener{ documentSnapshot, error in
                //if fetching the doc failed
                guard let document = documentSnapshot else {
                  print("Error fetching document: \(error!)")
                  return
                }
                //if no data was in document
                guard let data = document.data() else {
                  print("Document data was empty.")
                  return
                }
                let country_currency = data["country_currency"] as! String //KES
                let country_name = data["country_name"] as! String //Kenya
                let country_name_code = data["country_name_code"] as! String //KE
                let country_number_code = data["country_number_code"] as! String //+254
                let digit_number = data["digit_number"] as! Int //799123456
                
//                print("loaded another user phone: \(digit_number)")
                
                var account = self.getAccountIfExists(uid: user_id)
                if account == nil {
                    account = Account(context: self.context)
                    account?.uid = user_id
                }
                if account?.phone == nil {
                    account?.phone = Phone(context: self.context)
                }
                account?.phone?.country_currency = country_currency
                account?.phone?.country_name = country_name
                account?.phone?.country_name_code = country_name_code
                account?.phone?.country_number_code = country_number_code
                account?.phone?.digit_number = Int64(digit_number)
                
                self.saveContext(self.constants.refresh_account)
            }
        
        setOtherAccountListeners[user_id]?.append(accountPhoneRef)
        
        var accountRatingsRef = ratingsReference
            .addSnapshotListener{ querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                print("detected change for rating")
                snapshot.documentChanges.forEach { diff in
                    let rating_val = diff.document.data()["rating"] as! Double //convert to float
                    let rating_time = diff.document.data()["rating_time"] as! Int
                    let job_id = diff.document.data()["job_id"] as! String
                    let rated_user_id = diff.document.data()["user_id"] as! String
                    let job_country = diff.document.data()["job_country"] as! String
                    let rating_explanation = diff.document.data()["rating_explanation"] as? String
                    let language = diff.document.data()["language"] as? String
                    let job_object = diff.document.data()["job_object"] as? String
                    let rating_id = diff.document.documentID as String
                    
                    var rating = self.getRatingIfExists(rating_id: rating_id)
                    if rating == nil {
                        rating = Rating(context: self.context)
                    }
                    rating?.rating = rating_val
                    rating?.rating_time = Int64(rating_time)
                    rating?.job_id = job_id
                    rating?.user_id = rated_user_id
                    rating?.job_country = job_country
                    rating?.rating_explanation = rating_explanation
                    rating?.language = language
                    rating?.job_object = job_object
                    rating?.rated_user_id = user_id
                    rating?.rating_id = rating_id
                    
                    
                    if (diff.type == .added) {
//                        print("New item")
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                        self.context.delete(rating!)
                    }
                    
                    
                }
                self.saveContext(self.constants.refresh_account)
//                print("loaded \(snapshot.documentChanges.count) ratings for another user account")
                
            }
        
        setOtherAccountListeners[user_id]?.append(accountRatingsRef)
        
        var accountComplaintsRef = complaintsReference
            .addSnapshotListener{querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let id = diff.document.data()["id"] as! String
                    let message = diff.document.data()["message"] as! String
                    let reporter_id = diff.document.data()["reporter_id"] as! String
                    let reported_id = diff.document.data()["reported_id"] as! String
                    let timestamp = diff.document.data()["timestamp"] as! Int
                    
                    var complaint = self.getComplaintsIfExists(id: id)
                    if complaint == nil {
                        complaint = Complaint(context: self.context)
                    }
                    
                    complaint?.id = id
                    complaint?.message = message
                    complaint?.reporter_id = reporter_id
                    complaint?.reported_id = reported_id
                    complaint?.timestamp = Int64(timestamp)
                    
                    
                    
                    if (diff.type == .added) {
//                        print("New item")
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                    }
                    
                    
                }
                self.saveContext(self.constants.refresh_account)
//                print("loaded \(snapshot.documentChanges.count) complaints for another user account")
                
            }
        
        setOtherAccountListeners[user_id]?.append(accountComplaintsRef)
        
        if !amIAirworker() {
            //if i am a type user
            var accountQualificationsRef = db
                .collection(constants.airworkers_ref)
                .document(user_id)
                .collection(constants.qualifications)
                .addSnapshotListener{querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error fetching snapshots: \(error!)")
                        return
                    }
                    
                    snapshot.documentChanges.forEach { diff in
                        let title = diff.document.data()["title"] as! String
                        let details = diff.document.data()["details"] as! String
                        let last_update = diff.document.data()["last_update"] as! Int
                        let user_id = diff.document.data()["user_id"] as! String
                        let qualification_id = diff.document.data()["qualification_id"] as! String
                        let images = diff.document.data()["images"] as? String
                        
                        var qualification = self.getQualificationIfExists(qualification_id: qualification_id)
                        if qualification == nil {
                            qualification = Qualification(context: self.context)
                        }
                        qualification?.title = title
                        qualification?.details = details
                        qualification?.last_update = Int64(last_update)
                        qualification?.user_id = user_id
                        qualification?.qualification_id = qualification_id
                        qualification?.images = images
                        
                        
                        
                        
                        if (diff.type == .added) {
    //                        print("New item")
                        }
                        if (diff.type == .modified) {
    //                        print("Modified item")
                        }
                        if (diff.type == .removed) {
    //                        print("Removed item")
                        }
                    }
                    self.saveContext(self.constants.refresh_account)
    //                print("loaded \(snapshot.documentChanges.count) qualifications for another user account")
                    
                }
            
            setOtherAccountListeners[user_id]?.append(accountQualificationsRef)
            
            var appliedJobsRef = db
                .collection(constants.airworkers_ref)
                .document(user_id)
                .collection(constants.my_applied_jobs)
                .addSnapshotListener{querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        print("Error fetching snapshots: \(error!)")
                        return
                    }
                    
                    snapshot.documentChanges.forEach { diff in
                        let job_id = diff.document.data()["job_id"] as! String
                        let applicant_uid = diff.document.data()["applicant_uid"] as! String
                        let country = diff.document.data()["job_country"] as! String
                        let time = diff.document.data()["application_time"] as! Int64

                        var application = self.getJobApplicationIfExists(job_id: job_id, user_id: applicant_uid)
                        
                        if application == nil {
                            application = JobApplications(context: self.context)
                        }
                        
                        application?.country = country
                        application?.time = time
                        application?.user_id = applicant_uid
                        application?.job_id = job_id
                        
                        if !self.setJobListeners.keys.contains(job_id) {
                            if self.getJobIfExists(job_id: job_id) == nil {
                                self.listenForJobInfo(job_id: job_id, country: country, include_metas: false)
                            }
                        }
                        
                       
                        
                        
                        if (diff.type == .added) {
    //                        print("New item")
                        }
                        if (diff.type == .modified) {
    //                        print("Modified item")
                        }
                        if (diff.type == .removed) {
    //                        print("Removed item")
                        }
                    }
                    self.saveContext(self.constants.refresh_account)
    //                print("loaded \(snapshot.documentChanges.count) qualifications for another user account")
                    }
            
            setOtherAccountListeners[user_id]?.append(appliedJobsRef)
        }else{
            //if im an airworker
            
        }
        
    }
    
    
    
    // MARK: -App Public Data Listeners
    //this might be super expensive...
    func listenForGlobalTagData(country: String, last_update_time: Int){
//        var globalTagRef = db
//            .collection(constants.jobs_ref)
//            .document(country)
//            .collection(constants.tags)
//            .addSnapshotListener{querySnapshot, error in
//                guard let snapshot = querySnapshot else {
//                    print("Error fetching snapshots: \(error!)")
//                    return
//                }
//
//                snapshot.documentChanges.forEach { diff in
//                    let tag = diff.document.data()["title"] as! String
////                    print("loading tag: \(tag)")
//                    var last_update = diff.document.data()["last_update"] as? Int
//
//
////                    if last_update != nil {
////                        if last_update! >= last_update_time {
////                            self.listenForSpecificTagData(tag_title: tag, country: country)
////                        }
////                    }else{
////                        self.listenForSpecificTagData(tag_title: tag, country: country)
////                    }
//
//                    var current_time = Int64(round(NSDate().timeIntervalSince1970 * 1000))
//
//                    if last_update == nil {
//                        last_update = 0
//                    }
//
//                    var global_tag = self.getGlobalTagIfExists(tag_title: tag)
//                    var old_last_update = global_tag?.last_update
//                    if global_tag == nil {
//                        global_tag = GlobalTag(context: self.context)
//                        global_tag!.title = tag
//                        global_tag!.country = country
//                        old_last_update = Int64(last_update!)
//                        global_tag!.last_update = Int64(last_update!)
//                    }
//
//
//
//                    if (diff.type == .added) {
////                        print("New item")
//                        if self.setTagListeners[tag] == nil {
//                            //just checking if we have at least one item to use
//                            var t = self.getTagAssociateIfExists(tag_title: tag)
//                            if t == nil {
//                                self.listenForSpecificTagData(tag_title: tag, country: country)
//                            }else if global_tag!.last_update < old_last_update! {
//                                self.listenForSpecificTagData(tag_title: tag, country: country)
//                            }
//
//                        }
//                    }
//                    if (diff.type == .modified) {
////                        print("Modified item")
//                    }
//                    if (diff.type == .removed) {
////                        print("Removed item")
//                    }
//
//
//                }
//
//                self.saveContext(self.constants.refresh_app)
//            }
        
        
        var now = Int64(round(NSDate().timeIntervalSince1970 * 1000))
        var last_update_stored = self.getAppDataIfExists()!.global_tag_data_update_time
        
        
        var globalTagDataRef = db
            .collection(constants.jobs_ref)
            .document(country)
            .collection(constants.tag_data)
            .whereField("record_time", isGreaterThan: now)
            .addSnapshotListener{querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let job_id = diff.document.data()["job_id"] as! String
                    
                    let pay = diff.document.data()["pay"] as! [String: AnyObject]
                    let pay_amount = pay["amount"] as! Int
                    let pay_currency = pay["currency"] as! String
                    
                    let work_duration = diff.document.data()["work_duration"] as! String
                    let no_of_days = diff.document.data()["no_of_days"] as! Int
                    
                    let location = diff.document.data()["location"] as! [String: AnyObject]
                    let location_latitude = location["latitude"] as! Double
                    let location_longitude = location["longitude"] as! Double
                    let location_description = location["description"] as! String
                    
                    let record_time = diff.document.data()["record_time"] as! Int
                    let tag_associates = diff.document.data()["tag_associates"] as! String
                    
                    var its_tags = self.rip_tag_associates(tag_associates: tag_associates)
                    
                    for tag in its_tags{
                        var global_tag = self.getGlobalTagIfExists(tag_title: tag)
                        var old_last_update = global_tag?.last_update
                        if global_tag == nil {
                            global_tag = GlobalTag(context: self.context)
                            global_tag!.title = tag
                            global_tag!.country = country
                            old_last_update = Int64(now)
                            global_tag!.last_update = Int64(now)
                        }
                        
                        var the_tag = self.getTagAssociateIfExists(tag_title: tag, job_id: job_id)
                        
                        if(the_tag == nil){
                            print("creating new global tag: \(tag) for job: \(job_id)")
                            the_tag = JobTag(context: self.context)
                        }else{
                            print("global tag : \(tag) for job: \(job_id) already exists, so removing from associates")
                            global_tag!.removeFromTag_associates(the_tag!)
                        }
                        
                        var t = the_tag!
                        
                        t.title = tag
                        t.job_id = job_id
                        t.global = true
                        t.pay_amount = Int64(pay_amount)
                        t.pay_currency = pay_currency
                        t.work_duration = work_duration
                        t.no_of_days = Int64(no_of_days)
                        t.location_latitude = location_latitude
                        t.location_longitude = location_longitude
                        t.location_description = location_description
                        t.record_time = Int64(record_time)
                        t.tag_associates = tag_associates
                        
    //                    if !g_tag_associates.contains(t!){
                        global_tag!.addToTag_associates(t)
                        
                    }
                    
                    
                }
                self.saveContext(self.constants.refresh_app)
                
            }
        
        
        setPublicDataListeners.append(globalTagDataRef)
    }
    
    func rip_tag_associates(tag_associates: String) -> [String]{
        let decoder = JSONDecoder()
        let jsonData = tag_associates.data(using: .utf8)!
        var other_tags: [String] = [String]()
        do{
            let tags: [json_tag] =  try decoder.decode(json_tag_array.self, from: jsonData).tags
            for item in tags{
                other_tags.append(item.tag_title)
            }
        }catch {
            
        }
        
        return other_tags
    }
    
    // MARK: -Specific Tag item Listeners
    func listenForSpecificTagData(tag_title: String, country: String){
        setTagListeners[tag_title] = []
        
        print("listening for tag : \(tag_title)")
        
        var tagRef = db
            .collection(constants.jobs_ref)
            .document(country)
            .collection(constants.tags)
            .document(tag_title)
            .collection("its_jobs")
            .addSnapshotListener{querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                var global_tag = self.getGlobalTagIfExists(tag_title: tag_title)
                self.deleteTagAssociates(tag_title: tag_title)
                global_tag!.removeFromTag_associates((global_tag?.tag_associates)!)
                
                snapshot.documentChanges.forEach { diff in
                    let title = tag_title
                    let job_id = diff.document.data()["job_id"] as! String
                    
                    let pay = diff.document.data()["pay"] as! [String: AnyObject]
                    let pay_amount = pay["amount"] as! Int
                    let pay_currency = pay["currency"] as! String
                    
                    let work_duration = diff.document.data()["work_duration"] as! String
                    let no_of_days = diff.document.data()["no_of_days"] as! Int
                    
                    let location = diff.document.data()["location"] as! [String: AnyObject]
                    let location_latitude = location["latitude"] as! Double
                    let location_longitude = location["longitude"] as! Double
                    let location_description = location["description"] as! String
                    
                    let record_time = diff.document.data()["record_time"] as! Int
                    let tag_associates = diff.document.data()["tag_associates"] as! String
                    
//                    print("Tag associate for: \(title) : \(tag_associates)")
                    
                    var t = JobTag(context: self.context)
                    
                    t.title = title
                    t.job_id = job_id
                    t.global = true
                    t.pay_amount = Int64(pay_amount)
                    t.pay_currency = pay_currency
                    t.work_duration = work_duration
                    t.no_of_days = Int64(no_of_days)
                    t.location_latitude = location_latitude
                    t.location_longitude = location_longitude
                    t.location_description = location_description
                    t.record_time = Int64(record_time)
                    t.tag_associates = tag_associates
                    
//                    if !g_tag_associates.contains(t!){
                    global_tag?.addToTag_associates(t)
                    
                    
                    
                    if (diff.type == .added) {
//                        print("New item")
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                    }
                }
                self.saveContext(self.constants.refresh_app)
//                print("tag associates for \(tag_title) : \(global_tag!.tag_associates!.count)")
                
            }
        
//        setPublicDataListeners.append(tagRef)
        setTagListeners[tag_title]?.append(tagRef)
    }
    
    // MARK: -Public Location Data Listeners
    func listenForPublicLocationData(){
        var pubLocationRef = db
            .collection(constants.public_locations)
            .addSnapshotListener{querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let creation_time = diff.document.data()["creation_time"] as! Int64
                    let uid = diff.document.data()["uid"] as! String
                    let loc_pack = diff.document.data()["loc_pack"] as! String
                    let country = diff.document.data()["country"] as? String
                    
                    var public_user = self.getSharedLocationUserIfExists(user_id: uid)
                    if public_user == nil {
                        public_user = SharedLocationUser(context: self.context)
                    }
                    
                    public_user?.last_online = creation_time
                    public_user?.uid = uid
                    public_user?.loc_pack = loc_pack
                    public_user?.country = country
                    
                    if (diff.type == .added) {
//                        print("New item")
                        
                        if !self.setOtherAccountListeners.keys.contains(uid) {
                            self.listenForAnotherUserInfo(user_id: uid)
                        }
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                    }
                }
                
                print("loaded \(snapshot.documentChanges.count) public accounts")
            }
        
        setPublicDataListeners.append(pubLocationRef)
    }
    
    // MARK: -Flagged Words Listeners
    func listenForFlaggedWords(){
        var flagRef = db
            .collection(constants.flagged_words)
            .addSnapshotListener{querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    let timestamp = diff.document.data()["timestamp"] as? Int
                    let word = diff.document.data()["title"] as! String
                    let id = diff.document.data()["id"] as! String
                    
                    var f_word = self.getFlaggedIfExists(word: word)
                    if f_word == nil {
                        f_word = FlaggedWord(context: self.context)
                        f_word?.timestamp = Int64(timestamp!)
                        f_word?.word = word
                        f_word?.id = id
                    }
                    
                    if (diff.type == .added) {
                        
                    }
                    if (diff.type == .modified) {
//                        print("Modified item")
                    }
                    if (diff.type == .removed) {
//                        print("Removed item")
                        self.context.delete(f_word!)
                    }
                    
                    
                }
                self.saveContext(self.constants.refresh_app)
            }
    }
    
    
    
    
    func removeFirebaseListeners(){
        //remove each listener weve set
        for item in setAccountListners {
            item.remove()
        }
        
        for item in setContactListners.keys {
            for listener in setContactListners[item]! {
                listener.remove()
            }
        }
        
        for item in setJobListeners.keys {
            for listener in setJobListeners[item]! {
                listener.remove()
            }
        }
        
        for item in setOtherAccountListeners.keys {
            for listener in setOtherAccountListeners[item]! {
                listener.remove()
            }
        }
        
        for item in setPublicDataListeners {
            item.remove()
        }
        
        for item in setTagListeners.keys {
            for listener in setTagListeners[item]! {
                listener.remove()
            }
        }
        
        print("removing \(setAccountListners.count) account listnerers")
        setAccountListners.removeAll()
        setContactListners.removeAll()
        setJobListeners.removeAll()
        setOtherAccountListeners.removeAll()
        setPublicDataListeners.removeAll()
        setTagListeners.removeAll()
    }
    
    func saveContext(_ notification_name: String){
        do{
            try context.save()
            NotificationCenter.default.post(name: NSNotification.Name(notification_name), object: "listener")
            
            if notification_name == constants.refresh_account{
                self.updateAppliedJobs()
                self.updateViews()
            }
        }catch{
            
        }
    }
    
    
    
    // MARK: -Core Data Functions
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
    
    func getAppDataIfExists() -> AppData? {
        do{
            let request = AppData.fetchRequest() as NSFetchRequest<AppData>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }else{
                let new_app_data = AppData(context: self.context)
                self.saveContext("")
                return new_app_data
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getContactIfExists(uid: String) -> Contact? {
        do{
            let request = Contact.fetchRequest() as NSFetchRequest<Contact>
            let predic = NSPredicate(format: "rated_user == %@", uid)
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
    
    func getUploadedJobIfExists(job_id: String) -> UploadedJob? {
        do{
            let request = UploadedJob.fetchRequest() as NSFetchRequest<UploadedJob>
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
    
    func getNotificationIfExists(notif_id: String) -> Notification? {
        do{
            let request = Notification.fetchRequest() as NSFetchRequest<Notification>
            let predic = NSPredicate(format: "notif_id == %@", notif_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getComplaintsIfExists(id: String) -> Complaint? {
        do{
            let request = Complaint.fetchRequest() as NSFetchRequest<Complaint>
            let predic = NSPredicate(format: "id == %@", id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getQualificationIfExists(qualification_id: String) -> Qualification? {
        do{
            let request = Qualification.fetchRequest() as NSFetchRequest<Qualification>
            let predic = NSPredicate(format: "qualification_id == %@", qualification_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getTagIfExists(job_id: String, tag_title: String) -> JobTag? {
        var job = getJobIfExists(job_id: job_id)
        if job == nil {
            return nil
        }
        
        for tag in job!.tags!.allObjects {
            let job_tag = tag as? JobTag
            if job_tag?.title == tag_title {
                return job_tag
            }
        }
        
        return nil
        
    }

    func getJobViewIfExists(viewer_id: String, job_id: String) -> JobView? {
        do{
            let request = JobView.fetchRequest() as NSFetchRequest<JobView>
            let predic = NSPredicate(format: "job_id == %@", job_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                for item in items {
                    if item.viewer_id == viewer_id {
                        return item
                    }
                }
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getJobApplicantIfExists(applicant_uid: String) -> JobApplicant? {
        do{
            let request = JobApplicant.fetchRequest() as NSFetchRequest<JobApplicant>
            let predic = NSPredicate(format: "applicant_uid == %@", applicant_uid)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getGlobalTagIfExists(tag_title: String) -> GlobalTag?{
        do{
            let request = GlobalTag.fetchRequest() as NSFetchRequest<GlobalTag>
            let predic = NSPredicate(format: "title == %@", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func deleteTagAssociates(tag_title: String){
        do{
            let request = JobTag.fetchRequest() as NSFetchRequest<JobTag>
            let predic = NSPredicate(format: "title == %@ && global == \(NSNumber(value: true))", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                for item in items {
                    context.delete(item)
                }
            }
            saveContext(constants.refresh_app)
            
        }catch {
            
        }
    }
    
    func getTagAssociateIfExists(tag_title: String, job_id: String) -> JobTag? {
        do{
            let request = JobTag.fetchRequest() as NSFetchRequest<JobTag>
            let predic = NSPredicate(format: "title == %@ && global == \(NSNumber(value: true))", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                for tag in items{
                    if tag.job_id! == job_id {
                        return tag
                    }
                }
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func doesTagHaveAssociate(_ g_tag_associates: [JobTag], _ tag: JobTag?) -> Bool{
        for t in g_tag_associates{
            if t.title == tag?.title {
                return true
            }
        }
        return false
    }
    
    func getFlaggedIfExists(word: String) -> FlaggedWord? {
        do{
            let request = FlaggedWord.fetchRequest() as NSFetchRequest<FlaggedWord>
            let predic = NSPredicate(format: "word == %@", word)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    
    func getJobApplicationIfExists(job_id: String, user_id: String) -> JobApplications? {
        do{
            let request = JobApplications.fetchRequest() as NSFetchRequest<JobApplications>
            let predic = NSPredicate(format: "job_id == %@", job_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                for item in items{
                    if item.user_id! == user_id{
                        return item
                    }
                }
                return nil
            }
            
        }catch {
            
        }
        
        return nil
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
    
    func getJobPaymentIfExists(payment_id: String) -> JobPayment? {
        do{
            let request = JobPayment.fetchRequest() as NSFetchRequest<JobPayment>
            let predic = NSPredicate(format: "payment_id == %@", payment_id)
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
        var my_id = Auth.auth().currentUser!.uid

        for item in ratings {
            print("filtering rating:-------------> \(item.rating_id!)")
            let job_id = item.job_id
            let job = self.getJobIfExists(job_id: job_id!)

            var req_id_format = "\(job!.uploader_id!)\(job_id!)"
            if amIAirworker(){
                var unreq_id_format = "\(job_id!)"
                if (item.rating_id! != unreq_id_format && job!.uploader_id! != my_id){
                    filtered_items.append(item)
                }
            }else{
                if item.rating_id! == req_id_format{
                    filtered_items.append(item)
                }
            }
        }

        return filtered_items
    }
    
    
    
}

