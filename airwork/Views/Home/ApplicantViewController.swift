//
//  ApplicantViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 20/01/2021.
//

import UIKit
import Firebase
import CoreData
import Firebase
//import CoreLocation

class ApplicantViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var applicantPickedImage: UIImageView!
    @IBOutlet weak var applicantImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingsLabel: UILabel!
    
    @IBOutlet weak var completedNumberLabel: UILabel!
    @IBOutlet weak var jobsLabel: UILabel!
    @IBOutlet weak var ratedLabel: UILabel!
    @IBOutlet weak var lastThreeNumberLabel: UILabel!
    @IBOutlet weak var lastThreeLabel: UILabel!
    
    @IBOutlet weak var applicationTimeLabel: UILabel!
    @IBOutlet weak var applicationDateLabel: UILabel!
    @IBOutlet weak var amountTitleLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationContainerView: UIView!
    
    @IBOutlet weak var contactContainerView: UIView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var pickApplicantTitle: UILabel!
    @IBOutlet weak var pickApplicantDetailLabel: UILabel!
    @IBOutlet weak var applicantSkillTitleLabel: UILabel!
    @IBOutlet weak var applicantSkillDetailLabel: UILabel!
    @IBOutlet weak var skillsContainerView: UIView!
    
    @IBOutlet weak var addLocButton: UIButton!
    
    
    
    var applicant_id: String = ""
    var job_id: String = ""
    var constants = Constants.init()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let locationManager = CLLocationManager()
    let db = Firestore.firestore()
    var applicant_loc = location_packet()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpApplicantInfo()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_job), object: nil)
        
        locationManager.delegate = self
    }
    
    @objc func didGetNotification(_ notification: Notification){
        print("refreshing job!")
        setUpApplicantInfo()
    }
    
    func setUpApplicantInfo(){
        var applicant_acc = getApplicantAccount(applicant_id)!
        var applicant = getJobApplicantsIfExists(job_id: job_id)[0]
        var job = getJobIfExists(job_id: job_id)!
        
        var selected_users_json = job.selected_workers
        let decoder = JSONDecoder()
        var selected_users = selected_workers()
        
        do{
            if selected_users_json != nil && selected_users_json != "" {
                let jsonData = selected_users_json!.data(using: .utf8)!
                selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
            }
            
            if selected_users.worker_list.contains(applicant_id){
                applicantPickedImage.isHidden = false
                
                //set the pick applicant title
                pickApplicantTitle.text = "Remove \(applicant_acc.name!)"
                pickApplicantDetailLabel.text = "Remove \(applicant_acc.name!) from your picked applicants."
                contactContainerView.isHidden = false
            }else{
                //set the pick applicant title
                pickApplicantTitle.text = "Pick \(applicant_acc.name!)"
                pickApplicantDetailLabel.text = "Pick \(applicant_acc.name!) to do the job."
                contactContainerView.isHidden = true
            }
        
        }catch{
            print("error loading selected users")
        }
        
        //load the applicant image
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(applicant_acc.uid!)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            self.applicantImage.image = im
              
            let image = self.applicantImage!
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
                    self.applicantImage.image = im
                    
                    let image = self.applicantImage!
                    image.layer.borderWidth = 1
                    image.layer.masksToBounds = false
                    image.layer.borderColor = UIColor.white.cgColor
                    image.layer.cornerRadius = image.frame.height/2
                    image.clipsToBounds = true
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: applicant_acc.uid!)
                }
              }
        }
        
        //load the applicants name
        nameLabel.text = "\(applicant_acc.name!)."
        
        //load the applicants ratings
        let ratings = getAccountRatings(applicant_id)
        if ratings.isEmpty {
            ratingsLabel.text = "New!"
        }else{
            ratingsLabel.text = "\(ratings.count) Ratings."
            if ratings.count == 1 {
                ratingsLabel.text = "1 Rating."
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
                lastThreeLabel.text = "Last \(ratings.count) jobs."
            }
        }
        
        
        //load the application date and time
        var date = Date(timeIntervalSince1970: TimeInterval(applicant.application_time) / 1000)
        
        applicationDateLabel.text = "On \(gett("EEEE", date)), \(gett("d", date)) \(gett("MMM", date)) \(gett("yyyy", date))"
        
        //set application time
        applicationTimeLabel.text = "@\(gett("h", date)):\(gett("mm", date))\(self.gett("a", date).lowercased())"
        
        
        //set the amount
        if (applicant.application_pay_amount == 0) {
            amountLabel.text = "\(job.pay_currency!)  \(job.pay_amount)"
        }else{
            amountLabel.text = "\(applicant.application_pay_currency!)  \(applicant.application_pay_amount)"
            
            amountTitleLabel.text = "For the amount:"
        }
        
        
        //set the email and phone
        emailLabel.text = applicant_acc.email
        numberLabel.text = "\(applicant_acc.phone!.country_number_code!) \(applicant_acc.phone!.digit_number)"
        
        
        
        //set the applicant skills
        skillsContainerView.isHidden = false
            var skills = getJobApplicantSkillsIfExists(applicant_id: applicant_id)
            if skills.isEmpty{
                skillsContainerView.isHidden = true
            }else{
                if applicant_acc.gender == "Female"{
                    applicantSkillTitleLabel.text = "Her Skills"
                    applicantSkillDetailLabel.text = "She has \(skills.count) added skills."
                }else{
                    applicantSkillTitleLabel.text = "His Skills"
                    applicantSkillDetailLabel.text = "He has \(skills.count) added skills."
                }
            }
        
        loadApplicantLocIfAny()
    }
    
    struct selected_workers: Codable{
        var worker_list = [String]()
    }
    
    
    @IBAction func whenAddLocation(_ sender: Any) {
        let locStatus = CLLocationManager.authorizationStatus()
        
        if locStatus == .notDetermined {
            print("Requesting location")
            locationManager.requestWhenInUseAuthorization()
        }else{
//            locationManager.requestWhenInUseAuthorization()
            
            if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
                print("location permission granted alerady")
                
                var currentLoc: CLLocation? = self.locationManager.location
                print(currentLoc)
                print(currentLoc?.coordinate.longitude)
            
                if currentLoc?.coordinate.latitude != nil {
                    self.showDistanceToUser(lat: currentLoc!.coordinate.latitude,long: currentLoc!.coordinate.longitude)
                }else{
                    self.locationContainerView.isHidden = true
                }
//                showDistanceToUser(lat: -3.0, long: 30.0)
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                
                if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
                    var currentLoc: CLLocation? = self.locationManager.location
                    print(currentLoc?.coordinate.latitude)
                    print(currentLoc?.coordinate.longitude)
                
                    if (currentLoc?.coordinate.latitude != nil && !self.applicant_loc.received_locations.isEmpty) {
                        self.showDistanceToUser(lat: currentLoc!.coordinate.latitude,long: currentLoc!.coordinate.longitude)
                    }else{
                        self.locationContainerView.isHidden = true
                    }
                }
                
            }
        }
    }
    
    func showDistanceToUser(lat: Double, long: Double){
        print("user received locations size: \(applicant_loc.received_locations.count) ")
        var d: Double = distance_between_points(lat1: lat, lng1: long, lat2: applicant_loc.received_locations[0].lat.latitude,
                                        lng2: applicant_loc.received_locations[0].lat.longitude)
        
        if (d < 100){
            locationLabel.text = "Nearby!"
        }else if (d < 1000) {
            locationLabel.text = "\(Int(round(d)))m away."
        }else {
            let d_km = Int(round(Double(d)/1000.0))
            locationLabel.text = "\(d_km)km away."
        }
        
        self.addLocButton.isHidden = true
    }
    
    func distance_between_points(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double{
        let coordinate₀ = CLLocation(latitude: lat1, longitude: lng1)
        let coordinate₁ = CLLocation(latitude: lat2, longitude: lng2)

        let distanceInMeters = coordinate₀.distance(from: coordinate₁)

        
        return round(10 * (distanceInMeters))/10
    }
    
    func loadApplicantLocIfAny(){
        db.collection(constants.airworkers_ref)
            .document(applicant_id)
            .collection(constants.location_data)
            .order(by: "creation_time")
            .getDocuments(){ querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                
                let latest_doc = snapshot.documents[0].data()
                let uid = latest_doc["uid"] as! String
                let loc_id = latest_doc["loc_id"] as! String
                let desc = latest_doc["desc"] as! String
                let creation_time = latest_doc["creation_time"] as! Int
                
                let loc_pack_json_string = latest_doc["loc_pack"] as! String
                let decoder = JSONDecoder()
                let jsonData = loc_pack_json_string.data(using: .utf8)!
                
                do{
                    let des_loc =  try decoder.decode(location_packet.self, from: jsonData)
                    
                    print("loaded a location for user, showing container---------------------------")
                    self.applicant_loc = des_loc
                    self.locationContainerView.isHidden = false
                    
                    if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
                        self.addLocButton.sendActions(for: .touchUpInside)
                    }
                }catch{
                    print("error decoding location data")
                }
            }
    }
    
    struct location_packet: Codable{
        var received_locations = [location_item]()
        var geo_string = ""
        var location_desc = ""
    }
    
    struct location_item: Codable{
        var creation_time = 0
        var lat = LatLng()
    }
    
    struct LatLng: Codable{
        var latitude = 0.0
        var longitude = 0.0
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch(segue.identifier ?? "") {
                        
        case "viewJobHistory":
            guard let jobHistoryViewController = segue.destination as? JobHistoryViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            jobHistoryViewController.applicant_id = applicant_id
            jobHistoryViewController.job_id = job_id
            
        case "viewSkills":
            guard let skillsViewController = segue.destination as? SkillsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            skillsViewController.applicant_id = applicant_id
            skillsViewController.title = getApplicantAccount(applicant_id)!.name
            
        case "pickApplicantSegue":
            guard let selectApplicantViewController = segue.destination as? SelectApplicantViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            selectApplicantViewController.job_id = job_id
            selectApplicantViewController.applicant_id = applicant_id
            selectApplicantViewController.title = getApplicantAccount(applicant_id)!.name
            
        default:
            print("Unexpected Segue Identifier; \(segue.identifier)")
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
    
    func getJobApplicantSkillsIfExists(applicant_id: String) -> [Qualification]{
        do{
            let request = Qualification.fetchRequest() as NSFetchRequest<Qualification>
            
            let predic = NSPredicate(format: "user_id == %@", applicant_id)
            request.predicate = predic
            
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
