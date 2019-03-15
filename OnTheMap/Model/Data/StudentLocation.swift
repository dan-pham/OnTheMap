//
//  StudentLocation.swift
//  OnTheMap
//
//  Created by Dan Pham on 2/20/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation

struct StudentLocation {
    
    // MARK: Properties
    
    // Store student information as an array
    static var studentInformation = [StudentInformation]()
    
    // MARK: Student location dictionary
    
    // Store student locations as an array of dictionaries
    static func studentLocations(locations: [[String : AnyObject]]) {
        studentInformation = []
        
        for location in locations {
            studentInformation.append(StudentInformation(dictionary: location))
        }
    }
}
