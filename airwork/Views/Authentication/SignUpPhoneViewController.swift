//
//  SignUpPhoneViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 28/12/2020.
//

import UIKit
import CountryPickerView
import Firebase

class SignUpPhoneViewController: UIViewController {
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var cpvMain: CountryPickerView!
    @IBOutlet weak var finishButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    let db = Firestore.firestore()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
//        let cp = CountryPickerView(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
//        phoneNumberField.leftView = cp
//        phoneNumberField.leftViewMode = .always
//        self.cpvTextField = cp
        
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func whenFinishPressed(_ sender: Any) {
        hideErrorLabel()
        
        if !phoneNumberField.hasText {
            showError("Type a phone number!")
        } else {
            var typedNumber = phoneNumberField.text! as String
            if typedNumber.count == 10 {
                typedNumber.remove(at: typedNumber.startIndex)
            }
            
            let country = cpvMain.selectedCountry.name
            let countryCode = cpvMain.selectedCountry.code
            let phoneCode = cpvMain.selectedCountry.phoneCode
            
            print("country: \(country)")
            print("number: \(typedNumber)")
            print("country code: \(countryCode)")
            print("country phone code: \(phoneCode)")
            
            //sign up then move to home
            
            let i = navigationController?.viewControllers.firstIndex(of: self)
            
            let emailVC = (navigationController?.viewControllers[i!-1]) as! SignUpEmailViewController
            let nameVC = (navigationController?.viewControllers[i!-2]) as! SignUpNameViewController
            
            let typedEmail = emailVC.typedEmail
            let typedPassword = emailVC.typedPassword
            let typedName = nameVC.typedName
            let gender = nameVC.gender
            
            print("email: \(typedEmail)")
            print("password: \(typedPassword)")
            print("name: \(typedName)")
            print("gender: \(gender)")
            
            if ConnectionHelper.isConnectedToNetwork(){
                print("Internet Connection Available!")
                
                self.showLoadingScreen()
                Auth.auth().createUser(withEmail: typedEmail, password: typedPassword)
                { (result, err) in
                    if err != nil {
                        self.showError("Something went wrong. Retry after a few moments.")
                    }
                    else {
                       //Transition to the home screen
                        let time = round(NSDate().timeIntervalSince1970 * 1000)
                        self.transitionToHome()
                    }
                    self.hideLoadingScreen()
                }
                
            }else{
                print("Internet Connection not Available!")
                showError("Please connect to the internet")
            }
        }
        
        
    }
    
    
    func showError(_ error: String){
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func hideErrorLabel(){
        errorLabel.isHidden = true
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
    
    
    func transitionToHome(){
        let id = "HomeTabBarController"
    
        let homeViewController = storyboard?.instantiateViewController(identifier: id) as? UITabBarController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    
}


