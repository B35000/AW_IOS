//
//  AppliedJob+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 23/02/2021.
//
//

import Foundation
import CoreData


extension AppliedJob {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppliedJob> {
        return NSFetchRequest<AppliedJob>(entityName: "AppliedJob")
    }

    @NSManaged public var job_id: String?
    @NSManaged public var applicant_uid: String?
    @NSManaged public var job_country: String?
    @NSManaged public var application_time: Int64
    @NSManaged public var application_pay_amount: Int64
    @NSManaged public var application_pay_currency: String?
    @NSManaged public var applicant_set_pay: Bool

}
