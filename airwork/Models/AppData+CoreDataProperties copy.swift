//
//  AppData+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension AppData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppData> {
        return NSFetchRequest<AppData>(entityName: "AppData")
    }

    @NSManaged public var global_tag_data_update_time: Int64

}
