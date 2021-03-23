//
//  Account+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension Account {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

    @NSManaged public var country: String?
    @NSManaged public var email: String?
    @NSManaged public var email_verification_obj: String?
    @NSManaged public var gender: String?
    @NSManaged public var language: String?
    @NSManaged public var name: String?
    @NSManaged public var phone_verification_obj: String?
    @NSManaged public var scan_id_data: String?
    @NSManaged public var sign_up_time: Int64
    @NSManaged public var uid: String?
    @NSManaged public var user_type: String?
    @NSManaged public var complaints: NSSet?
    @NSManaged public var phone: Phone?
    @NSManaged public var ratings: NSSet?
    @NSManaged public var qualification: NSSet?

}

// MARK: Generated accessors for complaints
extension Account {

    @objc(addComplaintsObject:)
    @NSManaged public func addToComplaints(_ value: Complaint)

    @objc(removeComplaintsObject:)
    @NSManaged public func removeFromComplaints(_ value: Complaint)

    @objc(addComplaints:)
    @NSManaged public func addToComplaints(_ values: NSSet)

    @objc(removeComplaints:)
    @NSManaged public func removeFromComplaints(_ values: NSSet)

}

// MARK: Generated accessors for ratings
extension Account {

    @objc(addRatingsObject:)
    @NSManaged public func addToRatings(_ value: Rating)

    @objc(removeRatingsObject:)
    @NSManaged public func removeFromRatings(_ value: Rating)

    @objc(addRatings:)
    @NSManaged public func addToRatings(_ values: NSSet)

    @objc(removeRatings:)
    @NSManaged public func removeFromRatings(_ values: NSSet)

}

// MARK: Generated accessors for qualification
extension Account {

    @objc(addQualificationObject:)
    @NSManaged public func addToQualification(_ value: Qualification)

    @objc(removeQualificationObject:)
    @NSManaged public func removeFromQualification(_ value: Qualification)

    @objc(addQualification:)
    @NSManaged public func addToQualification(_ values: NSSet)

    @objc(removeQualification:)
    @NSManaged public func removeFromQualification(_ values: NSSet)

}
