//
//  SkillsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 21/01/2021.
//

import UIKit
import Firebase
import CoreData

class SkillsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var skillsTableView: UITableView!
    @IBOutlet weak var openPdfButton: UIButton!
    @IBOutlet weak var openEditSkillButton: UIButton!
    
    var applicant_id = ""
    var qualifs = [Qualification]()
    var constants = Constants.init()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var picked_doc: Data? = nil
    var picked_q: Qualification? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        qualifs = getJobApplicantSkillsIfExists(applicant_id: applicant_id)
        
        skillsTableView.delegate = self
        skillsTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name(rawValue: constants.refresh_account), object: nil)
    }
    
    @objc func didGetNotification(_ notification: Notification){
        print("refreshing account!")
        self.skillsTableView.reloadData()
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
     //editQualificationSegue
        
        switch(segue.identifier ?? "") {
                        
        case "editQualificationSegue":
            guard let editSkillViewController = segue.destination as? NewSkillViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
//            guard let skillTableViewCell = sender as? SkillTableViewCell else {
//                fatalError("Unexpected sender: \(sender)")
//            }
//
//            guard let indexPath = skillsTableView.indexPath(for: skillTableViewCell) else {
//                fatalError("The selected cell is not being displayed by the table")
//            }
//
//            picked_q = qualifs[indexPath.row]
            editSkillViewController.edit_skill_id = picked_q!.qualification_id!
            
        case "viewPdfSegue":
            guard let viewPdfViewController = segue.destination as? ViewPdfViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            viewPdfViewController.picked_doc = picked_doc
            
            
        default:
            print("Unexpected Segue Identifier")
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        qualifs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "skillItemCell", for: indexPath) as! SkillTableViewCell
        let qualification = qualifs[indexPath.row]
        
        cell.titleLabel.text = qualification.title!
        cell.detailsLabel.text = qualification.details!
        
        if qualification.details == "" {
//            cell.detailsLabel.isHidden = true
            cell.detailsLabel.text = "No details available."
        }
        
        cell.user_id = qualification.user_id!
        cell.imagesCollection.isHidden = false
        cell.skill_id = qualification.qualification_id!
        cell.loadDocIfExists()
        
        var json = qualification.images!
        print("json data for images: \(json)")
        let decoder = JSONDecoder()
        let jsonData = json.data(using: .utf8)!
        
        do{
            let des_images =  try decoder.decode(quali_images.self, from: jsonData).set_images
            
            if des_images.isEmpty{
                print("images count for skill : \(des_images.count)")
                cell.imagesCollection.isHidden = true
            }
            
            for image in des_images {
                cell.skill_images.append(image.name)
            }
            
        }catch {
            print("decoder failed \(error.localizedDescription)")
            cell.imagesCollection.isHidden = true
        }
        
        cell.actionBlock = {
            self.picked_doc = cell.picked_doc!
            self.openPdfButton.sendActions(for: .touchUpInside)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let my_id = Auth.auth().currentUser!.uid
        print("clicked item on table view \(indexPath.row)")
        if applicant_id == my_id {
//            self.performSegue(withIdentifier: "editQualificationSegue", sender: self)
            picked_q = qualifs[indexPath.row]
            self.openEditSkillButton.sendActions(for: .touchUpInside)
        }
    }
    
    struct quali_images: Codable{
        var set_images = [my_Image]()
    }
    
    struct my_Image: Codable{
        var name = ""
    }
    
    func getJobApplicantSkillsIfExists(applicant_id: String) -> [Qualification]{
        do{
            let request = Qualification.fetchRequest() as NSFetchRequest<Qualification>
            
            let predic = NSPredicate(format: "user_id == %@", applicant_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }

}
