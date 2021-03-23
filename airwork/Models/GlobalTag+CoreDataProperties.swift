//
//  GlobalTag+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 03/01/2021.
//
//

import Foundation
import CoreData


extension GlobalTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GlobalTag> {
        return NSFetchRequest<GlobalTag>(entityName: "GlobalTag")
    }

    @NSManaged public var country: String?
    @NSManaged public var last_update: Int64
    @NSManaged public var title: String?
    @NSManaged public var tag_associates: NSSet?

}

// MARK: Generated accessors for tag_associates
extension GlobalTag {

    @objc(addTag_associatesObject:)
    @NSManaged public func addToTag_associates(_ value: JobTag)

    @objc(removeTag_associatesObject:)
    @NSManaged public func removeFromTag_associates(_ value: JobTag)

    @objc(addTag_associates:)
    @NSManaged public func addToTag_associates(_ values: NSSet)

    @objc(removeTag_associates:)
    @NSManaged public func removeFromTag_associates(_ values: NSSet)

}
