//
//  Qualification+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension Qualification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Qualification> {
        return NSFetchRequest<Qualification>(entityName: "Qualification")
    }

    @NSManaged public var title: String?
    @NSManaged public var details: String?
    @NSManaged public var last_update: Int64
    @NSManaged public var user_id: String?
    @NSManaged public var qualification_id: String?
    @NSManaged public var images: String?
    @NSManaged public var account: Account?

}
