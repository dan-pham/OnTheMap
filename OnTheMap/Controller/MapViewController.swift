//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Dan Pham on 2/28/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: viewWillAppear Function
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    // MARK: viewWillDisappear Function
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    // MARK: viewDidLoad Function
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let locations = StudentLocation.studentInformation
        var annotations = [MKPointAnnotation]()
        
        for dictionary in locations {
            let lat = CLLocationDegrees(dictionary.latitude ?? 0.0)
            let long = CLLocationDegrees(dictionary.longitude ?? 0.0)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let first = dictionary.firstName ?? ""
            let last = dictionary.lastName ?? ""
            let mediaURL = dictionary.mediaURL
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(first) \(last)"
            annotation.subtitle = mediaURL
            
            annotations.append(annotation)
        }
        self.mapView.addAnnotations(annotations)
    }
    
    // MARK: refreshButton Function
    
    @IBAction func refreshButton(_ sender: Any) {
        ParseClient.sharedInstance().getStudentLocations { (success, error) in
            if success {
                DispatchQueue.main.async {
                    self.loadView()
                    self.viewDidLoad()
                }
            } else {
                DispatchQueue.main.async {
                    self.showError(title: "Refresh Error", message: "Refresh failed")
                }
            }
        }
    }
    
    // MARK: addButton functions
    
    @IBAction func addButton(_ sender: Any) {
        ParseClient.sharedInstance().getUserLocation { (userLocationPosted, success, error) in
            if success {
                if userLocationPosted {
                    DispatchQueue.main.async {
                        self.showOverwriteAlert()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.navigateToInformationPostingVC()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showError(title: "Add Pin Error", message: "Add pin failed")
                }
            }
        }
    }
    
    // Ask user before overwriting their location
    func showOverwriteAlert() {
        let alertVC = UIAlertController(title: "Location Found", message: "Do you want to overwrite it?", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default) {_ in
            self.navigateToInformationPostingVC()
        })
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertVC, animated: true)
    }
    
    // Navigate to InformationPostingViewController
    func navigateToInformationPostingVC() {
        let informationPostingVC = storyboard?.instantiateViewController(withIdentifier: "InformationPostingViewController") as! InformationPostingViewController
        navigationController?.pushViewController(informationPostingVC, animated: true)
    }
    
    // MARK: logoutButton Function
    
    @IBAction func logoutButton(_ sender: Any) {
        UdacityClient.sharedInstance().logout { (success, error) in
            if success {
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.showError(title: "Logout Error", message: "Logout failed")
                }
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
