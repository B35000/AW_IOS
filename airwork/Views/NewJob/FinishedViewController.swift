//
//  FinishedViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 07/01/2021.
//

import UIKit

class FinishedViewController: UIViewController {

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
    @IBAction func whenFinishedTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
