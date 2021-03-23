//
//  JobHistoryViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 20/01/2021.
//

import UIKit
import CoreData

class JobHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var ratingsTableView: UITableView!
    
    var applicant_id: String = ""
    var job_id: String = ""
    var constants = Constants.init()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var ratings = [Rating]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ratings = getAccountRatings(applicant_id)
        ratingsTableView.delegate = self
        ratingsTableView.dataSource = self
        
        var appli = getApplicantAccount(applicant_id)
        self.title = appli?.name!
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ratings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ratingCell", for: indexPath) as! RatingTableViewCell
        let rating = ratings[indexPath.row]
        
        cell.ratingLabel.text = "\(round(10 * rating.rating)/10)"
        cell.rating.rating = round(10 * rating.rating)/10
        cell.rating.settings.updateOnTouch = false
        cell.rating.settings.fillMode = .precise
        
        var json = rating.job_object!
        let decoder = JSONDecoder()
        let jsonData = json.data(using: .utf8)!
        
        do{            
            let des_job =  try decoder.decode(job.self, from: jsonData)
            
            for item in des_job.selected_tags{
                cell.tags.append(item.tag_title)
            }
            cell.tagsCollectionView.reloadData()
            print("loaded \(des_job.selected_tags.count) tags")
            
            cell.jobTitleLabel.text = des_job.job_title
            cell.durationView.isHidden = false
            if des_job.work_duration != "" {
                cell.jobDurationLabel.text = des_job.work_duration
                if des_job.work_duration == constants.durationless {
                    cell.durationView.isHidden = true
                }
            }else{
                let s_date = DateComponents(calendar: .current, year: des_job.start_date.year, month: des_job.start_date.month, day: des_job.start_date.day).date!

                let e_date = DateComponents(calendar: .current, year: des_job.end_date.year, month: des_job.end_date.month, day: des_job.end_date.day).date!

                var timeOffset = s_date.offset(from: e_date)
                if timeOffset == "" {
                    timeOffset = e_date.offset(from: s_date)
                }
                cell.jobDurationLabel.text = "For \(timeOffset)"
            }
            
            var date = DateComponents(calendar: .current, year: des_job.end_date.year, month: des_job.end_date.month, day: des_job.end_date.day, hour: des_job.time.hour, minute: des_job.time.minute).date!

            cell.ratingTimeLabel.text = "@\(gett("h", date)):\(gett("mm", date))\(self.gett("a", date).lowercased())"
            cell.ratingMonthLabel.text = "\(gett("MMM", date))"
            cell.ratingDayLabel.text = "\(gett("d", date))"
        }catch {
            
        }
        
        return cell
    }
    
    struct job: Codable{
        var selected_tags: [JobTag] = []
        var job_title: String = ""
        var work_duration: String = ""
        var start_date: myDate = myDate()
        var end_date: myDate = myDate()
        var time: Time = Time()
        var uploader = Uploader()
    }
    
    struct JobTag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
    }
    
    struct myDate: Codable{
        var day = 0
        var month = 0
        var year = 0
        var day_of_week = ""
        var month_of_year = ""
    }
    
    struct Time: Codable{
        var hour = 0
        var minute = 0
        var am_pm = ""
    }
    
    struct Uploader: Codable{
        var id = ""
        var email = ""
        var name = ""
        var number = 0
        var country_code = ""
    }
    
    
    func getApplicantAccount(_ user_id: String) -> Account? {
        do{
            let request = Account.fetchRequest() as NSFetchRequest<Account>
            
            let predic = NSPredicate(format: "uid == %@", user_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getAccountRatings(_ user_id: String) -> [Rating] {
        do{
            let request = Rating.fetchRequest() as NSFetchRequest<Rating>
            
            let sortDesc = NSSortDescriptor(key: "rating_time", ascending: false)
            request.sortDescriptors = [sortDesc]
            
            let predic = NSPredicate(format: "rated_user_id == %@", user_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return filterRatings(ratings: items)
            }
            
        }catch {
            
        }
        
        return []
    }
    
    func filterRatings(ratings: [Rating]) -> [Rating] {
        var filtered_items = [Rating]()
        print("loaded \(ratings.count) ratings")
        
        for item in ratings {
            let job_id = item.job_id
            let job = self.getJobIfExists(rating: item)
            
            print("loaded \(item.rating_id!)")
            
            var req_id_format = "\(job!.uploader.id)\(job_id!)"
            if amIAirworker(){
                var unreq_id_format = "\(job_id!)"
                if item.rating_id! != unreq_id_format{
                    filtered_items.append(item)
                }
            }else{
                if item.rating_id! == req_id_format{
                    filtered_items.append(item)
                }
            }
            
        }
        
        return filtered_items
    }
    
    func getJobIfExists(rating: Rating) -> job? {
        var json = rating.job_object!
        let decoder = JSONDecoder()
        let jsonData = json.data(using: .utf8)!
        
        do{
            let des_job =  try decoder.decode(job.self, from: jsonData)
            return des_job
        }catch{
            print("error decoding job")
        }
        
        return nil
    }
    
    func amIAirworker() -> Bool{
        let app_data = self.getAppDataIfExists()
        
        if app_data!.is_airworker {
            return true
        }
        
        return false
    }
    
    func getAppDataIfExists() -> AppData? {
        do{
            let request = AppData.fetchRequest() as NSFetchRequest<AppData>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }else{
                let new_app_data = AppData(context: self.context)
                return new_app_data
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

}
