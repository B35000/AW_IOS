//
//  SettingsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import Firebase
import SafariServices
import CoreData

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var ratingsLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var verifyEmailView: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    
    let db = Firestore.firestore()
    var constants = Constants.init()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if(isEmailVerified()){
            if(verifyEmailView != nil){
                verifyEmailView.isHidden = true
            }
        }
        
        setDataInViews()
        
    }
    
    func isEmailVerified() -> Bool{
        let me = Auth.auth().currentUser!
        me.reload { (e: Error?) in
            
        }
        
        return me.isEmailVerified
        
    }
    
    func setDataInViews(){
        let me = Auth.auth().currentUser!.uid
        print("my uid ------------ \(me)")
        
        let myAcc = getAccountIfExists(uid: me)!
        let myRatings = getAccountRatings(me)
        
        print("my email --------- \(myAcc.email)")
        
        nameLabel.text = myAcc.name!
        emailLabel.text = myAcc.email
        phoneLabel.text = "\(myAcc.phone!.country_number_code!) \(myAcc.phone!.digit_number)"
        
        
        if myRatings.isEmpty {
            ratingsLabel.text = "New!"
        }else{
            var total = 0.0
            for item in myRatings {
                total += Double(item.rating)
            }
            ratingsLabel.text = "\(round(10 * total/Double(myRatings.count))/10)"
        }
        
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(me)
            .child("avatar.jpg")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            let im = UIImage(data: resource.data!)
            self.profileImageView.image = im
            
            let image = self.profileImageView!
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
                    self.profileImageView.image = im
                    
                    let image = self.profileImageView!
                    image.layer.borderWidth = 1
                    image.layer.masksToBounds = false
                    image.layer.borderColor = UIColor.white.cgColor
                    image.layer.cornerRadius = image.frame.height/2
                    image.clipsToBounds = true
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: me)
                }
              }
        }
        
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        //viewAccountSkills
        let me = Auth.auth().currentUser!.uid
        let myAcc = getApplicantAccount(me)!
        
        switch(segue.identifier ?? "") {
            
        case "viewAccountSkills":
            guard let skillsViewController = segue.destination as? SkillsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            skillsViewController.applicant_id = me
            skillsViewController.title = myAcc.name

            
        default:
            print("Unexpected Segue Identifier; \(segue.identifier)")
            
        }
    }
    

    @IBAction func onBack(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func viewPrivacyTapped(_ sender: Any) {
        print("open eula registered!")
        
        if let url = URL(string: "https://storage.googleapis.com/airwork/Airwork-Eula/privacy.html") {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
    }
    
    @IBAction func userAgreementTapped(_ sender: Any) {
        print("open eula registered!")
        
        if let url = URL(string: "https://storage.googleapis.com/airwork/Airwork-Eula/index.html") {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
    }
    
    @IBAction func changePhotoTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button pick image")
            
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false

            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func onPickImageTapped(_ sender: Any) {
       
    }
    
    
    @IBAction func onSignOutTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "Sign Out?", message: "Are you sure you wish to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes.", style: .default, handler: { action in
            switch action.style{
                case .default:
                print("default")
                    self.sign_out()
                
                case .cancel:
                print("cancel")
                
                case .destructive:
                print("destructive")
                
            }
        }))
        self.present(alert, animated: true, completion: nil)
        
   
    }
    
    func sign_out(){
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
        
        let PaymentRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "JobPayment")
        let PaymentDeleteRequest = NSBatchDeleteRequest( fetchRequest: PaymentRequest)
        
        let ApplicationsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AppliedJob")
        let ApplicationsDeleteRequest = NSBatchDeleteRequest( fetchRequest: ApplicationsRequest)
        
        let UploadedJobsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UploadedJob")
        let UploadedJobsDeleteRequest = NSBatchDeleteRequest( fetchRequest: UploadedJobsRequest)
        
        
        let GlobalTagRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GlobalTag")
        let GlobalTagDeleteRequest = NSBatchDeleteRequest( fetchRequest: GlobalTagRequest)
        
        
        let JobTagRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "JobTag")
        let JobTagDeleteRequest = NSBatchDeleteRequest( fetchRequest: JobTagRequest)
        
        let JobRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Job")
        let JobDeleteRequest = NSBatchDeleteRequest( fetchRequest: JobRequest)
            
        do{
            try context.execute(contactDeleteRequest)
            try context.execute(NotificationDeleteRequest)
            try context.execute(ComplaintDeleteRequest)
            try context.execute(RatingDeleteRequest)
            try context.execute(AccountDeleteRequest)
            
            try context.execute(PaymentDeleteRequest)
            try context.execute(ApplicationsDeleteRequest)
            try context.execute(UploadedJobsDeleteRequest)
            try context.execute(GlobalTagDeleteRequest)
            try context.execute(JobTagDeleteRequest)
            try context.execute(JobDeleteRequest)
            
            try Auth.auth().signOut()
            
            let id = "SignUpNavigationController"
        
            let SignUpIntroViewController = self.storyboard?.instantiateViewController(identifier: id) as? SignUpNavigationController
            self.view.window?.rootViewController = SignUpIntroViewController
            self.view.window?.makeKeyAndVisible()
            
        }catch let error as NSError {
            print("error clearing data for sign out \(error.localizedDescription)")
        }
    }
    
    
//  MARK: Pick image for job
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        else{
            fatalError("Expected dicitonary conataining image but got this \(info)")
            
        }
        profileImageView.image = selectedImage
        dismiss(animated: true, completion: nil)
        
        let storageRef = Storage.storage().reference()
        let me = Auth.auth().currentUser!.uid
        let ref = storageRef.child(constants.users_data)
            .child(me)
            .child(constants.job_images)
            .child("avatar.jpg")
        
        let im_data = selectedImage.resized(toWidth: 600.0)!.pngData()
        
        let uploadTask = ref.putData(im_data!, metadata: nil) { (metadata, error) in
          guard let metadata = metadata else {
            // Uh-oh, an error occurred!
            return
          }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
            self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: im_data!, author_id: me)
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
    
    func getApplicantAccount(_ user_id: String) -> Account? {
        do{
            let request = Account.fetchRequest() as NSFetchRequest<Account>
            
            let predic = NSPredicate(format: "uid == %@", user_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                for item in items {
                    print("loaded account using \(user_id):--- \(item.email)")
                }
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
                do{
                    try context.save()
                }catch{
                    
                }
                return new_app_data
            }
            
        }catch {
            
        }
        
        return nil
    }
    
}
