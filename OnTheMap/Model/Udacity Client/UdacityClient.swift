//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Dan Pham on 2/20/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation

class UdacityClient {

    // MARK: Properties
    
    // Authentication variables
    struct Auth {
        static var userId = ""
        static var sessionId = ""
        static var objectId = ""
        static var userFirstName = ""
        static var userLastName = ""
        static var userLocationPosted: Bool = false
    }
    
    // Shared instance
    class func sharedInstance() -> UdacityClient {
        struct Singleton {
            static var sharedInstance = UdacityClient()
        }
        return Singleton.sharedInstance
    }
    
    // Udacity API Endpoints
    enum Endpoints {
        static let base = "https://onthemap-api.udacity.com/v1"
        
        case session
        case user
        
        var stringValue: String {
            switch self {
            case .session:
                return Endpoints.base + "/session"
            case .user:
                return Endpoints.base + "/users/\(Auth.userId)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    // MARK: Login Function
    
    func login(username: String, password: String, completion: @escaping (_ success: Bool, Error?) -> Void) {
        
        // POST user login information to get session ID and authenticate user
        taskForPOSTRequest(url: Endpoints.session.url, username: username, password: password) { (accountKey, sessionId, success, error) in
            if success {
                Auth.userId = accountKey!
                Auth.sessionId = sessionId!
                
                // Get the student locations of the last 100 posts
                ParseClient.sharedInstance().getStudentLocations(completion: { (success, error) in
                    if success {
                        completion(true, nil)
                    } else {
                        completion(false, error)
                    }
                })
            } else {
                completion(false, error)
                print("login request: Unsuccessful POST request")
                return
            }
        }
    }
    
    // MARK: Logout Function
    
    func logout(completion: @escaping (_ success: Bool, Error?) -> Void) {
        
        // HTTP DELETE request to delete cookie for user's session
        var request = URLRequest(url: Endpoints.session.url)
        request.httpMethod = "DELETE"
        var xsrfCookie: HTTPCookie? = nil
        let sharedCookieStorage = HTTPCookieStorage.shared
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(false, error)
                print("logout request: Unable to get data due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300) else {
                completion(false, error)
                print("logout request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(false, error)
                print("logout request: No data was returned")
                return
            }
            
            // Clear the user session ID
            Auth.sessionId = ""
            completion(true, nil)
        }
        task.resume()
    }
    
    // MARK: taskForGETRequest Function
    
    func taskForGETRequest(url: URL, completion: @escaping (_ userId: String?, _ userFirstName: String?, _ userLastName: String?, _ success: Bool, Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(nil, nil, nil, false, error)
                print("GET request: Unable to get public user data due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300) else {
                completion(nil, nil, nil, false, error)
                print("GET request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(nil, nil, nil, false, error)
                print("GET request: No data was returned")
                return
            }
            
            // Skip the first 5 characters from the Udacity API response since these are only there for security purposes and not part of the actual data
            let range = 5 ..< data.count
            let newData = data.subdata(in: range)
            
            // Parse the JSON data into a dictionary
            let parsedData: [String : AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: newData, options: .allowFragments) as! [String : AnyObject]
            } catch {
                completion(nil, nil, nil, false, error)
                print("GET request: Could not parse the JSON data")
                return
            }
            
            // Udacity says that the first 5 characters from all Udacity API responses are security characters so I skipped them, but it seems that there are no security characters or user keys?
            // Check for the user key in the parsed data dictionary
//            guard let userDictionary = parsedData["user"] as? [String : AnyObject] else {
//                completion(nil, nil, nil, false, error)
//                print("GET request: Could not find the \"user\" key in the JSON data")
//                //DEBUG
//                print(String(data: data, encoding: .utf8)!)
//                print(String(data: newData, encoding: .utf8)!)
//                return
//            }
            
            // Set user ID
            guard let userId = Auth.userId as? String else {
                completion(nil, nil, nil, false, error)
                print("GET request: Could not find the \"first_name\" key in the JSON data")
                return
            }
            
            // Check for the first_name key in the user dictionary
            guard let userFirstName = parsedData["first_name"] as? String else {
            //guard let userFirstName = userDictionary["first_name"] as? String else {
                completion(nil, nil, nil, false, error)
                print("GET request: Could not find the \"first_name\" key in the JSON data")
                return
            }
        
            // Check for the last_name key in the user dictionary
            guard let userLastName = parsedData["last_name"] as? String else {
            //guard let userLastName = userDictionary["last_name"] as? String else {
                completion(nil, nil, nil, false, error)
                print("GET request: Could not find the \"last_name\" key in the JSON data")
                return
            }
            
            // If everything is successful, return the user's first name and last name
            completion(userId, userFirstName, userLastName, true, nil)
        }
        task.resume()
    }
    
    // MARK: taskForPOSTRequest Function
    
    func taskForPOSTRequest(url: URL, username: String, password: String, completion: @escaping (_ userId: String?, _ sessionId: String?, _ success: Bool, Error?) -> Void) {
        
        // HTTP POST request to Udacity API to check for correct username and password
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Check for error from the dataTask request
            if error != nil {
                completion(nil, nil, false, error)
                print("POST request: Unable to complete login due to the following error: \(error!.localizedDescription)")
                return
            }
            
            // Check the response from the dataTask request
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (statusCode >= 200 && statusCode < 300)else {
                completion(nil, nil, false, error)
                print("POST request: Unsuccessful status code")
                return
            }
            
            // Check the data from the dataTask request
            guard let data = data else {
                completion(nil, nil, false, error)
                print("POST request: No data was returned")
                return
            }
            
            // Skip the first 5 characters from the Udacity API response since these are only there for security purposes and not part of the actual data
            let range = 5..<data.count
            let newData = data.subdata(in: range)
            
            // Parse the JSON data into a dictionary
            let parsedData: [String : AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: newData, options: .allowFragments) as! [String : AnyObject]
            } catch {
                completion(nil, nil, false, error)
                print("POST request: Could not parse the JSON data")
                return
            }
            
            // Check for the session key in the parsed data dictionary
            guard let sessionDictionary = parsedData["session"] as? [String : AnyObject] else {
                completion(nil, nil, false, error)
                print("POST request: Could not find the \"session\" key in the JSON data")
                return
            }
            
            // Check for the id key in the session dictionary
            guard let sessionId = sessionDictionary["id"] as? String else {
                completion(nil, nil, false, error)
                print("POST request: Could not find the \"id\" key in the JSON data")
                return
            }
            
            // Check for the account key in the parsed data dictionary
            guard let accountDictionary = parsedData["account"] as? [String : AnyObject] else {
                completion(nil, nil, false, error)
                print("POST request: Could not find the \"account\" key in the JSON data")
                return
            }
            
            // Check for the key key in the account dictionary
            guard let accountKey = accountDictionary["key"] as? String else {
                completion(nil, nil, false, error)
                print("POST request: Could not find the \"key\" key in the JSON data")
                return
            }
            
            // If everything is successful, return the account key and the session id
            completion(accountKey, sessionId, true, nil)
        }
        task.resume()
    }
}
