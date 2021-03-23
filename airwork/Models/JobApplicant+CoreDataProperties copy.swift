//
//  JobApplicant+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension JobApplicant {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JobApplicant> {
        return NSFetchRequest<JobApplicant>(entityName: "JobApplicant")
    }

    @NSManaged public var applicant_uid: String?
    @NSManaged public var application_pay_amount: Int64
    @NSManaged public var application_pay_currency: String?
    @NSManaged public var application_time: Int64
    @NSManaged public var job_country: String?
    @NSManaged public var job_id: String?
    @NSManaged public var job: Job?

}
