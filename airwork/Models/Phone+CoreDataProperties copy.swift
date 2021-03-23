//
//  Phone+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension Phone {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Phone> {
        return NSFetchRequest<Phone>(entityName: "Phone")
    }

    @NSManaged public var country_currency: String?
    @NSManaged public var country_name: String?
    @NSManaged public var country_name_code: String?
    @NSManaged public var country_number_code: String?
    @NSManaged public var digit_number: Int64
    @NSManaged public var account: Account?

}
