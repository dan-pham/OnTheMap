//
//  StudentInformation.swift
//  OnTheMap
//
//  Created by Dan Pham on 2/20/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation

struct StudentInformation {
    
    // MARK: Properties
    
    // Information for a single student object
    let objectId: String?
    let uniqueKey: String?
    let firstName: String?
    let lastName: String?
    let mapString: String?
    let mediaURL: String?
    let latitude: Double?
    let longitude: Double?

    // MARK: Initializer
    
    init(dictionary: [String: AnyObject]) {
        objectId = dictionary["objectId"] as? String
        uniqueKey = dictionary["uniqueKey"] as? String
        firstName = dictionary["firstName"] as? String
        lastName = dictionary["lastName"] as? String
        mapString = dictionary["mapString"] as? String
        mediaURL = dictionary["mediaURL"] as? String
        latitude = dictionary["latitude"] as? Double
        longitude = dictionary["longitude"] as? Double
    }
    
}
