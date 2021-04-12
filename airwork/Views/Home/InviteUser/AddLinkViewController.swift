//
//  AddLinkViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 12/04/2021.
//

import UIKit
import Firebase
import CoreData
import Foundation

class AddLinkViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var doneButtonItem: UIBarButtonItem!
    @IBOutlet weak var linkTextField: UITextField!
    
    var typed_link = ""
    var constants = Constants.init()
    var db = Firestore.firestore()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        linkTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            self.view.endEditing(true)
            return false
        }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func whenTypingDone(_ sender: UITextField) {
        hideErrorLabel()
        var typed_words = sender.text
        if typed_words == "" {
            showError("type something!")
            typed_link = ""
            doneButtonItem.isEnabled = false
        }else if(!CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: typed_words!))){
            showError("that wont work.")
            typed_link = ""
            doneButtonItem.isEnabled = false
        }else if(typed_words!.count < 9){
            showError("that wont work.")
            typed_link = ""
            doneButtonItem.isEnabled = false
        }
        else{
            typed_link = typed_words!
            doneButtonItem.isEnabled = true
        }
    }
    
    func showError(_ error: String){
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func hideErrorLabel(){
        errorLabel.isHidden = true
    }
    

    
    @IBAction func whenDonetapped(_ sender: UIBarButtonItem) {
        showLoadingScreen()
        let uid = Auth.auth().currentUser!.uid
        
        db.collection(constants.invites).whereField("link", isEqualTo: typed_link)
            .getDocuments() { [self] (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        
                        self.hideLoadingScreen()
                        self.showError("That didn't work.")
                        
                    } else {
                        if querySnapshot!.documents.isEmpty {
                            hideLoadingScreen()
                            showError("That doesn't work")
                        }else{
                            for document in querySnapshot!.documents {
                                let link_id = document.data()["link_id"] as! String
                                let creator = document.data()["creator"] as! String
                                let creation_time = document.data()["creation_time"] as! Int
                                let consumer = document.data()["consumer"] as! String
                                
                                if (creation_time > (Int(self.constants.get_now()) - self.constants.time_between_invites )) {
                                    if consumer == "N.A" {
                                        let theData: [String: Any] = [
                                            "consumer" : uid,
                                            "consume_time" : Int(self.constants.get_now())
                                        ]
                                        
                                        db.collection(constants.invites).document(link_id)
                                            .updateData(theData){ err in
                                                if let err = err {
                                                    print("Error writing document: \(err)")
                                                } else {
                                                    print("Document successfully written!")
                                                    self.hideLoadingScreen()
                                                    self.navigationController?.popViewController(animated: true)
                                                }
                                            }
                                        
                                    }else{
                                        hideLoadingScreen()
                                        showError("That doesn't work")
                                    }
                                }else{
                                    hideLoadingScreen()
                                    showError("That doesn't work")
                                }
                            }
                        }
                    }
            }
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
    
}
