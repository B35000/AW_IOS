//
//  ScanIdViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 18/03/2021.
//

import UIKit
import Firebase
import CoreData

class ScanIdViewController: UIViewController {
    @IBOutlet weak var scanIdFrontContainer: UIView!
    @IBOutlet weak var scanIdBackContainer: UIView!
    @IBOutlet weak var scanPassportPageContainer: UIView!
    
    @IBOutlet weak var image1Container: UIView!
    @IBOutlet weak var image1View: UIImageView!
    @IBOutlet weak var image1StatusView: UIImageView!
    
    @IBOutlet weak var image2Container: UIView!
    @IBOutlet weak var image2View: UIImageView!
    @IBOutlet weak var image2StatusView: UIImageView!
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    
    
    var constants = Constants.init()
    var scanning_id = ""
    var scanned_cards = [[String]]()
    let db = Firestore.firestore()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var isFirstImageAccepted = false
    var isSecondImageAccepted = false
    
    var frontTexts: [String] = [String]()
    var backTexts: [String] = [String]()
    
    var isScanningPassportInstead = false

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        load_scanned_cards()
        image1View.layer.cornerRadius = 15
        image2View.layer.cornerRadius = 15
        
        scanIdBackContainer.isHidden = true
    }
    
    func load_scanned_cards() {
        showLoadingScreen()
        let uid = Auth.auth().currentUser!.uid
        let my_acc = self.getAccount(user_id: uid)
        let my_country = my_acc!.country!
        
        scanned_cards.removeAll()
        
        db.collection(constants.airworkers_ref)
            .whereField("country", isEqualTo: my_country)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let doc_scanning = document.data()["scan_id_data"] as? String
                        if doc_scanning != nil {
                            let back_scanning = self.getScanning(string_json: doc_scanning!)!.back_texts
                            self.scanned_cards.append(back_scanning)
                        }
                    }
                    
                    self.hideLoadingScreen()
                }
            }
    }
    
    func getScanning(string_json: String) -> IdScaning?{
        let decoder = JSONDecoder()
        
        do{
            let jsonData = string_json.data(using: .utf8)!
            let scanning_objs =  try decoder.decode(IdScaning.self, from: jsonData)
            
            return scanning_objs
        }catch{
            print("error loading job images")
        }
        
        return nil
    }
    
    struct IdScaning: Codable{
        var time = 0
        var front_texts: [String] = [String]()
        var back_texts: [String] = [String]()
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch(segue.identifier ?? "") {
            case "addFrontCard":
                guard let takePhotoViewController = segue.destination as? TakePhotoViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                print("scanning for front card")
                scanning_id = constants.addPassportPage
                takePhotoViewController.scanning_id = scanning_id
                takePhotoViewController.scanIdViewController = self
                image1StatusView.image = nil
                
            case "addBackCard":
                guard let takePhotoViewController = segue.destination as? TakePhotoViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                print("scanning for back card")
                scanning_id = constants.addBackCard
                takePhotoViewController.scanning_id = scanning_id
                takePhotoViewController.scanIdViewController = self
                image2StatusView.image = nil
                
            case "addPassportPage":
                guard let takePhotoViewController = segue.destination as? TakePhotoViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                print("scanning for passport")
                scanning_id = constants.addPassportPage
                takePhotoViewController.scanning_id = scanning_id
                takePhotoViewController.scanIdViewController = self
                image1StatusView.image = nil
                
            default:
                print("Unexpected Segue Identifier; \(segue.identifier)")
        }
        
    }
    

    @IBAction func segmentedControlTapped(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                print("tapped 0")
                scanIdFrontContainer.isHidden = false
//                scanIdBackContainer.isHidden = false
                scanPassportPageContainer.isHidden = true
                errorLabel.text = ""
                removeImages()
                isScanningPassportInstead = false
                
            case 1:
                print("tapped 1")
                scanIdFrontContainer.isHidden = true
                scanIdBackContainer.isHidden = true
                scanPassportPageContainer.isHidden = false
                errorLabel.text = ""
                removeImages()
                isScanningPassportInstead = true
                
            default: break;
        }
    }
    
    
    
    @IBAction func whenDoneTapped(_ sender: UIBarButtonItem) {
        showLoadingScreen()
        var uid = Auth.auth().currentUser!.uid
        let t_mills = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        var scanning = IdScaning()
        scanning.time = Int(t_mills)
        
        if !isScanningPassportInstead {
            let card_front_image = image1View.image!
            let card_back_image = image2View.image!
            let card_front_texts = self.frontTexts
            let card_back_text = self.backTexts
            
            scanning.back_texts = backTexts
            scanning.front_texts = frontTexts
            
            let storageRef = Storage.storage().reference()
            let ref = storageRef.child(constants.users_data)
                .child(uid)
                .child("scan_id_front.jpg")
            
            let uploadTask = ref.putData(card_front_image.resized(toWidth: 600.0)!.pngData()!, metadata: nil) { (metadata, error) in
              guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
              }
              // Metadata contains file metadata such as size, content-type.
              let size = metadata.size
            }
            
            let ref2 = storageRef.child(constants.users_data)
                .child(uid)
                .child("scan_id_back.jpg")
            
            let uploadTask2 = ref2.putData(card_back_image.resized(toWidth: 600.0)!.pngData()!, metadata: nil) { (metadata, error) in
              guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
              }
              // Metadata contains file metadata such as size, content-type.
              let size = metadata.size
            }
            
        }else{
            let card_front_image = image1View.image!
            let card_front_texts = self.frontTexts
            
            scanning.front_texts = frontTexts
            
            let storageRef = Storage.storage().reference()
            let ref = storageRef.child(constants.users_data)
                .child(uid)
                .child("scan_id_front.jpg")
            
            let uploadTask = ref.putData(card_front_image.resized(toWidth: 600.0)!.pngData()!, metadata: nil) { (metadata, error) in
              guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
              }
              // Metadata contains file metadata such as size, content-type.
              let size = metadata.size
            }
        }
        
        
        var scanning_data_json = ""
        let encoder = JSONEncoder()
        
        do {
            let json_string = try encoder.encode(scanning)
            scanning_data_json = String(data: json_string, encoding: .utf8)!
        }catch {
           
        }
        
        
        db.collection(constants.airworkers_ref).document(uid)
            .updateData(["scan_id_data" : scanning_data_json]){ err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                    self.hideLoadingScreen()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        
        db.collection(constants.users_ref).document(uid)
            .updateData(["scan_id_data" : scanning_data_json])
    }
    
    
    func removeImages(){
        image1View.image = nil
        image2View.image = nil
        
        image1StatusView.image = nil
        image2StatusView.image = nil
        
        self.isFirstImageAccepted = false
        self.isSecondImageAccepted = false
        
        self.showFinishButtonIfBothImgaccepted()
    }
    
    
    func whenScanningDone(image: UIImage, accepted: Bool, message: String) {
        
        if scanning_id == constants.addFrontCard {
            image1View.image = image
            if accepted {
                image1StatusView.image = UIImage(named: "ScanningAccepted")
                self.isFirstImageAccepted = true
                errorLabel.text = ""
                
                scanIdBackContainer.isHidden = false
                
            }else{
                image1StatusView.image = UIImage(named: "ScanningRejected")
                self.isFirstImageAccepted = false
                errorLabel.text = message
            }
        }else if scanning_id == constants.addBackCard {
            image2View.image = image
            if accepted {
                image2StatusView.image = UIImage(named: "ScanningAccepted")
                self.isSecondImageAccepted = true
                errorLabel.text = ""
            }else{
                image2StatusView.image = UIImage(named: "ScanningRejected")
                self.isSecondImageAccepted = false
                errorLabel.text = message
            }
        }else if scanning_id == constants.addPassportPage {
            image1View.image = image
            if accepted {
                image1StatusView.image = UIImage(named: "ScanningAccepted")
                self.isFirstImageAccepted = true
                errorLabel.text = ""
            }else{
                image1StatusView.image = UIImage(named: "ScanningRejected")
                self.isFirstImageAccepted = false
                errorLabel.text = message
            }
        }
        
        self.showFinishButtonIfBothImgaccepted()
    }
    
    func showFinishButtonIfBothImgaccepted(){
        if (isFirstImageAccepted && isSecondImageAccepted) || (isFirstImageAccepted && isScanningPassportInstead) {
            self.doneBarButton.isEnabled = true
        }else{
            self.doneBarButton.isEnabled = false
        }
    }
    
    func check_if_scanning_is_new_id(image: UIImage, accepted: Bool, my_scanned_words: [String]){
        var found_matching_card = false
        for user_scanning in scanned_cards {
            let users_last_3_scanned_words =
                Array(user_scanning[user_scanning.index(user_scanning.endIndex, offsetBy: -4) ..< user_scanning.endIndex])
            
            let my_last_3_scanned_words =
                Array(my_scanned_words[my_scanned_words.index(my_scanned_words.endIndex, offsetBy: -4) ..< my_scanned_words.endIndex])
            
            for user_scan_line in users_last_3_scanned_words {
                if user_scan_line.count > 5 {
                    for item in my_last_3_scanned_words {
                        if(self.remove_unwanted_scanned_chars(text: user_scan_line).contains( self.remove_unwanted_scanned_chars(text: item))
                        ){
                            print("---\(self.remove_unwanted_scanned_chars(text: user_scan_line)) matchees: \(self.remove_unwanted_scanned_chars(text: item))---")
                            whenScanningDone(image: image, accepted: false, message: "A similar card already in use")
                            found_matching_card = true
                        }else{
//                            print("\(self.remove_unwanted_scanned_chars(text: user_scan_line)) doesnt match: \(self.remove_unwanted_scanned_chars(text: item))")
                        }
                    }
                }
            }
//            if(
//                self.remove_unwanted_scanned_chars(text: users_last_3_scanned_words[0]).contains(self.remove_unwanted_scanned_chars(text: my_last_3_scanned_words[0])) &&
//                self.remove_unwanted_scanned_chars(text: users_last_3_scanned_words[1]).contains(self.remove_unwanted_scanned_chars(text: my_last_3_scanned_words[1])) &&
//                self.remove_unwanted_scanned_chars(text: users_last_3_scanned_words[2]).contains(self.remove_unwanted_scanned_chars(text: my_last_3_scanned_words[2]))
//            ){
//                print("found a matching card")
//                whenScanningDone(image: image, accepted: false)
//                found_matching_card = true
//            }else{
//                print("\(my_last_3_scanned_words) doesnt match: \(users_last_3_scanned_words)")
//            }
        }
        
        if !found_matching_card {
            whenScanningDone(image: image, accepted: true, message: "")
        }
        
        if (scanning_id == constants.addFrontCard || scanning_id == constants.addPassportPage) {
            self.frontTexts.removeAll()
            self.frontTexts.append(contentsOf: my_scanned_words)
        }else{
            self.backTexts.removeAll()
            self.backTexts.append(contentsOf: my_scanned_words)
        }
    }
    
    func remove_unwanted_scanned_chars(text: String) -> String{
        let uid = Auth.auth().currentUser!.uid
        let my_acc = self.getAccount(user_id: uid)
        let my_country = my_acc!.country!
        
        if my_country == "Kenya" {
            var new_text = text.replacingOccurrences(of: " ", with: "")
            var new2 = new_text.replacingOccurrences(of: "<", with: "")
            var new3 = new2.replacingOccurrences(of: "O", with: "0")
            
//            print("trimmed texts: \(new_text)")
            
            return new3
        }
        
        return text
    }
    
    
    func getAccount(user_id: String) -> Account? {
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
