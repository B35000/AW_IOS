//
//  Resource+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 29/03/2021.
//
//

import Foundation
import CoreData


extension Resource {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Resource> {
        return NSFetchRequest<Resource>(entityName: "Resource")
    }

    @NSManaged public var data: Data?
    @NSManaged public var last_referenced: Int64
    @NSManaged public var data_id: String?
    @NSManaged public var author_id: String?

}
