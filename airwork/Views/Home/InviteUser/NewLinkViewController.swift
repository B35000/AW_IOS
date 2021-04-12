//
//  NewLinkViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 12/04/2021.
//

import UIKit
import Firebase
import CoreData

class NewLinkViewController: UIViewController {
    @IBOutlet weak var inviteLinkLabel: UILabel!
    var link = ""
    var constants = Constants.init()
    var db = Firestore.firestore()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        generateLink()
    }
    
    func generateLink(){
        var my_invites = self.getMyInvitesIfExists()
        var active_invites = [String]()
        
        for invite in my_invites{
            if (invite.creation_time > (constants.get_now() - Int64(constants.time_between_invites))) {
                if invite.link! != constants.default_invite_link{
                    active_invites.append(invite.link_id!)
                }
            }
        }
        
        if !active_invites.isEmpty {
            let active_invite = self.getUserInviteIfExists(link_id: active_invites[0])
            link = "\(active_invite!.link!)"
            
            inviteLinkLabel.text = link
            
            
        }else{
            let randomInt = Int.random(in: 1..<1000000000)
            link = "\(randomInt)"
            
            inviteLinkLabel.text = link
            
            let invite_ref = db.collection(constants.invites).document()
            let uid = Auth.auth().currentUser!.uid
            
            let theData: [String: Any] = [
                "link_id" : invite_ref.documentID,
                "creator" : uid,
                "creation_time" : constants.get_now(),
                "link" : self.link,
                "consumer" : "N.A",
                "consume_time" : 0
            ]
            
            invite_ref.setData(theData)
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func whenCopyTapped(_ sender: UIButton) {
        UIPasteboard.general.string = self.link
        
        let alert = UIAlertController(title: "Copied to Clipboard", message: "\(self.link) copied to clipboard", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
                case .default:
                print("default")
                
                case .cancel:
                print("cancel")
                
                case .destructive:
                print("destructive")
                
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func getUserInviteIfExists(link_id: String) -> Invite? {
        do{
            let request = Invite.fetchRequest() as NSFetchRequest<Invite>
            let predic = NSPredicate(format: "link_id == %@", link_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    
    func getMyInvitesIfExists() -> [Invite] {
        do{
            let request = Invite.fetchRequest() as NSFetchRequest<Invite>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    func getLatestInviteIfExists() -> Invite? {
        do{
            let request = Invite.fetchRequest() as NSFetchRequest<Invite>
            let sortDesc = NSSortDescriptor(key: "creation_time", ascending: false)
            request.sortDescriptors = [sortDesc]
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    
}
