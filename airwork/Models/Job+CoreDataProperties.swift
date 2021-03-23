//
//  Job+CoreDataProperties.swift
//  
//
//  Created by Bry Onyoni on 31/12/2020.
//
//

import Foundation
import CoreData


extension Job {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Job> {
        return NSFetchRequest<Job>(entityName: "Job")
    }

    @NSManaged public var am_pm: String?
    @NSManaged public var applicant_set_pay: Bool
    @NSManaged public var auto_taken_down: Bool
    @NSManaged public var country_name: String?
    @NSManaged public var country_name_code: String?
    @NSManaged public var end_day: Int64
    @NSManaged public var end_day_of_week: String?
    @NSManaged public var end_month: Int64
    @NSManaged public var end_month_of_year: String?
    @NSManaged public var end_year: Int64
    @NSManaged public var images: String?
    @NSManaged public var is_asap: Bool
    @NSManaged public var is_job_private: Bool
    @NSManaged public var job_details: String?
    @NSManaged public var job_id: String?
    @NSManaged public var job_title: String?
    @NSManaged public var job_worker_count: Int64
    @NSManaged public var language: String?
    @NSManaged public var location_desc: String?
    @NSManaged public var location_lat: Double
    @NSManaged public var location_long: Double
    @NSManaged public var pay_amount: Int64
    @NSManaged public var pay_currency: String?
    @NSManaged public var selected_day: Int64
    @NSManaged public var selected_day_of_week: String?
    @NSManaged public var selected_month: Int64
    @NSManaged public var selected_month_of_year: String?
    @NSManaged public var selected_users_for_job: String?
    @NSManaged public var selected_workers: String?
    @NSManaged public var selected_year: Int64
    @NSManaged public var start_day: Int64
    @NSManaged public var start_day_of_week: String?
    @NSManaged public var start_month: Int64
    @NSManaged public var start_month_of_year: String?
    @NSManaged public var start_year: Int64
    @NSManaged public var taken_down: Bool
    @NSManaged public var time_hour: Int64
    @NSManaged public var time_minute: Int64
    @NSManaged public var upload_time: Int64
    @NSManaged public var uploader_email: String?
    @NSManaged public var uploader_id: String?
    @NSManaged public var uploader_name: String?
    @NSManaged public var uploader_phone_number: Int64
    @NSManaged public var uploader_phone_number_code: String?
    @NSManaged public var work_duration: String?
    @NSManaged public var jobApplicants: NSSet?
    @NSManaged public var jobViews: NSSet?
    @NSManaged public var tags: NSSet?
    @NSManaged public var uploadedJob: UploadedJob?

}

// MARK: Generated accessors for jobApplicants
extension Job {

    @objc(addJobApplicantsObject:)
    @NSManaged public func addToJobApplicants(_ value: JobApplicant)

    @objc(removeJobApplicantsObject:)
    @NSManaged public func removeFromJobApplicants(_ value: JobApplicant)

    @objc(addJobApplicants:)
    @NSManaged public func addToJobApplicants(_ values: NSSet)

    @objc(removeJobApplicants:)
    @NSManaged public func removeFromJobApplicants(_ values: NSSet)

}

// MARK: Generated accessors for jobViews
extension Job {

    @objc(addJobViewsObject:)
    @NSManaged public func addToJobViews(_ value: JobView)

    @objc(removeJobViewsObject:)
    @NSManaged public func removeFromJobViews(_ value: JobView)

    @objc(addJobViews:)
    @NSManaged public func addToJobViews(_ values: NSSet)

    @objc(removeJobViews:)
    @NSManaged public func removeFromJobViews(_ values: NSSet)

}

// MARK: Generated accessors for tags
extension Job {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: JobTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: JobTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}
