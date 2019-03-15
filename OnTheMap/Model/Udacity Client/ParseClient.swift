//
//  ParseClient.swift
//  OnTheMap
//
//  Created by Dan Pham on 3/5/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation

class ParseClient {
    
    // MARK: Properties
    
    // Authentication variables
    struct Auth {
        static var userId = ""
        static var objectId = ""
        static var uniqueKey = ""
        static var userLocationPosted: Bool = false
    }
    
    // Parse Application ID and REST API key
    struct ParseRequest {
        static let applicationId = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
        static let RestApiKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    }
    
    // Shared instance
    class func sharedInstance() -> ParseClient {
        struct Singleton {
            static var sharedInstance = ParseClient()
        }
        return Singleton.sharedInstance
    }
    
    // Parse API Endpoints
    enum Endpoints {
        static let base = "https://parse.udacity.com/parse/classes/StudentLocation"
        
        case getMultipleLocations
        case getSingleLocation
        case post
        case put
        
        var stringValue: String {
            switch self {
            case .getMultipleLocations: return Endpoints.base + "?limit=100&order=-updatedAt"
            case .getSingleLocation: return Endpoints.base + "?where=%7B%22uniqueKey%22%3A%22\(Auth.uniqueKey)%22%7D"
            case .post: return Endpoints.base
            case .put:
                return Endpoints.base + "/\(Auth.objectId)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }

    // MARK: getStudentLocations Function
    
    func getStudentLocations(completion: @escaping (_ success: Bool, Error?) -> Void) {
        
        // Request to get last 100 user locations
        var request = URLRequest(url: Endpoints.getMultipleLocations.url)
        request.addValue(ParseRequest.applicationId, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(ParseRequest.RestApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(false, error)
                print("Parse GET request: Unable to get public user data due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300) else {
                completion(false, error)
                print("Parse GET request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(false, error)
                print("Parse GET request: No data was returned")
                return
            }
            
            // Parse the JSON data into a dictionary
            let parsedData: [String : AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
            } catch {
                completion(false, error)
                print("Parse GET request: Could not parse the JSON data")
                return
            }
            
            // Check for the results key in the parsed data dictionary and store as an array of dictionaries
            guard let resultsDictionary = parsedData["results"] as? [[String : AnyObject]] else {
                completion(false, error)
                print("Parse GET request: Could not find the \"results\" key in the JSON data")
                return
            }
            
            // Store the results as student locations
            StudentLocation.studentLocations(locations: resultsDictionary)
            completion(true, nil)
        }
        task.resume()
    }
    
    // MARK: getUserLocation Function
    
    func getUserLocation(completion: @escaping (_ userLocationPosted: Bool, _ success: Bool, Error?) -> Void) {
        
        // Request to get the user's location
        var request = URLRequest(url: Endpoints.getSingleLocation.url)
        request.addValue(ParseRequest.applicationId, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(ParseRequest.RestApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(false, false, error)
                print("Parse GET single request: Unable to get user data due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300) else {
                completion(false, false, error)
                print("Parse GET single request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(false, false, error)
                print("Parse GET single request: No data was returned")
                return
            }
            
            // Parse the JSON data into a dictionary
            let parsedData: [String : AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
            } catch {
                completion(false, false, error)
                print("Parse GET single request: Could not parse the JSON data")
                return
            }
            
            // Check for the results key in the parsed data dictionary and store as an array of dictionaries
            guard let resultsDictionary = parsedData["results"] as? [[String : AnyObject]] else {
                completion(false, false, error)
                print("Parse GET single request: Could not find the \"results\" key in the JSON data")
                return
            }
            
            // If the current count is 0, the user has not posted a location before.
            if (resultsDictionary.count == 0) {
                completion(false, false, error)
                print("Student has no record on file")
            } else {
                
                // Otherwise, return the user location from the first index of the array
                guard let student = resultsDictionary[0] as? [String : AnyObject] else {
                    completion(false, false, error)
                    print("Parse GET single request: Student information could not be returned")
                    return
                }
                
                // Check for the objectId key in the parsed student dictionary
                guard let objectId = student["objectId"] as? String else {
                    completion(false, false, error)
                    print("Parse GET single request: Could not find the \"objectId\" key in the JSON data")
                    return
                }

                Auth.objectId = objectId
                Auth.userLocationPosted = true
                completion(true, true, nil)
            }
        }
        task.resume()
    }
    
    // MARK: PostOrPutUserLocation Function
    
    func PostOrPutUserLocation(uniqueKey: String, firstName: String, lastName: String, mapString: String, mediaURL: String, latitude: Double, longitude: Double, completion: @escaping (_ success: Bool, Error?) -> Void) {
        
        if Auth.userLocationPosted {
            
            // If the user has a record on file, send a PUT request to update their location
            self.PutUserLocation(objectId: Auth.objectId, uniqueKey: uniqueKey, firstName: firstName, lastName: lastName, mapString: mapString, mediaURL: mediaURL, latitude: latitude, longitude: longitude) { (success, error) in
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        } else {
            
            //Otherwise, send a POST request
            self.PostUserLocation(uniqueKey: uniqueKey, firstName: firstName, lastName: lastName, mapString: mapString, mediaURL: mediaURL, latitude: latitude, longitude: longitude) { (success, error) in
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    // MARK: PutUserLocation Function
    
    func PutUserLocation(objectId: String, uniqueKey: String, firstName: String, lastName: String, mapString: String, mediaURL: String, latitude: Double, longitude: Double, completion: @escaping (_ success: Bool, Error?) -> Void) {
        
        // HTTP PUT request to Parse API
        var request = URLRequest(url: Endpoints.put.url)
        request.httpMethod = "PUT"
        request.addValue(ParseRequest.applicationId, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(ParseRequest.RestApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"uniqueKey\": \"\(uniqueKey)\", \"firstName\": \"\(firstName)\", \"lastName\": \"\(lastName)\",\"mapString\": \"\(mapString)\", \"mediaURL\": \"\(mediaURL)\", \"latitude\": \(latitude), \"longitude\": \(longitude)}".data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(false, error)
                print("Parse PUT request: Unable to update user data due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300) else {
                completion(false, error)
                print("Parse PUT request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(false, error)
                print("Parse PUT request: No data was returned")
                return
            }
            
            // Parse the JSON data into a dictionary
            let parsedData: [String : AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
            } catch {
                completion(false, error)
                print("Parse PUT request: Could not parse the JSON data")
                return
            }
            
            // Check for the updatedAt key in the parsed data dictionary
            guard let putDictionary = parsedData["updatedAt"] as? String else {
                completion(false, error)
                print("Parse PUT request: Could not find the \"updatedAt\" key in the JSON data")
                return
            }
            
            completion(true, nil)
        }
        task.resume()
    }
    
    // MARK: PostUserLocation Function
    
    func PostUserLocation(uniqueKey: String, firstName: String, lastName: String, mapString: String, mediaURL: String, latitude: Double, longitude: Double, completion: @escaping (_ success: Bool, Error?) -> Void) {
        
        // HTTP POST request to Parse API
        var request = URLRequest(url: Endpoints.post.url)
        request.httpMethod = "POST"
        request.addValue(ParseRequest.applicationId, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(ParseRequest.RestApiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"uniqueKey\": \"\(uniqueKey)\", \"firstName\": \"\(firstName)\", \"lastName\": \"\(lastName)\",\"mapString\": \"\(mapString)\", \"mediaURL\": \"\(mediaURL)\", \"latitude\": \(latitude), \"longitude\": \(longitude)}".data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(false, error)
                print("Parse POST request: Unable to update user data due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300) else {
                completion(false, error)
                print("Parse POST request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(false, error)
                print("Parse POST request: No data was returned")
                return
            }
            
            // Parse the JSON data into a dictionary
            let parsedData: [String : AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
            } catch {
                completion(false, error)
                print("Parse POST request: Could not parse the JSON data")
                return
            }
            
            // Check for the updatedAt key in the parsed data dictionary
            guard let postDictionary = parsedData["updatedAt"] as? String else {
                completion(false, error)
                print("Parse POST request: Could not find the \"updatedAt\" key in the JSON data")
                return
            }
            
            completion(true, nil)
        }
        task.resume()
    }
    
}
