//
//  ApplyForJobViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 28/02/2021.
//

import UIKit
import CoreData
import Firebase

class ApplyForJobViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var jobTitleLabel: UILabel!
    @IBOutlet weak var jobDateLabel: UILabel!
    @IBOutlet weak var jobAmountLabel: UILabel!
    @IBOutlet weak var tagsCollection: UICollectionView!
    @IBOutlet weak var jobTimeLabel: UILabel!
    @IBOutlet weak var jobDurationLabel: UILabel!
    
    @IBOutlet weak var userIconImage: UIImageView!
    @IBOutlet weak var applicantNameLabel: UILabel!
    @IBOutlet weak var applicantVerifiedImage: UIImageView!
    @IBOutlet weak var applicantsRatingsLabel: UILabel!
    @IBOutlet weak var jobCountLabel: UILabel!
    @IBOutlet weak var jobSubscriptLabel: UILabel!
    @IBOutlet weak var averageRatingLabel: UILabel!
    @IBOutlet weak var lastRatingNumberLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var applicantHistoryView: UIView!
    
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var suggestedLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var setAmountButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var jobTags = [JobTag]()
    var job_id = ""
    var constants = Constants.init()
    let db = Firestore.firestore()
    var job: Job? = nil
    
    var at_most_2 = "At most 2 hours."
    var two_to_four = "Around 2 to 4 hours."
    var whole_day = "The whole day."
    var selected_tags = [String]()
    var amount = 0
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        setData()
    }
    
    func setData() {
        job = self.getJobIfExists(job_id: job_id)!
        for tag in job!.tags! {
            jobTags.append(tag as! JobTag)
            selected_tags.append((tag as! JobTag).title!)
        }
        
        let my_application = self.getAppliedJobIfExists(job_id: job_id)
        
        if my_application != nil {
            //ive applied for this job,
            self.title = "Remove Application"
            
            if my_application!.application_pay_amount != job!.pay_amount {
                //the amounts are different, so we set their amount in the set amount field
                if my_application!.application_pay_amount != 0 {
                    amountField.text = "\(my_application!.application_pay_amount)"
                }
            }
            finishButton.setTitle("Remove", for: .normal)
        }else{
            // there is no application
            setAmountButton.isHidden = true
        }
        
        
        tagsCollection.delegate = self
        tagsCollection.dataSource = self
        
        setSuggestion(selected_tags: selected_tags)
        
        jobTitleLabel.text = job!.job_title!
        
        var hr = Int(job!.time_hour)
        if job!.am_pm == "PM" {
            hr += 12
        }
        
        let date = DateComponents(calendar: .current, year: Int(job!.start_year), month: Int(job!.start_month)+1, day: Int(job!.start_day), hour: hr, minute: Int(job!.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day), hour: hr, minute: Int(job!.time_minute)).date!
        
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
            jobDateLabel.text = "\(timeOffset) ago."
        }else{
            jobDateLabel.text = "In \(timeOffset)"
        }
        
        if job!.work_duration! == "" {
            timeOffset = end_date.offset(from: date)
            if timeOffset == "" {
                timeOffset = date.offset(from: end_date)
            }
            jobDurationLabel.text = "\(timeOffset)"
            
        }else{
            if job!.work_duration! == constants.durationless {
                jobDurationLabel.text = " "
            }else{
                jobDurationLabel.text = "\(job!.work_duration!)"
            }
            
        }
        
        jobAmountLabel.text = "\(job!.pay_currency!) \(job!.pay_amount) Quoted."
        if job!.pay_amount == 0 {
            jobAmountLabel.isHidden = true
        }else{
            jobAmountLabel.isHidden = false
        }
        jobTimeLabel.text = "At \(job!.time_hour):\(job!.time_minute)\(self.gett("a", date).lowercased())"
        
        
        var my_id = Auth.auth().currentUser!.uid
        var myAccount = self.getApplicantAccount(user_id: my_id)
        applicantNameLabel.text = myAccount!.name
        
        
        var ratings = self.getAccountRatings(myAccount!.uid!)
        
        //set the applicants number of ratings
        applicantsRatingsLabel.text = "\(ratings.count) Ratings."
        if ratings.count == 1 {
            applicantsRatingsLabel.text = "\(ratings.count) Rating."
        }else if ratings.count == 0 {
            applicantsRatingsLabel.text = "New!"
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
                    selectedLabel.isHidden = false
                }else{
                    selectedLabel.isHidden = true
                }
                
            }catch{
                print("error loading selected users")
            }
        }
        
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
        }else{
            applicantHistoryView.isHidden = true
        }
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(my_id)
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
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: my_id)
                }
              }
        }
        
        
        showFinishIfOk()
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        jobTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "ApplyForJobTagCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ApplyForJobTagCollectionViewCell
        
            let tag = jobTags[indexPath.row]

            cell.tagTitleLabel.text = tag.title
        
        return cell
    }
    
    @IBAction func whenAmountTyped(_ sender: UITextField) {
        hideErrorLabel()
        
        var isnumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: sender.text!))

        if !sender.hasText {
            showError("Set something")
            self.amount = 0
        }else if !isnumber{
            showError("You can't set that")
        }else if sender.text!.contains("-") {
            showError("You can't set that")
            self.amount = 0
        }
        else if Int(sender.text!)! <= 0 {
            showError("You can't set that")
            self.amount = 0
        }
        else{
            self.amount = Int(sender.text!)!
        }
        showFinishIfOk()
    }
    
    func showFinishIfOk(){
        if self.amount != 0 {
            finishButton.isHidden = false
            setAmountButton.isHidden = false
            
            let my_application = self.getAppliedJobIfExists(job_id: job_id)
            
            if my_application == nil {
                //amount will be set when finished
                setAmountButton.isHidden = true
            }
            
        }else{
            
            finishButton.isHidden = true
            if job!.pay_amount != 0{
                finishButton.isHidden = false
            }
            
            setAmountButton.isHidden = true
        }
    }
    
    func showError(_ error: String){
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func hideErrorLabel(){
        errorLabel.isHidden = true
    }
    
    
    
    @IBAction func whenSetTapped(_ sender: Any) {
        let my_application = self.getAppliedJobIfExists(job_id: job_id)
        hideErrorLabel()
        
        if my_application != nil {
            //amount will be set when finished
            if amount == 0 {
                showError("The job owner wants you to set the amount")
                return
            }
            
            var my_id = Auth.auth().currentUser!.uid
            var myAccount = self.getApplicantAccount(user_id: my_id)
            
            showLoadingScreen()
            
            db.collection(constants.jobs_ref)
                .document(job!.country_name!)
                .collection(constants.country_jobs)
                .document(job!.job_id!).collection(constants.applicants)
                .document(my_id).getDocument(){ (document, error) in
                    if let document = document, document.exists {
                        
                        let pay: [String : Any] = [
                            "amount" : self.amount,
                            "currency" : myAccount!.phone!.country_currency!
                        ]
                        
                        self.db.collection(self.constants.jobs_ref)
                            .document(self.job!.country_name!)
                            .collection(self.constants.country_jobs)
                            .document(self.job!.job_id!).collection(self.constants.applicants)
                            .document(my_id).updateData(["application_pay" : pay]){ err in
                                if let err = err {
                                    print("Error writing document: \(err)")
                                } else {
                                    print("Document successfully written!")
                                    
                                    self.hideLoadingScreen()
                                }
                                
                            }
                        
                    } else {
                        print("Document does not exist")
                    }
                }
            
        }
    }
    
    
    
    @IBAction func whenFinishedTapped(_ sender: Any) {
        let my_application = self.getAppliedJobIfExists(job_id: job_id)
        hideErrorLabel()
        
        if my_application == nil {
            //amount will be set when finished
            if job!.pay_amount == 0 {
                //they need to apply with an amount
                if amount == 0 {
                    showError("The job owner wants you to set the amount")
                    return
                }
            }
            
        }
        
        var my_id = Auth.auth().currentUser!.uid
        var myAccount = self.getApplicantAccount(user_id: my_id)
        let t_mills = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        let pay: [String : Any] = [
            "amount" : amount,
            "currency" : myAccount!.phone!.country_currency!
        ]
        
        var data: [String : Any] = [
            "applicant_uid": my_id,
            "job_id" : job_id,
            "job_country" : job!.country_name!,
            "application_time" : t_mills
        ]
        
        if amount != 0 {
            //if ive set a custom application amount
            data["application_pay"] = pay
        }
        
        showLoadingScreen()
        
        if my_application == nil {
        
            db.collection(constants.jobs_ref)
                .document(job!.country_name!)
                .collection(constants.country_jobs)
                .document(job!.job_id!).collection(constants.applicants)
                .document(my_id).setData(data)
            
            db.collection(constants.airworkers_ref).document(my_id)
                .collection(constants.my_applied_jobs)
                .document(job!.job_id!).setData(data){ err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                        
                        self.hideLoadingScreen()
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                }
            
            
            let ref = db.collection(constants.users_ref)
                .document(job!.uploader_id!)
                .collection(constants.notifications)
                .document()
            let upload_time = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
            var message = "\(myAccount!.name!) has applied to do a job for you."
            
            ref.setData([
                "message" : message,
                "time" : upload_time,
                "user_name" : myAccount!.name!,
                "user_id" : job!.uploader_id,
                "job_id" : job!.job_id!,
                "notif_id" : ref.documentID
            ])
        
        }else{
            db.collection(constants.jobs_ref)
                .document(job!.country_name!)
                .collection(constants.country_jobs)
                .document(job!.job_id!).collection(constants.applicants)
                .document(my_id).delete()
            
            db.collection(constants.airworkers_ref).document(my_id)
                .collection(constants.my_applied_jobs)
                .document(job!.job_id!).delete(){ err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully removed!")
                        
                        self.hideLoadingScreen()
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                }
            
            let ref = db.collection(constants.users_ref)
                .document(job!.uploader_id!)
                .collection(constants.notifications)
                .document()
            let upload_time = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
            var message = "\(myAccount!.name!) removed their application for one of you jobs."
            
            ref.setData([
                "message" : message,
                "time" : upload_time,
                "user_name" : myAccount!.name!,
                "user_id" : job!.uploader_id,
                "job_id" : job!.job_id!,
                "notif_id" : ref.documentID
            ])
            
            
            self.context.delete(my_application!)
            NotificationCenter.default.post(name: NSNotification.Name(self.constants.refresh_job), object: "listener")
            
        }
        
        
    }
    
    
    
    func setSuggestion(selected_tags: [String]){
        let prices = constants.getTagPricesForTags(selected_tags: selected_tags, context: self.context)
        
        print("gotten \(prices.count) prices")
        
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        let curr = me?.phone?.country_currency as! String
        
        if !prices.isEmpty {
            var top = Int(constants.getTopAverage(prices))
            var bottom = Int(constants.getBottomAverage(prices))
            
            if (top != 0  && top != bottom) {
                suggestedLabel.text = "Suggested: \(bottom) - \(top) \(curr), for ~2hrs"
            }
        }
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
