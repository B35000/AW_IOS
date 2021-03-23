//
//  JobTag+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 03/01/2021.
//
//

import Foundation
import CoreData


extension JobTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JobTag> {
        return NSFetchRequest<JobTag>(entityName: "JobTag")
    }

    @NSManaged public var job_id: String?
    @NSManaged public var location_description: String?
    @NSManaged public var location_latitude: Double
    @NSManaged public var location_longitude: Double
    @NSManaged public var no_of_days: Int64
    @NSManaged public var pay_amount: Int64
    @NSManaged public var pay_currency: String?
    @NSManaged public var record_time: Int64
    @NSManaged public var tag_associates: String?
    @NSManaged public var title: String?
    @NSManaged public var work_duration: String?
    @NSManaged public var global: Bool
    @NSManaged public var job: Job?

}
