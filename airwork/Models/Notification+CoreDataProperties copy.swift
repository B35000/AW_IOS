//
//  Notification+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension Notification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Notification> {
        return NSFetchRequest<Notification>(entityName: "Notification")
    }

    @NSManaged public var job_id: String?
    @NSManaged public var message: String?
    @NSManaged public var notif_id: String?
    @NSManaged public var seen: Int64
    @NSManaged public var time: Int64
    @NSManaged public var user_id: String?
    @NSManaged public var user_name: String?
    @NSManaged public var job: Job?

}
