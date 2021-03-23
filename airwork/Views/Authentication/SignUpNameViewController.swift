//
//  SignUpNameViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 29/12/2020.
//

import UIKit

class SignUpNameViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var femaleLabel: UILabel!
    @IBOutlet weak var maleLabel: UILabel!
    
    @IBOutlet weak var femaleImage: UIImageView!
    @IBOutlet weak var maleImage: UIImageView!
    
    var gender = "Female"
    var typedName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let male_tap = UITapGestureRecognizer(target: self, action: #selector(SignUpNameViewController.whenMaleGenderPicked))
        
        let female_tap = UITapGestureRecognizer(target: self, action: #selector(SignUpNameViewController.whenFemaleGenderPicked))
        
        
        femaleLabel.addGestureRecognizer(female_tap)
        maleLabel.addGestureRecognizer(male_tap)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func whenNameInputChanged(_ sender: UITextField) {
        if sender.text! == "" {
            print("nothing typed")
            continueButton.isHidden = true
            typedName = ""
        } else if sender.text!.count < 3 {
            continueButton.isHidden = true
            typedName = ""
        }
        else{
            print(sender.text!)
            continueButton.isHidden = false
            typedName = sender.text!
        }
        
        
    }
    
    
    @objc func whenFemaleGenderPicked(sender:UITapGestureRecognizer) {
        if gender == "Male" {
            gender = "Female"
            
            femaleImage.isHidden = false
            maleImage.isHidden = true
        }

        print("set gender \(gender)")
       }
    
    @objc func whenMaleGenderPicked(sender:UITapGestureRecognizer) {
        if gender == "Female" {
            gender = "Male"
            
            femaleImage.isHidden = true
            maleImage.isHidden = false
        }
        
        print("set gender \(gender)")
       }
    
    
    
    
}
