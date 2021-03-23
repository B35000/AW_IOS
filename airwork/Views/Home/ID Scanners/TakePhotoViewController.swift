//
//  TakePhotoViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 17/03/2021.
//

import UIKit
import AVFoundation
import MLKit
import CoreData
import Firebase

class TakePhotoViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureImageView: UIImageView!
    
    var session: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var captureIndicator: UIImageView!
    var isHidden = false
    var timer: Timer? = nil
    var is_timer_on = false
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let db = Firestore.firestore()
    var constants = Constants.init()
    var scanning_id = ""
    var scanIdViewController: ScanIdViewController? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        session = AVCaptureSession()
        session!.sessionPreset = .medium
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera!)
        } catch let error1 as NSError {
          error = error1
          input = nil
          print(error!.localizedDescription)
        }
        
        stillImageOutput = AVCapturePhotoOutput()
        
        if (error == nil && session!.canAddInput(input) && session!.canAddOutput(stillImageOutput!)){
          session!.addInput(input)
            session!.addOutput(stillImageOutput!)
            setupLivePreview()
            
        }
        
        
    }
    
    func startCamera(){
        DispatchQueue.global(qos: .userInitiated).async {
            self.session!.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer!.frame = self.previewView.bounds
            }
        }
    }
    
    func start_timer(){
        is_timer_on = true
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { (timer) in
            self.showAndHideFilterMenu()
        }
    }
    
    func stop_timer(){
        if(is_timer_on){
            is_timer_on = false
            timer?.invalidate()
        }
    }
    
    func stopCamera() {
        if isBeingDismissed {
            self.session?.stopRunning()
            stop_timer()
        }
        
    }
    
    func showAndHideFilterMenu() {
        if self.isHidden == false {
            self.captureIndicator.alpha = 0.0
            self.captureIndicator.isHidden = false
            self.isHidden = true

            UIView.animate(withDuration: 0.6,
                           animations: { [weak self] in
                            self?.captureIndicator.alpha = 1.0
            })
        } else {
            UIView.animate(withDuration: 0.6,
                           animations: { [weak self] in
                            self?.captureIndicator.alpha = 0.0
            }) { [weak self] _ in
                self?.captureIndicator.isHidden = true
                self?.isHidden = false
            }
        }
    }
    
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
        videoPreviewLayer!.videoGravity = .resizeAspect
        videoPreviewLayer!.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(videoPreviewLayer!)
        
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
        if isBeingPresented {
            startCamera()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func didTakePhoto(_ sender: UIButton) {
        start_timer()
        if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            stillImageOutput?.capturePhoto(with: settings, delegate: self)
            
        }
        
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        
        let image = UIImage(data: imageData)
        captureImageView.image = image
        
        scanImageForText(img: image!)
    }
    
    
    func scanImageForText(img: UIImage){
        let image = VisionImage(image: img)
        image.orientation = img.imageOrientation
        let textRecognizer = TextRecognizer.textRecognizer()
        
        textRecognizer.process(image) { result, error in
            guard error == nil, let result = result else {
            // Error handling
                return
            }
            self.stop_timer()
            let resultText = self.get_texts_from_scanning(result)
            if(self.is_scanning_good(text_list: resultText)){
                //we can return the image
                self.scanIdViewController?.check_if_scanning_is_new_id(image: img, accepted: true, my_scanned_words: resultText)
                self.dismiss(animated: true, completion: nil)
                
            }else{
                self.scanIdViewController?.whenScanningDone(image: img, accepted: false)
            }
            
            
        }
    }
    
    
    func get_texts_from_scanning(_ result: Text) -> [String]{
        var text_list = [String]()
        for block in result.blocks {
            for line in block.lines {
                for element in line.elements {
                    let elementText = element.text
                    text_list.append(elementText)
                }
            }
        }
        
        return text_list
    }
    
    func is_scanning_good(text_list: [String]) -> Bool{
        let uid = Auth.auth().currentUser!.uid
        let my_acc = self.getAccount(user_id: uid)
        let my_country = my_acc!.country!
        
        
        
        if(does_extracted_text_contain_required_text(text_list, getValidatorText())){
            return true
        }
        
        return false
    }
    
    func getValidatorText() -> [String] {
        var validator_list = [String]()
        
        if scanning_id == constants.addFrontCard {
            validator_list.append("JAMHURI YA KENYA")
            return validator_list
        }else if scanning_id == constants.addBackCard {
            validator_list.append("PRINCIPAL REGISTRAR'S SIGN")
            return validator_list
        }else if scanning_id == constants.addPassportPage {
            validator_list.append("JAMHURI YA KENYA")
            validator_list.append("PASSPORT")
            
            return validator_list
        }
        
        validator_list.append("DATE OF BIRTH")
        
        return validator_list
        
    }
    
    func remove_unwanted_scanned_chars(text: String) -> String{
        let uid = Auth.auth().currentUser!.uid
        let my_acc = self.getAccount(user_id: uid)
        let my_country = my_acc!.country!
        
        if my_country == "Kenya" {
            var new_text = text.replacingOccurrences(of: " ", with: "")
            new_text.replacingOccurrences(of: "<", with: "")
            new_text.replacingOccurrences(of: "O", with: "0")
            
            return new_text
        }
        
        return text
    }
    
    func does_extracted_text_contain_required_text(_ ripped_text: [String], _ validator_text: [String]) -> Bool {
        for v_text in validator_text {
            for text in ripped_text {
                if text.contains(v_text) {
                    return true
                }
            }
        }
        
        return false
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
    
    
}
