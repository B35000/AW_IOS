//
//  SharedLocationUser+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 16/02/2021.
//
//

import Foundation
import CoreData


extension SharedLocationUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SharedLocationUser> {
        return NSFetchRequest<SharedLocationUser>(entityName: "SharedLocationUser")
    }

    @NSManaged public var last_online: Int64
    @NSManaged public var uid: String?
    @NSManaged public var loc_pack: String?
    @NSManaged public var country: String?

}
