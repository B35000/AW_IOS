//
//  JobPayment+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 23/02/2021.
//
//

import Foundation
import CoreData


extension JobPayment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JobPayment> {
        return NSFetchRequest<JobPayment>(entityName: "JobPayment")
    }

    @NSManaged public var transaction_id: String?
    @NSManaged public var receipt_time: Int64
    @NSManaged public var payment_receipt: String?
    @NSManaged public var payment_id: String?

}
