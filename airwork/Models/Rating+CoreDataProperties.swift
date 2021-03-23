//
//  Rating+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 16/01/2021.
//
//

import Foundation
import CoreData


extension Rating {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Rating> {
        return NSFetchRequest<Rating>(entityName: "Rating")
    }

    @NSManaged public var job_country: String?
    @NSManaged public var job_id: String?
    @NSManaged public var job_object: String?
    @NSManaged public var language: String?
    @NSManaged public var rating: Double
    @NSManaged public var rating_explanation: String?
    @NSManaged public var rating_time: Int64
    @NSManaged public var user_id: String?
    @NSManaged public var rating_id: String?
    @NSManaged public var account: Account?
    @NSManaged public var contact: Contact?

}
