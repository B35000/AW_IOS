//
//  SignUpIntroViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 29/12/2020.
//

import UIKit
import SafariServices
import Firebase
import CoreData

class SignUpIntroViewController: UIViewController {
    @IBOutlet weak var whenLicensePressed: UILabel!
    @IBOutlet weak var skipButton: UIButton!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SignUpIntroViewController.whenEulaTapped))
        whenLicensePressed.addGestureRecognizer(tap)
        
        if Auth.auth().currentUser != nil {
            if (Auth.auth().currentUser!.isAnonymous) {
                //anon, so hide skip btn
                skipButton.isHidden = true
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
    @IBAction func whenSkipPressed(_ sender: Any) {
        self.showLoadingScreen()
        
        Auth.auth().signInAnonymously { (result, error) in
            if error != nil {
                self.hideLoadingScreen()
            }else{
                let uid = result!.user.uid
                let time = round(NSDate().timeIntervalSince1970 * 1000)
                let account = Account(context: self.context)
                account.email = "unknown_email"
                account.country = "Kenya"
                account.email_verification_obj = ""
                account.gender = "Female"
                account.language = "en"
                account.name = "Anon"
                account.phone_verification_obj = ""
                account.sign_up_time = Int64(time)
                account.user_type = "user"
                account.uid = uid
                
                account.phone = Phone(context: self.context)
                account.phone?.country_currency = "KES"
                account.phone?.country_name = account.country
                account.phone?.country_name_code = "KE"
                account.phone?.country_number_code = "+254"
                account.phone?.digit_number = Int64(0)
                
                do{
                    try self.context.save()
                    self.hideLoadingScreen()
                    self.transitionToHome()
                }catch{
                    
                }
                
                
                
            }
        }
    }

    
    
    @objc func whenEulaTapped(sender:UITapGestureRecognizer) {
        print("open eula registered!")
        
        if let url = URL(string: "https://storage.googleapis.com/airwork/Airwork-Eula/index.html") {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
    }
    
    func transitionToHome(){
        let id = "HomeTabBarController"
    
        let homeViewController = storyboard?.instantiateViewController(identifier: id) as? UITabBarController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
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
