//
//  SignUpEmailViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 29/12/2020.
//

import UIKit

class SignUpEmailViewController: UIViewController {
    @IBOutlet weak var emailInputField: UITextField!
    @IBOutlet weak var passwordInputField: UITextField!
    @IBOutlet weak var confirmPasswordInputField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var typedEmail = ""
    var typedPassword = ""
    var typedConfirmPassword = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        continueButton.isHidden = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func whenEmailInputChanged(_ sender: UITextField) {
        hideErrorLabel()
        
        if !sender.hasText {
            showError("Set your email.")
            typedEmail = ""
            
        } else if !isValidEmail(sender.text!) {
            showError("That email is invalid.")
            typedEmail = ""
            
        } else {
            typedEmail = sender.text!
        }
        
        showNextButtonIfCorrectDataSet()
    }
    @IBAction func whenEmailInputSet(_ sender: UITextField) {
        showNextButtonIfCorrectDataSet()
    }
    

    
    @IBAction func whenPasswordInputChanged(_ sender: UITextField) {
        hideErrorLabel()
        
        if !sender.hasText {
            showError("Set a password.")
            typedPassword = ""
        } else if sender.text!.count < 8 {
            showError("Password must be at least 8 characters")
            typedPassword = ""
        } else {
            typedPassword = sender.text!
        }
        
        showNextButtonIfCorrectDataSet()
    }
    
    @IBAction func whenPasswordInputSet(_ sender: UITextField) {
        
        showNextButtonIfCorrectDataSet()
    }
    
    @IBAction func whenConfirmPasswordInputChanged(_ sender: UITextField) {
        hideErrorLabel()
        
        if !sender.hasText {
            showError("Set a password.")
            typedConfirmPassword = ""
        } else if sender.text!.count < 8 {
            showError("Password must be at least 8 characters.")
            typedConfirmPassword = ""
        } else if sender.text! != typedPassword {
            showError("The two typed passwords dont match!")
            typedConfirmPassword = ""
        }else {
            typedConfirmPassword = sender.text!
        }
        
        showNextButtonIfCorrectDataSet()
    }
    
    @IBAction func whenConfirmPasswordInputSet(_ sender: UITextField) {
        
        showNextButtonIfCorrectDataSet()
    }
    
    func showError(_ error: String){
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func hideErrorLabel(){
        errorLabel.isHidden = true
    }
    
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    
    func showNextButtonIfCorrectDataSet(){
        if typedEmail != "" && typedPassword != "" && typedConfirmPassword != "" {
            continueButton.isHidden = false
        } else {
            continueButton.isHidden = true
        }
        
    }
    
    
}
