//
//  FlaggedWord+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 07/01/2021.
//
//

import Foundation
import CoreData


extension FlaggedWord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlaggedWord> {
        return NSFetchRequest<FlaggedWord>(entityName: "FlaggedWord")
    }

    @NSManaged public var id: String?
    @NSManaged public var word: String?
    @NSManaged public var timestamp: Int64

}
