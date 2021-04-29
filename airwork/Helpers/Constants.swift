//
//  Constants.swift
//  airwork
//
//  Created by Bry Onyoni on 30/12/2020.
//

import Foundation
import UIKit
import CoreData
import Firebase

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
    let tag_data = "tag_data"
    
    let sign_in_broadcast = "sign_in_broadcast"
    let invites = "invites"
    let time_between_invites = (12*60*60*1000)
    let default_invite_link = "696969699"
    
    
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
    
    func get_now() -> Int64 {
        return Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
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
    
    
    
    var at_most_2 = "At most 2 hours."
    var two_to_four = "Around 2 to 4 hours."
    var whole_day = "The whole day."
    var myLat = -1.274483
    var myLng = 36.785340
    
    func getTagPricesForTags(selected_tags: [String], context: NSManagedObjectContext) -> [Double]{
        var tag_with_prices: [Double] = [Double]()
        var near_tags_with_their_prices:  [String: [Double]] = [String: [Double]]()
        var mid_tags_with_their_prices:  [String: [Double]] = [String: [Double]]()
        var far_tags_with_their_prices:  [String: [Double]] = [String: [Double]]()
        
        for selected_tag in selected_tags {
            var global_t = self.getGlobalTagIfExists(tag_title: selected_tag, context: context)
            
            if global_t != nil {
                var (near_tag_prices, mid_tag_prices, far_tag_prices) = getAssociatedTagPrices(global_t!, selected_tags, context: context)
                print("near tag prices associated for: \(global_t!.title!) -------------------------> \(near_tag_prices)")
                print("mid tag prices associated for: \(global_t!.title!) -------------------------> \(mid_tag_prices)")
                print("far tag prices associated for: \(global_t!.title!) -------------------------> \(far_tag_prices)")
                
                near_tags_with_their_prices[global_t!.title!] = near_tag_prices
                mid_tags_with_their_prices[global_t!.title!] = mid_tag_prices
                far_tags_with_their_prices[global_t!.title!] = far_tag_prices
                
//                if tag_with_prices.count < associated_tag_prices.count {
//                    tag_with_prices.removeAll()
//                    tag_with_prices.append(contentsOf: associated_tag_prices)
//                }
            }
        }
        
        if !near_tags_with_their_prices.isEmpty {
            for item in near_tags_with_their_prices.values {
                if tag_with_prices.count < item.count {
                    tag_with_prices.removeAll()
                    tag_with_prices.append(contentsOf: item)
                    print("using near items \(item)")
                }
            }
        }
        
        if !mid_tags_with_their_prices.isEmpty && tag_with_prices.isEmpty {
            for item in mid_tags_with_their_prices.values {
                if tag_with_prices.count < item.count {
                    tag_with_prices.removeAll()
                    tag_with_prices.append(contentsOf: item)
                    print("using mid items \(item)")
                }
            }
        }
        
        if !far_tags_with_their_prices.isEmpty && tag_with_prices.isEmpty {
            for item in far_tags_with_their_prices.values {
                if tag_with_prices.count < item.count {
                    tag_with_prices.removeAll()
                    tag_with_prices.append(contentsOf: item)
                    print("using far items \(item)")
                }
            }
        }
        
        return tag_with_prices
    }
    
    func getAssociatedTagPrices(_ global_tag: GlobalTag,_ selected_tags: [String],
                                context: NSManagedObjectContext) -> ([Double], [Double], [Double]) {
        var near_prices: [Double] = []
        var near_price_ids: [String] = []
        
        var mid_prices: [Double] = []
        var mid_price_ids: [String] = []
        
        var far_prices: [Double] = []
        var far_price_ids: [String] = []
        
        var associates = self.getGlobalTagAssociatesIfExists(tag_title: global_tag.title!, context: context)
//        print("tag associates for tag: \(global_tag.title!) -------------------------> \(associates)")
        if !associates.isEmpty{
            for associateTag in associates{
                var price = Double(associateTag.pay_amount)
                
                
                var json = associateTag.tag_associates
                let decoder = JSONDecoder()
                let jsonData = json!.data(using: .utf8)!
                
                do{
                    let tags: [json_tag] =  try decoder.decode(json_tag_array.self, from: jsonData).tags
                    var shared_tags: [String] = []
                    for item in tags{
                        
                        if selected_tags.contains(item.tag_title) {
                            if(!shared_tags.contains(item.tag_title)){
                                shared_tags.append(item.tag_title)
                            }
                        }
                    }
//
//                print("shared tags for fumigate: \(associateTag.job_id!): \(shared_tags)")
//
//                    print("adding price to far_prices")
                    var price_ids = "far_price_ids"
                    var prices = "far_prices"
                    
                    if(myLat != 0.0 && myLng != 0.0 && associateTag.location_latitude != 0.0 && associateTag.location_longitude != 0.0){
//                        print("my location is being factored,")
                        var location_lat = associateTag.location_latitude
                        var location_lng = associateTag.location_longitude
                        
                        let coordinate₀ = CLLocation(latitude: location_lat, longitude: location_lng)
                        let coordinate₁ = CLLocation(latitude: myLat, longitude: myLng)
                        let distanceInMeters = coordinate₀.distance(from: coordinate₁)
                    
//                        print("distance for tag: \(associateTag.title) to me: \(distanceInMeters)")
                        if distanceInMeters <= 1500.0 {
//                            print("adding price to near_prices instead")
                            price_ids = "near_price_ids"
                            prices = "near_prices"
                        }else if distanceInMeters <= 4000.0 {
//                            print("adding price to mid_prices instead")
                            price_ids = "mid_price_ids"
                            prices = "mid_prices"
                        }
                    }
                    
                    
                    if ( (shared_tags.count == 1 && selected_tags.count == 1) || (shared_tags.count >= 2) ){
                        //associated tag obj works
                        var price = Double(associateTag.pay_amount)
//                        print("set \(price) for tag \(associateTag.title!) : \(associateTag.job_id)")

                        if associateTag.no_of_days > 0 {
                            price = ((price / Double(associateTag.no_of_days)) / 4 )
                        }else if associateTag.work_duration != nil {
                            switch associateTag.work_duration {
                                case durationless:
                                    price = price / 1
                                case at_most_2:
                                    price = price / 1
                                case two_to_four:
                                    price = price / 2
                                default:
                                    price = price / 4
                            }
                        }
                        
                        
                        if prices == "far_prices" {
                            if(!far_price_ids.contains(associateTag.job_id!)){
                                far_prices.append(price)
                                far_price_ids.append(associateTag.job_id!)
                                
//                                print("---changed to \(price) into FAR")
                            }
                        }else if prices == "mid_prices"{
                            if(!mid_price_ids.contains(associateTag.job_id!)){
                                mid_prices.append(price)
                                mid_price_ids.append(associateTag.job_id!)
                                
//                                print("---changed to \(price) into MID")
                            }
                            
                        }else{
                            if(!near_price_ids.contains(associateTag.job_id!)){
                                near_prices.append(price)
                                near_price_ids.append(associateTag.job_id!)
                                
//                                print("---changed to \(price) into NEAR")
                            }
                            
                        }
                    }
                    
                }catch {
                    
                }
            }
        }
        
        
        
//        if !near_prices.isEmpty {
//            return near_prices
//
//        }else if !mid_prices.isEmpty {
//            return mid_prices
//        }
        
        return (near_prices, mid_prices, far_prices)
    }
    
    struct json_tag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
    }
    
    struct json_tag_array: Codable{
        var tags: [json_tag] = []
    }
    
    func getTopAverage(_ prices: [Double]) -> Double {
        let sortedPrices = prices.sorted(by: >)
        
        var number_of_items = Int(Double(prices.count) * 0.6)
        
        var total = 0.0
        for price in sortedPrices.prefix(number_of_items) {
            total += price
        }
        
        if total.isZero {
            return 0.0
        }
        
        return total / Double(number_of_items)
    }
    
    
    func getBottomAverage(_ prices: [Double]) -> Double {
        let sortedPrices = prices.sorted(by: <)
        
        var number_of_items = Int(Double(prices.count) * 0.6)
        
        var total = 0.0
        for price in sortedPrices.prefix(number_of_items) {
            total += price
        }
        
        if total.isZero {
            return 0.0
        }
        
        return total / Double(number_of_items)
    }
    
    
    func getGlobalTagsIfExists(context: NSManagedObjectContext) -> [GlobalTag]{
        do{
            let request = GlobalTag.fetchRequest() as NSFetchRequest<GlobalTag>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
        }catch {
            
        }
        
        return []
    }
    
    
    func getGlobalTagAssociatesIfExists(tag_title: String, context: NSManagedObjectContext) -> [JobTag]{
        do{
            let request = JobTag.fetchRequest() as NSFetchRequest<JobTag>
            let predic = NSPredicate(format: "title == %@ && global == \(NSNumber(value: true))", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    func getGlobalTagIfExists(tag_title: String, context: NSManagedObjectContext) -> GlobalTag?{
        do{
            let request = GlobalTag.fetchRequest() as NSFetchRequest<GlobalTag>
            let predic = NSPredicate(format: "title == %@", tag_title)
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
