//
//  Constants.swift
//  airwork
//
//  Created by Bry Onyoni on 30/12/2020.
//

import Foundation
import UIKit
import CoreData

struct Constants{
    let users_ref = "users"
    let airworkers_ref = "airworkers"
    let jobs_ref = "jobs"
    let meta_data = "meta_data"
    let phone = "phone"
    let my_contacts = "my_contacts"
    let contact_ratings = "contact_ratings"
    let all_my_ratings = "all_my_ratings"
    let job_history = "job_history"
    let country_jobs = "country_jobs"
    let views = "views"
    let applicants = "applicants"
    let notifications = "notifications"
    let complaints = "complaints"
    let qualifications = "qualifications"
    let tags = "tags"
    let public_locations = "public_locations"
    
    let refresh_account = "refresh_account"
    let refresh_job = "refresh_job"
    let refresh_app = "refresh_app"
    let swapped_account_type = "swapped_account_type"
    
    let flagged_words = "flagged_words"
    let jobs = "jobs"
    let users_data = "users_data"
    let job_images = "job_images"
    let maxNumber = 999999999
    let durationless = "Durationless"
    
    let qualification_images = "qualification_images"
    let my_job_ratings = "my_job_ratings"
    let worker_ratings = "worker_ratings"
    let its_jobs = "its_jobsod"
    let location_data = "location_data"
    let my_applied_jobs = "my_applied_jobs"
    let type_airworker = "airworker"
    let job_payments = "job_payments"
    let employee_ratings = "employee_ratings"
    let employer_rating = "employer_rating"
    
    let addFrontCard = "addFrontCard"
    let addBackCard = "addBackCard"
    let addPassportPage = "addPassportPage"
    let qualification_document = "qualification_document"
    let pay_perc = 0.055
    let job_document = "job_document"
    
    
    func randomString(_ length: Int) -> String {

        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
    
    func getResourceIfExists(data_id: String, context: NSManagedObjectContext) -> Resource?{
        var data = getData(data_id, context: context)
        
        if data != nil {
            let now = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
            data?.last_referenced = Int64(now)
            do{
                try context.save()
            }catch{
                
            }
            
            return data
        }
        
        return nil
    }
    
    func storeResource(data_id: String, context: NSManagedObjectContext, data: Data, author_id: String){
        let now = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        var new_resource = getData(data_id, context: context)
        
        if new_resource == nil {
            new_resource = Resource(context: context)
        }
        new_resource?.author_id = author_id
        new_resource?.data = data
        new_resource?.data_id = data_id
        new_resource?.last_referenced = Int64(now)
        
        do{
            try context.save()
        }catch{
            
        }
    }
    
    func removeResource(data_id: String, context: NSManagedObjectContext){
        var new_resource = getData(data_id, context: context)
        
        if new_resource != nil {
            do{
                try context.delete(new_resource!)
            }catch{
                
            }
        }
    }
    
    func getData(_ data_id: String, context: NSManagedObjectContext) -> Resource? {
        do{
            let request = Resource.fetchRequest() as NSFetchRequest<Resource>
            
            let predic = NSPredicate(format: "data_id == %@", data_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
}


@IBDesignable
class CardView: UIView {

    @IBInspectable var cornerRadius: CGFloat = 2

    @IBInspectable var shadowOffsetWidth: Int = 0
    @IBInspectable var shadowOffsetHeight: Int = 3
    @IBInspectable var shadowColor: UIColor? = UIColor.black
    @IBInspectable var shadowOpacity: Float = 0.5

    override func layoutSubviews() {
        layer.cornerRadius = cornerRadius
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)

        layer.masksToBounds = false
        layer.shadowColor = shadowColor?.cgColor
        layer.shadowOffset = CGSize(width: shadowOffsetWidth, height: shadowOffsetHeight);
        layer.shadowOpacity = shadowOpacity
        layer.shadowPath = shadowPath.cgPath
    }

}

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
    
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    func resized(toWidth width: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}
