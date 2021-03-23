//
//  TakeDownViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 29/01/2021.
//

import UIKit
import CoreData
import Firebase

class TakeDownViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var takeDownExplanationLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var tagsCollectionView: UICollectionView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    var job_id = ""
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var jobTags = [JobTag]()
    var job: Job? = nil
    var constants = Constants.init()
    let db = Firestore.firestore()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadJob()
    }
    
    func loadJob(){
        job = self.getJobIfExists(job_id: job_id)!
        for tag in job!.tags! {
            jobTags.append(tag as! JobTag)
        }
        
        if job!.taken_down == true {
            self.title = "Restore"
            takeDownExplanationLabel.text = "Continue to restore this job? This will make it visible to others again."
        }
        
        tagsCollectionView.delegate = self
        tagsCollectionView.dataSource = self
        
        titleLabel.text = job!.job_title!
        
        let date = DateComponents(calendar: .current, year: Int(job!.start_year), month: Int(job!.start_month)+1, day: Int(job!.start_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        let end_date = DateComponents(calendar: .current, year: Int(job!.end_year), month: Int(job!.end_month)+1, day: Int(job!.end_day), hour: Int(job!.time_hour), minute: Int(job!.time_minute)).date!
        
        var timeOffset = date.offset(from: Date())
        if timeOffset == "" {
            timeOffset = Date().offset(from: date)
            dateLabel.text = "\(timeOffset) ago."
        }else{
            dateLabel.text = "In \(timeOffset)"
        }
        
        if job!.work_duration! == "" {
            timeOffset = end_date.offset(from: date)
            if timeOffset == "" {
                timeOffset = date.offset(from: end_date)
            }
            durationLabel.text = "\(timeOffset)"
            
        }else{
            if job!.work_duration! == constants.durationless {
                durationLabel.text = " "
            }else{
                durationLabel.text = "\(job!.work_duration!)"
            }
            
        }
        
        
        amountLabel.text = "\(job!.pay_currency!) \(job!.pay_amount) Quoted."
        timeLabel.text = "At \(job!.time_hour):\(job!.time_minute)\(self.gett("a", date).lowercased())"
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return jobTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "TakeDownJobTagCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TakeDownTagCollectionViewCell
        let tag = jobTags[indexPath.row]

        cell.titleLabel.text = tag.title
        
        return cell
    }
    
    
    @IBAction func whenContinueTapped(_ sender: Any) {
        self.showLoadingScreen()
        let taken_down = !job!.taken_down
        print("take down value: \(taken_down)")
        db.collection(constants.jobs)
            .document(job!.country_name!)
            .collection("country_jobs")
            .document(job!.job_id!)
            .updateData([
                "taken_down" : taken_down
            ]){ err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                    self.hideLoadingScreen()
                    self.navigationController?.popViewController(animated: true)
                }
                
            }
    }
    
    
    
    func getJobIfExists(job_id: String) -> Job? {
        do{
            let request = Job.fetchRequest() as NSFetchRequest<Job>
            let predic = NSPredicate(format: "job_id == %@", job_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
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
