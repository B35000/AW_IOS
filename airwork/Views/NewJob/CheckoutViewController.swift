//
//  CheckoutViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import Firebase
import CoreData

class CheckoutViewController: UIViewController, UICollectionViewDataSource,
                              UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var jobDateLabel: UILabel!
    @IBOutlet weak var jobAmountLabel: UILabel!
    @IBOutlet weak var tagsCollection: UICollectionView!
    @IBOutlet weak var jobTimeLabel: UILabel!
    @IBOutlet weak var jobDurationLabel: UILabel!
    @IBOutlet weak var openFinish: UIButton!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let db = Firestore.firestore()
    var constants = Constants.init()
    
    var titleText = ""
    var details = ""
    var pickedImages: [UIImage] = []
    var number = 0
    var selectedTags: [String] = []
    var date = Date()
    var time_duration = ""
    var days_duration = 0
    var location_desc = ""
    var lat = 0.0
    var lng = 0.0
    var amount = 0
    var is_job_private = false
    var pickedUsers: [String] = []
    var picked_doc: Data? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let i = navigationController?.viewControllers.firstIndex(of: self)
        let payVC = (navigationController?.viewControllers[i!-1]) as! WorkerPayViewController
        let locVC = (navigationController?.viewControllers[i!-2]) as! LocationViewController
        let durationVC = (navigationController?.viewControllers[i!-3]) as! DurationViewController
        let dateTimeVC = (navigationController?.viewControllers[i!-4]) as! DateTimeViewController
        let tagsVC = (navigationController?.viewControllers[i!-5]) as! NewJobTagsViewController
        let numWorkersVC = (navigationController?.viewControllers[i!-6]) as! NumOfWorkersViewController
        let titleVC = (navigationController?.viewControllers[i!-7]) as! NewJobTitleViewController
        
        titleText = titleVC.titleText
        details = titleVC.detailsTextField.text
        pickedImages = titleVC.pickedImages
        pickedUsers = titleVC.pickedUsers
        number = numWorkersVC.number
        if number == 0 {
            number = constants.maxNumber
        }
        
        selectedTags = tagsVC.selectedTags
        time_duration = durationVC.time_duration
        if time_duration == "" {
            time_duration = constants.durationless
        }
        days_duration = durationVC.days_duration
        location_desc = locVC.location_desc
        lat = locVC.lat
        lng = locVC.lng
        amount = payVC.amount
        date = dateTimeVC.datePicker.date
        picked_doc = titleVC.picked_doc
        
        let year: String = gett("yyyy", date)
        let month: String = gett("MM", date)//then MMM for month name in short eg. 'Jan' and MMMM for full name eg. 'January'
        let day: String = gett("dd", date) //EEEE for name of day eg. 'Sunday' then EE for short eg 'Tue'
        let hour: String = gett("HH", date)
        let min: String = gett("mm", date)
        
        let time_in_mills = Int64((self.date.timeIntervalSince1970 * 1000.0).rounded())
        
//        let date1 = DateComponents(calendar: .current, year: 2014, month: 11, day: 28, hour: 5, minute: 9).date!
//        let date2 = DateComponents(calendar: .current, year: 2015, month: 8, day: 28, hour: 5, minute: 9).date!
        var timeOffset = Date().offset(from: date)
        if timeOffset == "" {
            timeOffset = date.offset(from: Date())
        }
        print("timeOffset: \(timeOffset) reverse: \(date.offset(from: Date()))")
        
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        let curr = me?.phone?.country_currency as! String
        
        jobTitleLabel.text = titleText
        jobDateLabel.text = "In \(timeOffset)"
        jobAmountLabel.text = "\(curr) \(amount) Quoted."
        if amount == 0 {
            jobAmountLabel.text = ""
        }
        jobTimeLabel.text = "At \(hour):\(min) Hrs."
        
        if days_duration == 0 {
            jobDurationLabel.text = "For \(time_duration)"
            if time_duration == constants.durationless {
                jobDurationLabel.text = " "
            }
        } else {
            jobDurationLabel.text = "For \(days_duration) days."
        }
        
        
        tagsCollection.delegate = self
        tagsCollection.dataSource = self
        
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    

    @IBAction func whenUploadTapped(_ sender: Any) {
        uploadTheJob()
    }
    
    @IBAction func whenCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    func uploadTheJob(){
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        
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
       
        let upload_time = Int64((self.date.timeIntervalSince1970 * 1000.0).rounded())
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
        
        var isJobOk = self.isJobDataOk()
        
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
            "taken_down": !isJobOk,
            "auto_taken_down" : isJobOk
        ]
        
        let refData: [String: Any] = [
            "job_id" : key,
            "country_name" : me!.phone!.country_name!,
            "location" : location,
            "pay" : pay,
            "upload_time" : upload_time,
            "selected_date" : selected_date
        ]
        
        if picked_doc != nil {
            let storageRef = Storage.storage().reference()
            let ref = storageRef.child(constants.users_data)
                .child(uid)
                .child(constants.job_document)
                .child("\(key).pdf")
            
            let uploadTask = ref.putData(picked_doc!, metadata: nil) { (metadata, error) in
              guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
              }
              // Metadata contains file metadata such as size, content-type.
              let size = metadata.size
                print("set doc in db")
                self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: self.picked_doc!, author_id: uid)
            }
        }
        
        
        print("starting upload ...")
        db.collection(constants.users_ref)
            .document(uid)
            .collection(constants.job_history)
            .document(key)
            .setData(refData)
        
        self.showLoadingScreen()
        newJobRef.setData(docData){ err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
                self.openFinish.sendActions(for: .touchUpInside)
                self.hideLoadingScreen()
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
    
    struct selected_users_class: Codable{
        var selected_users_for_job = [String]()
    }
    
    
    func isJobDataOk() -> Bool{
        let flagged_words = getFlaggedWordsIfExists()
        
        for word in flagged_words {
            if self.titleText.contains(word!.word!) {
                return false
            }
            
            if self.details.contains(word!.word!) {
                return false
            }
            
            for item in selectedTags {
                if item == word!.word! {
                    return false
                }
            }
        }
        
        return true
    }
    
    
    //MARK: - TAGS COLLECTION VIEW
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedTags.count
//        return 2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "CheckoutJobTagCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ConfirmJobTagCollectionViewCell
        let tag = selectedTags[indexPath.row]
//        
        cell.title.text = tag
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        
        return 4;
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
    
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
    
    
    func getFlaggedWordsIfExists() -> [FlaggedWord?] {
        do{
            let request = FlaggedWord.fetchRequest() as NSFetchRequest<FlaggedWord>
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
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
