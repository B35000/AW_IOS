//
//  NewSkillViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 23/03/2021.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import MultilineTextField
import Firebase
import CoreData
import PDFKit

class NewSkillViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate, UIDocumentMenuDelegate, UITextFieldDelegate{
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextField: MultilineTextField!
    @IBOutlet weak var pickedImagesCollectionView: UICollectionView!
    @IBOutlet weak var continueButton: UIBarButtonItem!
    @IBOutlet weak var ErrorLabel: UILabel!
    @IBOutlet weak var attachPdfLabel: UILabel!
    @IBOutlet weak var pdfContainer: UIView!
    var pdfView = PDFView()
    @IBOutlet weak var removeDocButton: UIButton!
    
    var titleText = ""
    var skill_images: [UIImage : String] = [UIImage : String]()
    var pickedImages = [UIImage]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let db = Firestore.firestore()
    let constants = Constants.init()
    let doc_max_size = (6 * (1024 * 1024))
    
    var edit_skill_id = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pickedImagesCollectionView.delegate = self
        pickedImagesCollectionView.dataSource = self
        
        if edit_skill_id != "" {
            //were editing a skill
            loadEditedSkill()
            loadDocIfExists()
        }
        
        titleTextField.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                view.addGestureRecognizer(tap)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder() // dismiss keyboard
            return true
    }
    
    @objc func handleTap() {
        titleTextField.resignFirstResponder() // dismiss keyoard
        detailsTextField.resignFirstResponder()
    }
    
    
    func loadEditedSkill(){
        let skill = self.getSkillIfExists(self.edit_skill_id)!
        titleTextField.text = skill.title!
        detailsTextField.text = skill.details!
        
        self.title = "Edit Skill"
        self.titleText = skill.title!
        
        //load any images if exist
        var json = skill.images!
        let decoder = JSONDecoder()
        let jsonData = json.data(using: .utf8)!
        print("images : \(json)")
        do{
            let des_images =  try decoder.decode(qual_image_list.self, from: jsonData).set_images
            
            for image in des_images {
                let user_id = Auth.auth().currentUser!.uid
                let storageRef = Storage.storage().reference()
                
                let ref = storageRef.child(constants.users_data)
                    .child(user_id)
                    .child(constants.qualification_images)
                    .child("\(image.name).jpg")
                
                if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
                    let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
                    let im = UIImage(data: resource.data!)
                    self.skill_images[im!] = image.name
                    self.pickedImages.append(im!)
                    self.pickedImagesCollectionView.reloadData()
                }else{
                    ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
                        if let error = error {
                          // Uh-oh, an error occurred!
                            print("loading image from cloud failed")
                        } else {
                          // Data for "images/island.jpg" is returned
                            let im = UIImage(data: data!)
                            self.skill_images[im!] = image.name
                            self.pickedImages.append(im!)
                            self.pickedImagesCollectionView.reloadData()
                            
                            self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: user_id)
                        }
                      }
                }
            }
            
        }catch {
            print("decoder failed")
        }
    }
    
    func loadDocIfExists(){
        let user_id = Auth.auth().currentUser!.uid
        let storageRef = Storage.storage().reference()
        
        let ref = storageRef.child(constants.users_data)
            .child(user_id)
            .child(constants.qualification_document)
            .child("\(edit_skill_id).pdf")
        
        if constants.getResourceIfExists(data_id: ref.fullPath, context: context) != nil {
            let resource = constants.getResourceIfExists(data_id: ref.fullPath, context: context)!
            self.picked_doc = resource.data!
            self.setDocOnView()
        }else{
            ref.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                  // Uh-oh, an error occurred!
                    print("loading image from cloud failed")
                } else {
                  // Data for "images/island.jpg" is returned
                    self.picked_doc = data
                    self.setDocOnView()
                    
                    self.constants.storeResource(data_id: ref.fullPath, context: self.context, data: data!, author_id: user_id)
                }
              }
        }

    }
    
    func setDocOnView(){
        attachPdfLabel.text = "Attached Document Exists"
        attachPdfLabel.textColor = .label
        removeDocButton.isHidden = true
        
        let uid = Auth.auth().currentUser!.uid
        
         do {
            pdfView = PDFView()

            pdfView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pdfView)

            pdfView.leadingAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.leadingAnchor).isActive = true
            pdfView.trailingAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.trailingAnchor).isActive = true
            pdfView.topAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.topAnchor).isActive = true
            pdfView.bottomAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.bottomAnchor).isActive = true
            
            let d = PDFDocument(data: picked_doc!)
            pdfView.document = d
            
            removeDocButton.isHidden = false
            
         } catch {
             print("\(error.localizedDescription)")
         }
        
        
    }
    
    @IBAction func whenDeleteDocTapped(_ sender: Any) {
        pdfView.document = nil
        removeDocButton.isHidden = true
        picked_doc = nil
        
        let user_id = Auth.auth().currentUser!.uid
        let storageRef = Storage.storage().reference()
        
        let ref = storageRef.child(constants.users_data)
            .child(user_id)
            .child(constants.qualification_document)
            .child("\(edit_skill_id).pdf")
        
        ref.delete { (error) in
            if error != nil {
                print(error.debugDescription)
                self.constants.removeResource(data_id: ref.fullPath, context: self.context)
            }
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        

    }
    
    
    @IBAction func whenAttachFileTapped(_ sender: Any) {
        let types = UTType.types(tag: "pdf",tagClass: UTTagClass.filenameExtension,
                                     conformingTo: nil)
            let documentPickerController = UIDocumentPickerViewController(
                    forOpeningContentTypes: types)
            documentPickerController.delegate = self
            self.present(documentPickerController, animated: true, completion: nil)
        
    }
    
    var picked_doc: Data? = nil
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        if controller.allowsMultipleSelection {
            print("WARNING: controller allows multiple file selection, but coordinate-read code here assumes only one file chosen")
            // If this is intentional, you need to modify the code below to do coordinator.coordinate
            // on MULTIPLE items, not just the first one
            if urls.count > 0 { print("Ignoring all but the first chosen file") }
        }
        
        let firstFileURL = urls[0]
        let isSecuredURL = (firstFileURL.startAccessingSecurityScopedResource() == true)
        
        print("UIDocumentPickerViewController gave url = \(firstFileURL)")

        // Status monitoring for the coordinate block's outcome
        var blockSuccess = false
        var outputFileURL: URL? = nil

        // Execute (synchronously, inline) a block of code that will copy the chosen file
        // using iOS-coordinated read to cooperate on access to a file we do not own:
        let coordinator = NSFileCoordinator()
        var error: NSError? = nil
        coordinator.coordinate(readingItemAt: firstFileURL, options: [], error: &error) { (externalFileURL) -> Void in
                
            // WARNING: use 'externalFileURL in this block, NOT 'firstFileURL' even though they are usually the same.
            // They can be different depending on coordinator .options [] specified!
        
            // Create file URL to temp copy of file we will create:
            var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            tempURL.appendPathComponent(externalFileURL.lastPathComponent)
            print("Will attempt to copy file to tempURL = \(tempURL)")
            
            // Attempt copy
            do {
                // If file with same name exists remove it (replace file with new one)
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    print("Deleting existing file at: \(tempURL.path) ")
                    try FileManager.default.removeItem(atPath: tempURL.path)
                }
                
                // Move file from app_id-Inbox to tmp/filename
                print("Attempting move file to: \(tempURL.path) ")
                try FileManager.default.copyItem(atPath: externalFileURL.path, toPath: tempURL.path)
//                try FileManager.default.moveItem(atPath: externalFileURL.path, toPath: tempURL.path)
                
                blockSuccess = true
                outputFileURL = tempURL
            }
            catch {
                print("File operation error: " + error.localizedDescription)
                blockSuccess = false
            }
            
        }
        navigationController?.dismiss(animated: true, completion: nil)
        
        if error != nil {
            print("NSFileCoordinator() generated error while preparing, and block was never executed")
            return
        }
        if !blockSuccess {
            print("Block executed but an error was encountered while performing file operations")
            return
        }
        
        print("Output URL : \(String(describing: outputFileURL))")
        
        if (isSecuredURL) {
            firstFileURL.stopAccessingSecurityScopedResource()
        }
        
        if let out = outputFileURL {
            print("import result : \(out)")
            do {
                let resources = try out.resourceValues(forKeys:[.fileSizeKey])
                let fileSize = resources.fileSize!
                let path = String(describing: out.path)
                
                
                if fileSize < Int64(doc_max_size){
                    attachPdfLabel.text = "Document Attached!"
                    picked_doc = try Data(contentsOf: out)
                    attachPdfLabel.textColor = .label
                    removeDocButton.isHidden = true
                    
                    let uid = Auth.auth().currentUser!.uid
                    
                     do {
                        pdfView = PDFView()

                        pdfView.translatesAutoresizingMaskIntoConstraints = false
                        view.addSubview(pdfView)

                        pdfView.leadingAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.leadingAnchor).isActive = true
                        pdfView.trailingAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.trailingAnchor).isActive = true
                        pdfView.topAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.topAnchor).isActive = true
                        pdfView.bottomAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.bottomAnchor).isActive = true
                        

                        
                        let d = PDFDocument(data: picked_doc!)
                        pdfView.document = d
                        removeDocButton.isHidden = false
                     } catch {
                         print("\(error.localizedDescription)")
                     }
                    
                }else{
                    attachPdfLabel.text = "The file size limit is 3.5Mb."
                    attachPdfLabel.textColor = .systemRed
                }
    
            } catch {
                print("something went wrong: \(error.localizedDescription)")
            }
            
        }
        
    }
    
    func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    
    public func documentMenu(_ documentMenu:UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }


    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    @IBAction func whenPickImageTapped(_ sender: Any) {
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
        pickedImagesCollectionView.reloadData()
    }
    
    
    
    
    @IBAction func whenTitleFieldEdited(_ sender: UITextField) {
        hideErrorLabel()
        if !sender.hasText{
            continueButton.isEnabled = false
            showError("You need to set a title.")
            self.titleText = ""
        } else if sender.text!.count > 35 {
            continueButton.isEnabled = false
            showError("That title is too long!")
            self.titleText = ""
        } else if checkIfSimilarSkillExists(title: sender.text!) {
            continueButton.isEnabled = false
            showError("You cant reuse that title")
            self.titleText = ""
        }
        else {
            continueButton.isEnabled = true
            self.titleText = sender.text!
        }
    }
    
    func checkIfSimilarSkillExists(title: String) -> Bool{
        let uid = Auth.auth().currentUser!.uid
        let my_skills = self.getJobApplicantSkillsIfExists(applicant_id: uid)
        var their_titles: [String] = [String]()
        
        for skill in my_skills {
            their_titles.append(skill.title!)
        }
        
        if their_titles.contains(title){
            return true
        }
        
        return false
    }
    
    
    func showError(_ error: String){
        ErrorLabel.isHidden = false
        ErrorLabel.text = error
    }
    
    func hideErrorLabel(){
        ErrorLabel.isHidden = true
    }
    
    
    @IBAction func whenDoneTapped(_ sender: UIBarButtonItem) {
        uploadNewQualification()
    }
    
    func uploadNewQualification(){
        showLoadingScreen()
        let uid = Auth.auth().currentUser!.uid
        let me = self.getAccountIfExists(uid)
        let upload_time = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        var newQualRef = db.collection(constants.airworkers_ref)
            .document(uid)
            .collection(constants.qualifications)
            .document()
        
        if edit_skill_id != "" {
            newQualRef = db.collection(constants.airworkers_ref)
                .document(uid)
                .collection(constants.qualifications)
                .document(edit_skill_id)
        }
        
        var qual_images = qual_image_list()
        for image in pickedImages {
            var qual_im = qual_image()
            qual_im.name = constants.randomString(16)
            
            if skill_images[image] != nil {
                //its not a new image
                qual_im.name = skill_images[image]!
            }
            
            let storageRef = Storage.storage().reference()
            let img_ref = storageRef.child(constants.users_data)
                .child(uid)
                .child(constants.qualification_images)
                .child("\(qual_im.name).jpg")
            
            let im_data = image.resized(toWidth: 600.0)!.jpegData(compressionQuality: 100)
            
            let uploadTask = img_ref.putData(im_data!, metadata: nil) { (metadata, error) in
              guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
              }
                // Metadata contains file metadata such as size, content-type.
                let size = metadata.size
                print("written image in db")
                self.constants.storeResource(data_id: img_ref.fullPath, context: self.context, data: im_data!, author_id: uid)
            }
            
            qual_images.set_images.append(qual_im)
        }
        
        var job_image_list_json = ""
        let encoder = JSONEncoder()
        
        do {
            let json_string = try encoder.encode(qual_images)
            job_image_list_json = String(data: json_string, encoding: .utf8)!
        
            let docData: [String: Any] = [
                "title" : titleText,
                "qualification_id" : newQualRef.documentID,
                "user_id" : uid,
                "images" : job_image_list_json,
                "last_update" : upload_time,
                "details" : detailsTextField.text
            ]
            
            
            if picked_doc != nil {
                let storageRef = Storage.storage().reference()
                let ref = storageRef.child(constants.users_data)
                    .child(uid)
                    .child(constants.qualification_document)
                    .child("\(newQualRef.documentID).pdf")
                
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
            
            
            newQualRef.setData(docData){ err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                    
                    self.hideLoadingScreen()
                }
            }
            
        }catch {
           
        }
        
    }
    
    struct qual_image_list: Codable {
        var set_images = [qual_image]()
    }
    
    struct qual_image: Codable{
        var name = ""
        var is_new_item = false
    }
    
    
//  MARK: Collection for job images
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pickedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkillImageCell", for: indexPath) as! AddSkillImageCollectionViewCell
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
        
        if skill_images[pickedImages[indexPath.row]] != nil {
            self.deleteImage(image_name: skill_images[pickedImages[indexPath.row]]!)
            skill_images.remove(at: skill_images.index(forKey: pickedImages[indexPath.row])!)
        }
        pickedImages.remove(at: indexPath.row)
        pickedImagesCollectionView.reloadData()
        
        
     }
    
    func deleteImage(image_name: String){
        let uid = Auth.auth().currentUser!.uid
        let storageRef = Storage.storage().reference()
        let ref = storageRef.child(constants.users_data)
            .child(uid)
            .child(constants.qualification_images)
            .child("\(image_name).jpg")
        
        let uploadTask = ref.delete { (error) in
            if error != nil {
                print(error.debugDescription)
            }
            self.constants.removeResource(data_id: ref.fullPath, context: self.context)
        }
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
    
    func getSkillIfExists(_ qualification_id: String) -> Qualification? {
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
    
    func getAccountIfExists(_ user_id: String) -> Account? {
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
