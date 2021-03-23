//
//  JobView+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension JobView {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JobView> {
        return NSFetchRequest<JobView>(entityName: "JobView")
    }

    @NSManaged public var job_id: String?
    @NSManaged public var view_id: String?
    @NSManaged public var view_time: Int64
    @NSManaged public var viewer_id: String?
    @NSManaged public var job: Job?

}
