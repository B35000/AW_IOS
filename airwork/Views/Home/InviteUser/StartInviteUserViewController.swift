//
//  StartInviteUserViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 12/04/2021.
//

import UIKit

class StartInviteUserViewController: UIViewController {

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
    
}
