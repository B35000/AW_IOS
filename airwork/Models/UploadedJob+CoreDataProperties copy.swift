//
//  UploadedJob+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension UploadedJob {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UploadedJob> {
        return NSFetchRequest<UploadedJob>(entityName: "UploadedJob")
    }

    @NSManaged public var applicant_set_pay: Bool
    @NSManaged public var country_name: String?
    @NSManaged public var job_id: String?
    @NSManaged public var location_desc: String?
    @NSManaged public var location_lat: Double
    @NSManaged public var location_long: Double
    @NSManaged public var pay_amount: Int64
    @NSManaged public var pay_currency: String?
    @NSManaged public var selected_date_day: Int64
    @NSManaged public var selected_date_month: Int64
    @NSManaged public var selected_date_year: Int64
    @NSManaged public var selected_day_of_week: String?
    @NSManaged public var selected_month_of_year: String?
    @NSManaged public var upload_time: Int64
    @NSManaged public var job: Job?

}
