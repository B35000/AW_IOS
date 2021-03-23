//
//  PickUserViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 15/02/2021.
//

import UIKit
import GoogleMaps
import CoreData
import Firebase

class PickUserViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,
                              GMSMapViewDelegate {
    @IBOutlet weak var searchTagField: UITextField!
    @IBOutlet weak var tagsCollection: UICollectionView!
    @IBOutlet weak var pickedUsersCollection: UICollectionView!
    @IBOutlet weak var mapView: GMSMapView!
    
    var selectedTags: [String] = []
    var pickedUsers: [String] = []
    var selectedUsers: [String] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var tags_to_show: [String] = []
    var typedItem = ""
    let db = Firestore.firestore()
    let constants = Constants.init()
    var addedMarkers = [String : GMSMarker]()
    var addedCircles = [String : GMSCircle]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tags_to_show = getTheTagsToShow()
        tagsCollection.dataSource = self
        tagsCollection.delegate = self
        
        
        pickedUsers = getAppropriateUsers()
        pickedUsersCollection.delegate = self
        pickedUsersCollection.dataSource = self
        
        if pickedUsers.isEmpty{
            pickedUsersCollection.isHidden = true
        }else{
            pickedUsersCollection.isHidden = false
        }
        
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
                
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = true
        mapView.layer.cornerRadius = 0
        mapView.delegate = self
        
        setAllUsersOnMap()
    }
    
    func setAllUsersOnMap(){
        for user in pickedUsers{
            var their_loc = getPubUsersLocation(user)
            
            if their_loc != nil {
                var user_ratings = self.getRatingsMatchingPickedTags(user)
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
                
                addedMarkers[user] = marker
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
    
    func moveCamera(_ lat: Double,_ long: Double){
        mapView.animate(to: GMSCameraPosition(latitude: lat, longitude: long, zoom: 15))
        
    }
    
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        print("tapped on marker")

//        let pickedMarkerUser = addedMarkers[marker]!
//        if(selectedUsers.contains(pickedMarkerUser)){
//            let pos = selectedUsers.firstIndex(of: pickedMarkerUser)!
//            selectedUsers.remove(at: pos)
//            marker.icon = UIImage(named: "PickUserIcon")
//        }else{
//            selectedUsers.append(pickedMarkerUser)
//            marker.icon = UIImage(named: "PickedUserIcon")
//        }
//
//        pickedUsers = getAppropriateUsers()
//        pickedUsersCollection.reloadData()
        
        
        return true
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        //openNewJobSegue
        switch(segue.identifier ?? "") {
                        
        case "openNewJobSegue":
            let navVC = segue.destination as? UINavigationController
            let titleVC = navVC?.viewControllers.first as! NewJobTitleViewController
            
            titleVC.pickedUsers = selectedUsers
            
        default:
            print("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    @IBAction func whenSearchTyped(_ sender: UITextField) {
        if !sender.hasText{
            
        }else{
            typedItem = sender.text!

            tags_to_show = getTheTagsToShow()
            tagsCollection.reloadData()
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagsCollection{
            return tags_to_show.count
        }else{
            return pickedUsers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == tagsCollection{
            let reuseIdentifier = "PickUserJobTagCell"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PickedUserTagCollectionViewCell
            
            let tag = tags_to_show[indexPath.row]
            
            cell.tagTitleLabel.text = tag
            if selectedTags.contains(tag){
                cell.tagBackView.backgroundColor = UIColor.darkGray
            }else {
                let c = UIColor(named: "TagBackColor")
                cell.tagBackView.backgroundColor = c
            }
            
            return cell
        }else{
            let reuseIdentifier = "pickedUserItem"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PickedUserCollectionViewCell
            
            let uid = pickedUsers[indexPath.row]
            let user = self.getAccountIfExists(uid: uid)
            let user_ratings = self.getRatingsMatchingPickedTags(uid)
            let users_applications = self.getApplicationsMatchingPickedTags(user_id: uid)
            let shared_pub_user = self.getSharedLocationUserIfExists(user_id: uid)
            
            
            if user_ratings.isEmpty{
                cell.ratingsLabel.text = "New!."
            }else if user_ratings.count == 1 {
                cell.ratingsLabel.text = "\(user_ratings.count) Rating."
            }else{
                cell.ratingsLabel.text = "\(user_ratings.count) Ratings."
            }
            
            if users_applications.isEmpty{
                cell.applicationsLabel.text = "New!."
            }else if users_applications.count == 1 {
                cell.applicationsLabel.text = "\(users_applications.count) Applications."
            }else{
                cell.applicationsLabel.text = "\(users_applications.count) Applications."
            }
            
            var date = Date(timeIntervalSince1970: TimeInterval(shared_pub_user!.last_online) / 1000)
            var timeOffset = date.offset(from: Date())
            if timeOffset == "" {
                timeOffset = Date().offset(from: date)
                cell.lastOnlineLabel.text = "Active: \(timeOffset) ago."
            }else{
                cell.lastOnlineLabel.text = "Active: \(timeOffset) ago."
            }
            
            print("user \(uid) : ratings: \(user_ratings.count) , applications: \(users_applications.count)")
            
            if selectedUsers.contains(uid){
                cell.mapIconView.image = UIImage(named: "PickedUserIcon")
            }else{
                cell.mapIconView.image = UIImage(named: "PickUserIcon")
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         // handle tap events
         print("You selected cell \(indexPath.item)!")
        
        if collectionView == tagsCollection{
            var selected_t = tags_to_show[indexPath.row]
            if !selectedTags.contains(selected_t){
                selectedTags.append(selected_t)
            }else{
                selectedTags.remove(at: indexPath.row)
            }
            searchTagField.text = ""
            typedItem = ""
            
            tags_to_show = getTheTagsToShow()
            tagsCollection.reloadData()
            
            pickedUsers = getAppropriateUsers()
            pickedUsersCollection.reloadData()
            
            if pickedUsers.isEmpty{
                pickedUsersCollection.isHidden = true
            }else{
                pickedUsersCollection.isHidden = false
            }
            
        }else{
            var picked_user = pickedUsers[indexPath.row]
            var their_loc = getPubUsersLocation(picked_user)
            
            if their_loc != nil {
                self.moveCamera(their_loc!.latitude, their_loc!.longitude)
            }else{
                print("thier loc is nil")
            }
            
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
            }
            
            pickedUsers = getAppropriateUsers()
            pickedUsersCollection.reloadData()
            
            if pickedUsers.isEmpty{
                pickedUsersCollection.isHidden = true
            }else{
                pickedUsersCollection.isHidden = false
            }
        }
     }
    
    
    
    
    
    func getAppropriateUsers() -> [String]{
        self.pickedUsers.removeAll()
        let pub_users = self.getSharedLocationUsersIfExists()
        var picked_users = [String]()
        
        if selectedTags.isEmpty{
            for item in pub_users{
                picked_users.append(item.uid!)
            }
            return picked_users
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
        
        
        return picked_users
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
                let tag_associates = getGlobalTagIfExists(tag_title: tag)
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
    
    func getGlobalTagIfExists(tag_title: String) -> [JobTag]{
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
    
    struct json_tag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
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
    

    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
    
}
