//
//  Invite+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 12/04/2021.
//
//

import Foundation
import CoreData


extension Invite {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Invite> {
        return NSFetchRequest<Invite>(entityName: "Invite")
    }

    @NSManaged public var link_id: String?
    @NSManaged public var creator: String?
    @NSManaged public var creation_time: Int64
    @NSManaged public var link: String?
    @NSManaged public var consumer: String?
    @NSManaged public var consume_time: Int64

}
