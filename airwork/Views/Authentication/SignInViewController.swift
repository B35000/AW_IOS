//
//  SignInViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 29/12/2020.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    @IBOutlet weak var emailInputField: UITextField!
    @IBOutlet weak var passwordInputField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func whenLoginPressed(_ sender: Any) {
        hideErrorLabel()
        
        if !emailInputField.hasText {
            showError("Type your email")
        }else if !passwordInputField.hasText {
            showError("Type your password")
        }else{
            let email = emailInputField.text! as String
            let password = passwordInputField.text! as String
            
            //sign in then move to home
            if ConnectionHelper.isConnectedToNetwork(){
                print("Internet Connection Available!")
                
                self.showLoadingScreen()
                Auth.auth().signIn(withEmail: email, password: password) { (result, err) in
                    if err != nil {
                        self.showError("That didn't work. Recheck your credetials and try again.")
                        print(err.debugDescription)
                    }else{
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
