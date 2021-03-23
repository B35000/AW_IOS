//
//  VerifyNumberViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 06/02/2021.
//

import UIKit

class VerifyNumberViewController: UIViewController {
    @IBOutlet weak var numberLabel: UILabel!
    var newNumber = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        numberLabel.text = newNumber
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
