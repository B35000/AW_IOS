//
//  ViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 24/12/2020.
//

import UIKit
import Firebase

class LauncherScreen: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if Auth.auth().currentUser != nil{
              // User is signed in.
                print("User is signed in")
                
                let id = "HomeTabBarController"
            
                let homeViewController = self.storyboard?.instantiateViewController(identifier: id) as? UITabBarController
                self.view.window?.rootViewController = homeViewController
                self.view.window?.makeKeyAndVisible()
                
            } else {
              // No user is signed in.
                print("No user exists")
                
                let id = "SignUpNavigationController"
//                do{
//                    try Auth.auth().signOut()
//                }catch{
//
//                }
                
            
                let SignUpIntroViewController = self.storyboard?.instantiateViewController(identifier: id) as? SignUpNavigationController
                self.view.window?.rootViewController = SignUpIntroViewController
                self.view.window?.makeKeyAndVisible()
            }
        }
       
        
    }


}

