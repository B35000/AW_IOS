//
//  AppData+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 23/02/2021.
//
//

import Foundation
import CoreData


extension AppData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppData> {
        return NSFetchRequest<AppData>(entityName: "AppData")
    }

    @NSManaged public var global_tag_data_update_time: Int64
    @NSManaged public var is_airworker: Bool

}
