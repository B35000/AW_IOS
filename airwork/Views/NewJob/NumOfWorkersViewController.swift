//
//  NumOfWorkersViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import Foundation

class NumOfWorkersViewController: UIViewController {
    @IBOutlet weak var numberOfWorkersField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var number = 0
    var asManySet = false
    
    
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

    @IBAction func whenCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func whenAsManySwitched(_ sender: UISwitch) {
        asManySet = sender.isOn
        hideErrorLabel()
        if asManySet {
            number = 0
            continueButton.isHidden = false
            numberOfWorkersField.text = ""
            numberOfWorkersField.isEnabled = false
        } else {
            numberOfWorkersField.isEnabled = true
            continueButton.isHidden = true
        }
    }
    
    @IBAction func whenNumberSet(_ sender: UITextField) {
        hideErrorLabel()
        
        var isnumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: sender.text!))
        
        if !sender.hasText && !asManySet && !isnumber{
            showError("Set a number")
            number = 0
            continueButton.isHidden = true
        }else if sender.text!.contains("-") {
            showError("You can't set that")
            number = 0
        }
        else if Int(sender.text!)! <= 0 {
            showError("You can't set that")
            number = 0
        } else if sender.hasText{
            number = Int(sender.text!) ?? 1
            continueButton.isHidden = false
        }
    }
    
    func showError(_ error: String){
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func hideErrorLabel(){
        errorLabel.isHidden = true
    }
    
}
