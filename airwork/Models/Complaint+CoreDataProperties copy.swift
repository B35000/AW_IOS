//
//  Complaint+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension Complaint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Complaint> {
        return NSFetchRequest<Complaint>(entityName: "Complaint")
    }

    @NSManaged public var id: String?
    @NSManaged public var message: String?
    @NSManaged public var reported_id: String?
    @NSManaged public var reporter_id: String?
    @NSManaged public var timestamp: Int64
    @NSManaged public var account: Account?

}
