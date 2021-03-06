//
//  EditJobViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 29/01/2021.
//

import UIKit
import MultilineTextField
import CoreData
import Firebase

class EditJobViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var detailsField: MultilineTextField!
    @IBOutlet weak var workerNumberField: UITextField!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var imagesCollection: UICollectionView!
    @IBOutlet weak var suggestedAmountLabel: UILabel!
    @IBOutlet weak var leaveForApplicantSwitch: UISwitch!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var pickedImages: [UIImage] = []
    var job_id: String = ""
    var job: Job? = nil
    var job_images = [job_image]()
    var constants = Constants.init()
    var jobTags = [String]()
    let db = Firestore.firestore()
    
    var at_most_2 = "At most 2 hours."
    var two_to_four = "Around 2 to 4 hours."
    var whole_day = "The whole day."
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imagesCollection.delegate = self
        imagesCollection.dataSource = self
        
        setData()
    }
    
    func setData(){
        job = self.getJobIfExists(job_id: job_id)!
        job_images = self.getJobImages(images_json: job!.images!)
        
        titleField.text = job?.job_title!
        detailsField.text = job?.job_details!
        
        
        if job!.job_worker_count != Int64(constants.maxNumber){
            workerNumberField.text = "\(job!.job_worker_count)"
        }
        
        timePicker.minimumDate = Date()
        
        let date = DateComponents(calendar: .current, year: Int(job!.start_year), month: Int(job!.start_month)+1, day: Int(job!.start_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        timePicker.date = date
        
        if job!.pay_amount != Int64(0){
            amountField.text = "\(job!.pay_amount)"
            leaveForApplicantSwitch.isOn = false
        }else{
            leaveForApplicantSwitch.isOn = true
        }
        
        for tag in job!.tags! {
            jobTags.append((tag as! JobTag).title!)
        }
        setSuggestion(selected_tags: jobTags)
        
        for image in job_images{
            let uid = job!.uploader_id!
            let storageRef = Storage.storage().reference()
            let ref = storageRef.child(constants.users_data)
                .child(uid)
                .child(constants.job_images)
                .child("\(image.name).jpg")
            
            ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                  // Uh-oh, an error occurred!
                    print("loading image from cloud failed")
                } else {
                  // Data for "images/island.jpg" is returned
                    let im = UIImage(data: data!)
                    self.pickedImages.append(im!)
                    self.imagesCollection.reloadData()
                }
              }
        }
    }
    
    @IBAction func whenLeaveForApplicantSwitched(_ sender: UISwitch) {
        if sender.isOn{
            amountField.text = ""
            amountField.isEnabled = false
        }else{
            if job!.pay_amount != Int64(0){
                amountField.text = "\(job!.pay_amount)"
                amountField.isEnabled = true
            }
        }
    }
    
    
    @IBAction func whenDone(_ sender: Any) {
        
    }
    @IBAction func whenDoneTapped(_ sender: UIButton) {
        print("starting update job")
        updateJob()
    }
    
    func updateJob(){
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        
        let date = timePicker.date
        var amount = 0
        if !leaveForApplicantSwitch.isOn{
            if !amountField.hasText {
                amount = 0
            }else if Int(amountField.text!) == 0 {
                amount = 0
            }else{
                amount = Int(amountField.text!)!
            }
        }
        print("set date and amount")
        
        var title = ""
        if !titleField.hasText{
            title = job!.job_title!
        } else {
            title = titleField.text!
        }
        
        let details = detailsField.text!
        
        var workers = constants.maxNumber
        if workerNumberField.hasText{
            workers = Int(workerNumberField.text!) ?? 1
        }
        
        print("set details, title and workers")
        
        
        let upload_time = Int64((date.timeIntervalSince1970 * 1000.0).rounded())
        let year: Int = Int(gett("yyyy", date))!
        let month: Int = Int(gett("MM", date))!-1
        let day: Int = Int(gett("dd", date))!
        let hour: Int = Int(gett("hh", date))!
        let min: Int = Int(gett("mm", date))!
        var am_pm: String = gett("a", date)
        var day_of_week: String = gett("EEEE", date)
        var month_of_year: String = gett("MMM", date)
        
        let pay: [String : Any] = [
            "amount" : amount,
            "currency" : me!.phone!.country_currency!,
            "applicant_set" : false
        ]
        
        let time: [String: Any] = [
            "hour" : hour,
            "minute" : min,
            "am_pm" : am_pm
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
                print("failed to upload an image")
                return
              }
              // Metadata contains file metadata such as size, content-type.
              let size = metadata.size
            }
            
            job_list.set_images.append(job_im)
        }
        
        var job_image_list_json = ""
        let encoder = JSONEncoder()
        
        do {
            let json_string = try encoder.encode(job_list)
            job_image_list_json = String(data: json_string, encoding: .utf8)!
        }catch {
           print("error encoding ")
        }
        
        var isJobOk = self.isJobDataOk(title, details, jobTags)
        
        let docData: [String: Any] = [
            "job_title" : title,
            "job_details" : details,
            "job_worker_count" : workers,
            "pay" : pay,
            "time" : time,
            "images" : job_image_list_json,
            "taken_down": isJobOk,
            "auto_taken_down" : isJobOk
        ]
        
        print("writing changes to db")
        self.showLoadingScreen()
        db.collection(constants.jobs)
            .document(job!.country_name!)
            .collection("country_jobs")
            .document(job!.job_id!)
            .updateData(docData){ err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                    self.hideLoadingScreen()
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func isJobDataOk(_ titleText: String, _ details: String, _ selectedTags: [String]) -> Bool{
        let flagged_words = getFlaggedWordsIfExists()
        
        for word in flagged_words {
            if titleText.contains(word!.word!) {
                return false
            }
            
            if details.contains(word!.word!) {
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
    
    @IBAction func onPickImageTapped(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button pick image")
            
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false

            present(imagePicker, animated: true, completion: nil)
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
        pickedImages.append(selectedImage)
        dismiss(animated: true, completion: nil)
        print("appended selected image \(pickedImages.count)")
        imagesCollection.reloadData()
    }

//  MARK: Collection for job images
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pickedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! JobImageCollectionViewCell
        cell.pickedImageView.image = pickedImages[indexPath.row]

        let image = cell.pickedImageView!
        image.layer.borderWidth = 1
        image.layer.masksToBounds = false
        image.layer.borderColor = UIColor.white.cgColor
        image.layer.cornerRadius = image.frame.height/2
        image.clipsToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        
        return 4;
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         // handle tap events
         print("You selected cell \(indexPath.item)!")
        
        pickedImages.remove(at: indexPath.row)
        imagesCollection.reloadData()
     }
    
    func setSuggestion(selected_tags: [String]){
        let prices = getTagPricesForTags(selected_tags: selected_tags)
        
        
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid: uid)
        let curr = me?.phone?.country_currency as! String
        
        if !prices.isEmpty {
            var top = Int(getTopAverage(prices))
            var bottom = Int(getBottomAverage(prices))
            
            if (top != 0  && top != bottom) {
                suggestedAmountLabel.text = "Suggested: \(bottom) - \(top) \(curr)/ ~2hrs"
            }
        }
    }
    
    func getTagPricesForTags(selected_tags: [String]) -> [Double]{
        var tag_with_prices = [Double]()
        
        for selected_tag in selected_tags {
            var global_t = self.getGlobalTagIfExists(tag_title: selected_tag)
            if global_t != nil {
                var associated_tag_prices = getAssociatedTagPrices(global_t!, selected_tags)
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
        
        for associateTag in global_tag.tag_associates?.allObjects as [JobTag]{
            var json = associateTag.tag_associates
            let decoder = JSONDecoder()
            let jsonData = json!.data(using: .utf8)!
            
            do{
                let tags: [json_tag] =  try decoder.decode(json_tag_array.self, from: jsonData).tags
                var shared_tags: [String] = []
                for item in tags{
                    if selected_tags.contains(item.tag_title) {
                        shared_tags.append(item.tag_title)
                    }
                }
                
                if shared_tags.count == selected_tags.count || shared_tags.count >= 2 {
                    //associated tag obj works
                    var price = Double(associateTag.pay_amount)
                    
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
                    
                    prices.append(price)
                }
                
            }catch {
                
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
    
    
    struct json_tag_array: Codable{
        var tags: [json_tag] = []
    }
    
    struct json_tag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
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
