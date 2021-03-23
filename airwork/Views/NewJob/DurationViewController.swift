//
//  DurationViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import Foundation

class DurationViewController: UIViewController {
    @IBOutlet weak var twoHrsLabel: UILabel!
    @IBOutlet weak var twoFourHoursLabel: UILabel!
    @IBOutlet weak var wholeDayLabel: UILabel!
    
    @IBOutlet weak var twoHrsImage: UIImageView!
    @IBOutlet weak var twoFourHrsImage: UIImageView!
    @IBOutlet weak var wholeDayImage: UIImageView!
    
    
    @IBOutlet weak var daysNoField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var asManySwitch: UISwitch!
    
    var time_duration = ""
    var days_duration = 0
    
    var at_most_2 = "At most 2 hours."
    var two_to_four = "Around 2 to 4 hours."
    var whole_day = "The whole day."
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let twoHrsTapped = UITapGestureRecognizer(target: self, action: #selector(DurationViewController.whenTwo))
        
        let twoToFourTapped = UITapGestureRecognizer(target: self, action: #selector(DurationViewController.whenTwoToFour))
        
        let wholeDayTapped = UITapGestureRecognizer(target: self, action: #selector(DurationViewController.whenWholeDay))
        
        
        twoHrsLabel.addGestureRecognizer(twoHrsTapped)
        twoFourHoursLabel.addGestureRecognizer(twoToFourTapped)
        wholeDayLabel.addGestureRecognizer(wholeDayTapped)
        
        setDurationCheckIcon()
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    @objc func whenTwo(sender:UITapGestureRecognizer){
        if !asManySwitch.isOn{
            time_duration = at_most_2
            setDurationCheckIcon()
        }
    }
    
    @objc func whenTwoToFour(sender:UITapGestureRecognizer){
        if !asManySwitch.isOn{
            time_duration = two_to_four
            setDurationCheckIcon()
        }
    }
    
    @objc func whenWholeDay(sender:UITapGestureRecognizer){
        if !asManySwitch.isOn{
            time_duration = whole_day
            setDurationCheckIcon()
        }
    }
    

    @IBAction func onCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func durationNotExactSwitched(_ sender: UISwitch) {
        if sender.isOn {
            daysNoField.text = ""
            daysNoField.isEnabled = false
            
            time_duration = ""
            days_duration = 0
            removeDurationCheckIcon()
        }else{
            setDurationCheckIcon()
            daysNoField.isEnabled = true
        }
    }
    
    @IBAction func whenDaysNoTyped(_ sender: UITextField) {
        var isnumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: sender.text!))

        if sender.hasText {
             days_duration = Int(sender.text!) ?? 1
             removeDurationCheckIcon()
         }else{
             setDurationCheckIcon()
         }
    }
    
    
    func setDurationCheckIcon(){
        twoHrsImage.isHidden = true
        twoFourHrsImage.isHidden = true
        wholeDayImage.isHidden = true
        
        switch time_duration {
            case at_most_2:
                twoHrsImage.isHidden = false
            case two_to_four:
                twoFourHrsImage.isHidden = false
            case whole_day:
                wholeDayImage.isHidden = false
            default:
                time_duration = at_most_2
                twoHrsImage.isHidden = false
        }
        
        days_duration = 0
        daysNoField.text = ""
    }
    
    func removeDurationCheckIcon(){
        twoHrsImage.isHidden = true
        twoFourHrsImage.isHidden = true
        wholeDayImage.isHidden = true
    }
    
}
