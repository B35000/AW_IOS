//
//  NewJobTitleViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import MultilineTextField
import PDFKit
import UniformTypeIdentifiers
import Firebase
import CoreData

let reuseIdentifier = "ImageCell";

class NewJobTitleViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIDocumentPickerDelegate, UIDocumentMenuDelegate {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextField: MultilineTextField!
    @IBOutlet weak var pickedImagesCollectionView: UICollectionView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var ErrorLabel: UILabel!
    @IBOutlet weak var attachPdfLabel: UILabel!
    @IBOutlet weak var pdfContainer: UIView!
    var pdfView = PDFView()
    @IBOutlet weak var removeDocButton: UIButton!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var titleText = ""
    var pickedImages: [UIImage] = []
    var pickedUsers: [String] = []
    let doc_max_size = (6 * (1024 * 1024))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
//        detailsTextView.textColor = UIColor.lightGray
//        detailsTextView.placeholderColor = UIColor.lightGray
                
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func onPickImageTapped(_ sender: Any) {
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
    
    @IBAction func whenTitleFieldChanged(_ sender: UITextField) {
        hideErrorLabel()
        
        if !sender.hasText{
            continueButton.isHidden = true
            showError("You need to set a title.")
            self.titleText = ""
        } else if sender.text!.count > 35 {
            continueButton.isHidden = true
            showError("That title is too long!")
            self.titleText = ""
        } else {
            continueButton.isHidden = false
            self.titleText = sender.text!
        }
    }
    
    
    func showError(_ error: String){
        ErrorLabel.isHidden = false
        ErrorLabel.text = error
    }
    
    func hideErrorLabel(){
        ErrorLabel.isHidden = true
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
        pickedImagesCollectionView.reloadData()
     }
    
    @IBAction func whenAttachDocTapped(_ sender: UIButton) {
        print("add tapped")
        pickDoc()
    }
    
    
    @IBAction func whenAddTapped(_ sender: Any) {
        
    }
    
    
    @IBAction func whenRemoveTapped(_ sender: Any) {
        pdfView.document = nil
        removeDocButton.isHidden = true
        picked_doc = nil
    }
    
    
    func pickDoc(){
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
//        navigationController?.dismiss(animated: true, completion: nil)
        
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
    
    
}
