//
//  LocationDetailViewController.swift
//  OnTheMap
//
//  Created by Dan Pham on 3/2/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class LocationDetailViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Properties
    
    var userFirstName: String?
    var userLastName: String?
    var userLocation: String?
    var userURL: String?
    var latitude: Double?
    var longitude: Double?
    var mapLocation: CLLocation?
    var mapCoordinates: CLLocationCoordinate2D?
    var annotation = MKPointAnnotation()
    var geocoder = CLGeocoder()
    var coordinateRegion: MKCoordinateRegion?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var finishButton: UIButton!
    
    // MARK: viewDidLoad Function
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Referenced from stackoverflow: https://stackoverflow.com/questions/4189621/setting-the-zoom-level-for-a-mkmapview
        coordinateRegion = MKCoordinateRegion.init(center: mapCoordinates!, latitudinalMeters: 5000, longitudinalMeters: 5000)
        mapView.setRegion(coordinateRegion!, animated: true)
        annotation.coordinate = mapCoordinates!
        annotation.title = userLocation
        mapView.addAnnotation(annotation)
    }
    
    // MARK: backButton Function
    
    @IBAction func backButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: finishButton Function
    
    @IBAction func finishButton(_ sender: Any) {
        
        // GET request to Udacity API for user's id, first name, and last name
        UdacityClient.sharedInstance().taskForGETRequest(url: UdacityClient.Endpoints.user.url) { (userId, userFirstName, userLastName, success, error) in
            if success {
                
                // POST or PUT request to Parse API depending on user's current location information
                ParseClient.sharedInstance().PostOrPutUserLocation(uniqueKey: userId!, firstName: userFirstName!, lastName: userLastName!, mapString: self.userLocation!, mediaURL: self.userURL!, latitude: self.latitude!, longitude: self.longitude!) { (success, error) in
                    if success {
                        ParseClient.sharedInstance().getStudentLocations(completion: { (success, error) in
                            if success {
                                DispatchQueue.main.async {
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.showError(title: "Posting Error", message: "Could not update new location")
                                }
                            }
                        })
                    } else {
                        DispatchQueue.main.async {
                            self.showError(title: "Posting Error", message: "Could not post new location")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showError(title: "Posting Error", message: "Could not find user information")
                }
                return
            }
        }
    }
    
    // MARK: Alert Function
    
    func showError(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let app = UIApplication.shared
            if let toOpen = view.annotation?.subtitle!, let url = URL(string: toOpen) {
                app.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
