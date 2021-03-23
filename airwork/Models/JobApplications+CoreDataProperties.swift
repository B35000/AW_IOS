//
//  JobApplications+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 16/02/2021.
//
//

import Foundation
import CoreData


extension JobApplications {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JobApplications> {
        return NSFetchRequest<JobApplications>(entityName: "JobApplications")
    }

    @NSManaged public var user_id: String?
    @NSManaged public var job_id: String?
    @NSManaged public var country: String?
    @NSManaged public var time: Int64

}
