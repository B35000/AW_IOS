//
//  NotificationsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 10/01/2021.
//

import UIKit
import CoreData

class NotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var notificationsTableView: UITableView!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var notifications = [Notification]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        notificationsTableView.delegate = self
        notificationsTableView.dataSource = self
        notifications = self.getNotificationsIfExists()
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch(segue.identifier ?? "") {
                        
        case "viewJob":
            guard let jobDetailViewController = segue.destination as? JobDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedMealCell = sender as? NotificationTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = notificationsTableView.indexPath(for: selectedMealCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedNotif = notifications[indexPath.row]
            print("notif item: \(selectedNotif.message)")
//            jobDetailViewController = selectedNotif
            jobDetailViewController.job_id = selectedNotif.job_id!
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notificationView", for: indexPath) as! NotificationTableViewCell

        let notification = notifications[indexPath.row]
        let pos = indexPath.row+1
        cell.notificationItem.text = "\(pos).\(notification.message!)"
       
        let date = Date(timeIntervalSince1970: TimeInterval(notification.time) / 1000)
        var timeOffset = Date().offset(from: date)
        if timeOffset == "" {
            timeOffset = date.offset(from: Date())
        }
        cell.notifAgeLabel.text = "\(timeOffset)"
        
        cell.senderLabel.text = "from \(notification.user_name!)"
        
        return cell
    }
    
    func getNotificationsIfExists() -> [Notification] {
        do{
            let request = Notification.fetchRequest() as NSFetchRequest<Notification>
            let sortDesc = NSSortDescriptor(key: "time", ascending: true)
            request.sortDescriptors = [sortDesc]
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }


    
}
