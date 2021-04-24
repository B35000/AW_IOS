//
//  QuickJobViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 22/02/2021.
//

import UIKit
import GoogleMaps
import CoreData
import Firebase
import MapKit
import CoreLocation

class QuickJobViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var applicantsCollection: UICollectionView!
    @IBOutlet weak var applicantsContainerView: UIView!
    @IBOutlet weak var tagsCollection: UICollectionView!
    
    @IBOutlet weak var userIconImage: UIImageView!
    @IBOutlet weak var applicantNameLabel: UILabel!
    @IBOutlet weak var applicantVerifiedImage: UIImageView!
    @IBOutlet weak var applicationTimeLabel: UILabel!
    @IBOutlet weak var applicantsRatingsLabel: UILabel!
    @IBOutlet weak var applicantAmountLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var applicantCard: UIView!
    @IBOutlet weak var viewApplicantButton: UIButton!
    @IBOutlet weak var noApplicationsView: UIView!
    
    @IBOutlet weak var viewFirstApplicantButton: UIButton!
    @IBOutlet weak var firstApplicantCardView: CardView!
    
    @IBOutlet weak var estimatePriceContainer: UIView!
    @IBOutlet weak var estimatedPriceLabel: UILabel!
    @IBOutlet weak var jobLocationSwitch: UISwitch!
    
    @IBOutlet weak var myLocationImage: UIImageView!
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let db = Firestore.firestore()
    let constants = Constants.init()
    var job: Job?
    var job_id = ""
    var jobTags = [JobTag]()
    var jobApplicants = [JobApplicant]()
    var pickedUsers: [String] = []
    
    let locationManager = CLLocationManager()
    var myLat = 0.0
    var myLong = 0.0
    
    var myLocationMarker: GMSMarker?
    var myLocationCircle: GMSCircle?
    var addedMarkers = [String : GMSMarker]()
    var addedCircles = [String : GMSCircle]()
    var addedLines = [String : [GMSPolyline]]()
    
    var jobsViews = [String]()
    var jobApplicantsUids = [String]()
    var pickedApplicantsUids = [String]()
    var selectedUsers = [String]()
    
    let MAX_DISTANCE_TRHESHOLD = 7000.0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpViews()
        setUpMap()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_job), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_account), object: nil)
        
    }
    
    @objc func didGetNotification(_ notification: Notification){
        print("refreshing job!")
        setUpViews()
    }
    
    struct selected_users_class: Codable{
        var selected_users_for_job = [String]()
    }
    
    func setUpViews(){
        job = self.getJobIfExists(job_id: job_id)
        jobTags.removeAll()
        for tag in job!.tags! {
            jobTags.append(tag as! JobTag)
        }
        jobApplicants.removeAll()
        jobApplicants = self.getJobApplicantsIfExists(job_id: job_id)
        
        jobsViews.removeAll()
        jobApplicantsUids.removeAll()
        pickedApplicantsUids.removeAll()
        
        let view_objs = self.getJobViewsIfExists(job_id: job_id)
        for item in view_objs {
            jobsViews.append(item.viewer_id!)
        }
        
        let applicant_objs = self.getJobApplicantsIfExists(job_id: job_id)
        for item in applicant_objs {
            jobApplicantsUids.append(item.applicant_uid!)
        }
        
        var selected_users_json = job!.selected_workers
        let decoder = JSONDecoder()
        
        do{
            var selected_users = selected_users_class()
            
            if selected_users_json != nil && selected_users_json != "" {
                let jsonData = selected_users_json!.data(using: .utf8)!
                selected_users = try decoder.decode(selected_users_class.self ,from: jsonData)
            }
            
            if !selected_users.selected_users_for_job.isEmpty {
                print("job is private, loaded---------------------- \(selected_users.selected_users_for_job)")
                selectedUsers.append(contentsOf: selected_users.selected_users_for_job)
            }
        }catch{
            print("\(error.localizedDescription)")
        }
        
        
        tagsCollection.delegate = self
        tagsCollection.dataSource = self
        
        
        applicantsCollection.delegate = self
        applicantsCollection.dataSource = self
        
        applicantsCollection.reloadData()
    
        if jobApplicants.isEmpty{
            applicantsContainerView.isHidden = true
        }else{
            if jobApplicants.count > 1 {
                applicantsContainerView.isHidden = false
            }else{
                applicantsContainerView.isHidden = true
            }
        }
        
        
        titleLabel.text = job!.job_title!
        var view_count = self.getJobViewsIfExists(job_id: job_id)
        viewsLabel.text = "\(view_count.count) views"
        if view_count.count == 1 {
            viewsLabel.text = "\(view_count.count) view"
        }
        
        
        let date = DateComponents(calendar: .current, year: Int(job!.start_year), month: Int(job!.start_month)+1, day: Int(job!.start_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
        }
        var applicants = self.getJobApplicantsIfExists(job_id: job!.job_id!)
        
        if applicants.isEmpty {
            applicantCard.isHidden = true
            noApplicationsView.isHidden = false
        }else{
            applicantCard.isHidden = false
            noApplicationsView.isHidden = true
            
            var firstApplicant = applicants[0]
            var theirAcc = self.getApplicantAccount(user_id: firstApplicant.applicant_uid!)
            var selected_users = selected_workers()
            
            if job!.selected_workers != nil {
                var selected_users_json = job!.selected_workers!
                let decoder = JSONDecoder()
                let jsonData = selected_users_json.data(using: .utf8)!
                
                do{
                    if selected_users_json != "" {
                        selected_users = try decoder.decode(selected_workers.self ,from: jsonData)
                    }
                    //if applicant has been selected
                    if !selected_users.worker_list.isEmpty {
                        //lets show the first person picked instead
                        pickedApplicantsUids.append(contentsOf: selected_users.worker_list)
                        
                        let first = selected_users.worker_list[0]
                        
                        for item in applicants {
                            if item.applicant_uid == first{
                                firstApplicant = item
                                theirAcc = self.getApplicantAccount(user_id: firstApplicant.applicant_uid!)
                            }
                        }
                        
                    }
                    
                }catch{
                    print("error loading selected users")
                }
            }
            
            //set the applicants name
            applicantNameLabel.text = theirAcc!.name
            
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
            
            if selected_users.worker_list.contains(firstApplicant.applicant_uid!){
                //the user has been selected!
                selectedLabel.isHidden = false
                
                let ratings = getAccountRatings(firstApplicant.applicant_uid!)
                if !ratings.isEmpty {
                    
                    if ratings.count > 3 {
                        var last3 = Array(ratings.suffix(3))
                        var total = 0.0
                        for item in last3 {
                            total += Double(item.rating)
                        }
                    }else{
                        //less than 3
                        var total = 0.0
                        for item in ratings {
                            total += Double(item.rating)
                        }
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
            
            
            
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(QuickJobViewController.whenViewApplicantTapped))
        firstApplicantCardView.addGestureRecognizer(tap)
        
    }
    
    @objc func whenViewApplicantTapped(sender:UITapGestureRecognizer) {
        viewFirstApplicantButton.sendActions(for: .touchUpInside)
    }
    
    @IBAction func viewApplicantsTapped(_ sender: Any) {
        let homeVC = ((self.presentingViewController as! UITabBarController).viewControllers![0] as! UINavigationController).viewControllers[0] as! HomeViewController
        homeVC.selectedQuickJob = job_id
        
        dismiss(animated: true, completion: nil)
        homeVC.openQuickJobApplicantsButton.sendActions(for: .touchUpInside)
        
    }
    
    @IBAction func viewDetailsTapped(_ sender: Any) {
        let homeVC = ((self.presentingViewController as! UITabBarController).viewControllers![0] as! UINavigationController).viewControllers[0] as! HomeViewController
        homeVC.selectedQuickJob = job_id
        
        dismiss(animated: true, completion: nil)
        homeVC.openQuickJobDetailsButton.sendActions(for: .touchUpInside)
    }
    
    @IBAction func viewFirstApplicantTapped(_ sender: Any) {
        let homeVC = ((self.presentingViewController as! UITabBarController).viewControllers![0] as! UINavigationController).viewControllers[0] as! HomeViewController
        homeVC.selectedQuickJob = job_id
        
        dismiss(animated: true, completion: nil)
        homeVC.openFirstQuickJobApplicantButton.sendActions(for: .touchUpInside)
    }
    
    struct selected_workers: Codable{
        var worker_list = [String]()
    }
    
    
    
    var at_most_2 = "At most 2 hours."
    var two_to_four = "Around 2 to 4 hours."
    var whole_day = "The whole day."
    
    func calculatePriceFromTag(){
        var selectedTags = [String]()
        for item in jobTags {
            selectedTags.append(item.title!)
        }
        
        let prices = constants.getTagPricesForTags(selected_tags: selectedTags, context: self.context)
//        estimatePriceContainer.isHidden = true
        
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        let curr = me?.phone?.country_currency as! String
        
        if !prices.isEmpty {
            print("prices being used for calculation:--------------> \(prices.count)")
           
            var top = Int(constants.getTopAverage(prices))
            var bottom = Int(constants.getBottomAverage(prices))
            
            if prices.count == 1 {
                top = Int(prices[0])
                bottom = Int(prices[0])
            }
            
            if (top != 0  && top != bottom) {
                estimatedPriceLabel.text = "\(bottom) - \(top) \(curr), for ~2hrs"
//                estimatePriceContainer.isHidden = false
            }else if (top != 0  && top == bottom) {
                estimatedPriceLabel.text = "~ \(top) \(curr)"
//                estimatePriceContainer.isHidden = false
            }else{
                estimatedPriceLabel.text = ""
            }
        }else{
            estimatedPriceLabel.text = ""
        }
    }
    
    
    
    
    var hasLoadedMap = false
    func setUpMap(){
        self.mapView.alpha = 0
        
        self.pickedUsers.removeAll()
        self.pickedUsers = getAppropriateUsers()
        
        if !hasLoadedMap {
            hasLoadedMap = true
            do {
                 // Set the map style by passing the URL of the local file.
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
        }
                
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = false
        mapView.layer.cornerRadius = 0
        mapView.delegate = self
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `2.0` to the desired number of seconds.
               // Code you want to be delayed
//                let camera = GMSCameraPosition.camera(withLatitude: self.myLat, longitude: self.myLong, zoom: 15.0)
//                self.mapView.alpha = 1
//                self.mapView.camera = camera
            }
            
        }
        
        
    }
    
    @IBAction func whenMyLocationTapped(_ sender: Any) {
        print("show my location tapped ------------------------")
        if myLat != 0.0 && myLong != 0.0 {
            self.moveCamera(self.myLat, self.myLong)
        }else{
            self.setUpMap()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        
        self.jobLocationSwitch.isEnabled = true
        self.myLocationImage.image = UIImage(named: "KnownLocation")
        
        if(self.myLat == 0.0){
            self.myLat = locValue.latitude
            self.myLong = locValue.longitude
            
            self.moveCamera(locValue.latitude, locValue.longitude)
            self.setMyLocation(locValue.latitude, locValue.longitude)
            self.setAllUsersOnMap()
            
            if (self.job!.location_lat == 0.0 && self.job!.location_long == 0.0) {
                self.jobLocationSwitch.isOn = false
            }else{
                self.jobLocationSwitch.isOn = true
            }
        }
        self.myLat = locValue.latitude
        self.myLong = locValue.longitude
        
    }
    
    @IBAction func whenLocationSwitchTapped(_ sender: UISwitch) {
        if sender.isOn {
            self.setMyLocationInJob(self.myLat, self.myLong)
        }else{
            let db = Firestore.firestore()
            let uid = Auth.auth().currentUser!.uid
            
            let location: [String: Any] = [
                "latitude" : 0.0,
                "longitude" : 0.0,
                "description" : ""
            ]
            
            let docData: [String: Any] = [
                "location" : location
            ]
            
            let refData: [String: Any] = [
                "location" : location
            ]
            
            
            let newJobRef = db.collection(self.constants.jobs)
                .document(self.job!.country_name!)
                .collection("country_jobs")
                .document(self.job_id)
            
            db.collection(self.constants.users_ref)
                .document(uid)
                .collection(self.constants.job_history)
                .document(self.job_id)
                .updateData(refData)
            
            newJobRef.updateData(docData){ err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
    }
    
    
    func moveCamera(_ lat: Double,_ long: Double){
        mapView.animate(to: GMSCameraPosition(latitude: lat, longitude: long, zoom: 15))
    }
    
    func setMyLocation(_ lat: Double,_ long: Double){
        var position = CLLocationCoordinate2DMake(lat, long)
        var marker = GMSMarker(position: position)
        
        let circleCenter = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let circle = GMSCircle(position: circleCenter, radius: 1000)
        
        circle.fillColor = UIColor(red: 113, green: 204, blue: 231, alpha: 0.1)
        circle.strokeColor = .none
        
        circle.map = mapView
        
        marker.icon = UIImage(named: "MyLocationIcon")
        marker.map = mapView
        
        self.myLocationMarker = marker
        self.myLocationCircle = circle
    
    }
    
    func setMyLocationInJob(_ lat: Double,_ lng: Double){
        
        guard let filePath = Bundle.main.path(forResource: "maps-Info", ofType: "plist") else {
              fatalError("Couldn't find file 'maps-Info.plist'.")
            }
            // 2
            let plist = NSDictionary(contentsOfFile: filePath)
            guard let value = plist?.object(forKey: "GEO_API_KEY") as? String else {
              fatalError("Couldn't find key 'GEO_API_KEY' in 'maps-Info.plist'.")
            }
        
        var url: String = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(lng)&key=\(value)"
        
        var request : NSMutableURLRequest = NSMutableURLRequest()
        request.url = NSURL(string: url) as URL?
        request.httpMethod = "GET"

        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse!, data: Data!, error: Error!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
            do{
                let jsonResult: NSDictionary! = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary

                if (jsonResult != nil) {
                    // process jsonResult

                    let results = jsonResult["results"] as! NSArray
                    let result_title = (results[0] as! NSDictionary)["formatted_address"] as! String
                    
                    print(result_title)
                    let location_desc = result_title
                    
                    DispatchQueue.main.async {
                        let db = Firestore.firestore()
                        let uid = Auth.auth().currentUser!.uid
                        
                        let location: [String: Any] = [
                            "latitude" : lat,
                            "longitude" : lng,
                            "description" : location_desc
                        ]
                        
                        let docData: [String: Any] = [
                            "location" : location
                        ]
                        
                        let refData: [String: Any] = [
                            "location" : location
                        ]
                        
                        
                        let newJobRef = db.collection(self.constants.jobs)
                            .document(self.job!.country_name!)
                            .collection("country_jobs")
                            .document(self.job_id)
                        
                        db.collection(self.constants.users_ref)
                            .document(uid)
                            .collection(self.constants.job_history)
                            .document(self.job_id)
                            .updateData(refData)
                        
                        newJobRef.updateData(docData){ err in
                            if let err = err {
                                print("Error writing document: \(err)")
                            } else {
                                print("Document successfully written!")
                            }
                        }
                        
                    }
                    
                } else {
                   // couldn't load JSON, look at error
                }
            }catch {
            
            }


        })
        
        
       
    }
    

    
    
    func setAllUsersOnMap(){
        var bounds = GMSCoordinateBounds()
        for user in pickedUsers{
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
                marker.map = mapView
                
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
            self.mapView.animate(with: update)
        }
    }
    
    func getLineColorForUser(user_id: String) -> UIColor {
        var color = UIColor(red: 40, green: 40, blue: 40, alpha: 0.2)
        color = UIColor(named: "JobUnseen")!
        
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
        }else if selectedUsers.contains(user_id){
            color = UIColor(named: "JobApplied")!
        }
        
        return color
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
        polyline.map = mapView
        
        polyline_list.append(polyline)
        self.addedLines[user] = polyline_list
        
        if jobsViews.contains(user) || jobApplicantsUids.contains(user) || selectedUsers.contains(user){
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
                                polyline.map = self.mapView
                                
                                
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
    
    func runAnimationForDirection(_ polyline_list : [GMSPolyline]){
        for item in polyline_list {
            item.map = nil
        }
        pos = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startAnimation(polyline_list)
        }
    }
    
    var pos = 0
    func startAnimation(_ polyline_list : [GMSPolyline]){
        polyline_list[pos].map = mapView
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            print("running animation")
            self.pos += 1
            if polyline_list.count >= self.pos + 1 {
                self.startAnimation(polyline_list)
            }
        }
    }
    
    
    func getAverage(_ ratings: [Rating]) -> Double{
        var total = 0.0
        for item in ratings {
            total += Double(item.rating)
        }
        return round(10 * total/Double(ratings.count))/10
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
        self.pickedUsers.removeAll()
        let pub_users = self.getSharedLocationUsersIfExists()
        var picked_users = [String]()
        
        for item in pub_users{
            picked_users.append(item.uid!)
        }
        return picked_users
        
        
        return picked_users
    }
    
    
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        //viewDetailsSegue
        //viewApplicantsSegue
        //editQuickJobSegue
        
        switch(segue.identifier ?? "") {
                        
        case "viewDetailsSegue":
            guard let jobDetailViewController = segue.destination as? JobDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            jobDetailViewController.job_id = job_id
        
        case "viewApplicantsSegue":
            guard let allApplicantsViewController = segue.destination as? AllApplicantsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            allApplicantsViewController.job_id = job_id
            
        case "editQuickJobSegue":
            guard let editViewController = segue.destination as? EditJobViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            editViewController.job_id = job_id
            
        default:
            print("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    
    // MARK: - Image Collection Views
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagsCollection{
            return jobTags.count
        }else{
            return jobApplicants.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == tagsCollection {
            let reuseIdentifier = "QuickJobTagCell"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! QuickJobTagCollectionViewCell
            
            let tag = jobTags[indexPath.row]
            
            cell.tagTitleLabel.text = tag.title
            
            return cell
            
        }else{
            let reuseIdentifier = "ApplicantImageCell"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AppliedUserCollectionViewCell
            
            let applicant = jobApplicants[indexPath.row]
            
            let storageRef = Storage.storage().reference()
            let ref = storageRef.child(constants.users_data)
                .child(applicant.applicant_uid!)
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
                        
                        self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: applicant.applicant_uid!)
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
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         // handle tap events
         print("You selected cell \(indexPath.item)!")
        
        if collectionView == applicantsCollection{
            var user_id = self.jobApplicants[indexPath.row]
            var drawn_paths = self.addedLines[user_id.applicant_uid!]
            
            if drawn_paths != nil {
                self.runAnimationForDirection(drawn_paths!)
            }
        }
     }

    
    
    
    // MARK: - Coredata
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
    
    func getUploadedJobsIfExists() -> [UploadedJob] {
        do{
            let request = UploadedJob.fetchRequest() as NSFetchRequest<UploadedJob>
//            let predic = NSPredicate(format: "job_id == %@", job_id)
//            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
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
    

    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
    
}
