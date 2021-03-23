//
//  VerifyEmailViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 10/02/2021.
//

import UIKit
import Firebase

class VerifyEmailViewController: UIViewController {
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    
    var gameTimer: Timer?
    let db = Firestore.firestore()
    var constants = Constants.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let me = Auth.auth().currentUser!
        self.emailLabel.text = "\(me.email!)"
        
        gameTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
        resendButton.sendActions(for: .touchUpInside)
    }
    
    @objc func runTimedCode(){
        let me = Auth.auth().currentUser!
        if(isEmailVerified()){
            self.emailLabel.text = "\(me.email!) verified!"
            showLoadingScreen()
            
            
            //set data in db then go back
            var email_verification_obj_json = ""
            let me = Auth.auth().currentUser!
            let upload_time = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
            
            var email_vo = email_verification_obj()
            email_vo.time = Int(upload_time)
            email_vo.email = me.email!
            
            let encoder = JSONEncoder()
            
            do {
                let json_string = try encoder.encode(email_vo)
                email_verification_obj_json = String(data: json_string, encoding: .utf8)!
                
                db.collection(constants.users_ref)
                    .document(me.uid).updateData(["email_verification_obj" : email_verification_obj_json])
                
                db.collection(constants.airworkers_ref)
                    .document(me.uid)
                    .updateData(["email_verification_obj" : email_verification_obj_json]){ err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                            let i = self.navigationController?.viewControllers.firstIndex(of: self)
                            let settingsVC = (self.navigationController?.viewControllers[i!-1]) as! SettingsViewController
                            settingsVC.verifyEmailView.isHidden = true
                            
                            self.hideLoadingScreen()
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                
            }catch {
               
            }
            
        }
    }
    
    struct email_verification_obj: Codable{
        var time = 0
        var email = ""
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func whenResendTapped(_ sender: Any) {
        let me = Auth.auth().currentUser!
        
        me.sendEmailVerification { (e: Error?) in
            self.emailLabel.text = "Verification email sent to -> \(me.email!)"
        }
    }
    
    func isEmailVerified() -> Bool{
        let me = Auth.auth().currentUser!
        me.reload { (e: Error?) in
            
        }
        
        return me.isEmailVerified
        
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
