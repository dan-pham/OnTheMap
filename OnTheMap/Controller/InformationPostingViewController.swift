//
//  InformationPostingViewController.swift
//  OnTheMap
//
//  Created by Dan Pham on 3/2/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class InformationPostingViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var mediaURLTextField: UITextField!
    @IBOutlet weak var findLocationButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var userLocation: String?
    var userURL: String?
    var latitude: Double?
    var longitude: Double?
    var mapLocation: CLLocation?
    var mapCoordinates: CLLocationCoordinate2D?
    var keyboardOnScreen = false
    var geocoder = CLGeocoder()
    var location: CLLocation?
    
    // MARK: viewWillAppear Function
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setFindLocation(false)
        prepareTextField()
    }
    
    // MARK: cancelButton Function
    
    @IBAction func cancelButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: findLocation functions
    
    @IBAction func findLocation(_ sender: Any) {
        if (locationTextField.hasText && mediaURLTextField.hasText) {
            checkLocation()
        } else if (!locationTextField.hasText && mediaURLTextField.hasText) {
            showFindLocationFailure(message: "Please enter a location")
        } else if (locationTextField.hasText && !mediaURLTextField.hasText) {
            showFindLocationFailure(message: "Please enter a URL")
        } else {
            showFindLocationFailure(message: "Please enter a location and a URL")
        }
    }
    
    // Forward geocode location information
    func checkLocation() {
        geocoder.geocodeAddressString(locationTextField.text!) { (placemark, error) in
            
            // Check for error
            if let error = error {
                self.showFindLocationFailure(message: "Could not geocode location")
                print("Geocoding error: \(error.localizedDescription)")
            } else {
                
                // Otherwise, set the location placemark
                if let placemark = placemark?[0] {
                    self.location = placemark.location
                } else {
                    self.showFindLocationFailure(message: "Could not find placemark")
                    print("Placemark error")
                }
                
                // Referenced from stackoverflow: https://stackoverflow.com/questions/5210535/passing-data-between-view-controllers
                // Pass the location information to the locationDetailViewController
                if let location = self.location {
                    self.setFindLocation(true)
                    self.userLocation = self.locationTextField.text
                    self.userURL = self.mediaURLTextField.text
                    self.latitude = location.coordinate.latitude
                    self.longitude = location.coordinate.longitude
                    self.mapLocation = location
                    self.mapCoordinates = location.coordinate
                    
                    let locationDetailVC = self.storyboard!.instantiateViewController(withIdentifier: "LocationDetailViewController") as! LocationDetailViewController
                    
                    locationDetailVC.userLocation = self.userLocation!
                    locationDetailVC.userURL = self.userURL!
                    locationDetailVC.latitude = self.latitude!
                    locationDetailVC.longitude = self.longitude!
                    locationDetailVC.mapLocation = self.mapLocation!
                    locationDetailVC.mapCoordinates = self.mapCoordinates!
                    self.navigationController?.pushViewController(locationDetailVC, animated: true)
                } else {
                    self.showFindLocationFailure(message: "Could not find location")
                }
            }
        }
    }
    
    // MARK: Activity Indicator Function
    
    func setFindLocation(_ ready: Bool) {
        if ready {
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
        } else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
        }
        locationTextField.isEnabled = !ready
        mediaURLTextField.isEnabled = !ready
        findLocationButton.isEnabled = !ready
    }
    
    // MARK: Alert Function
    
    func showFindLocationFailure(message: String) {
        let alertVC = UIAlertController(title: "Find location failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension InformationPostingViewController: UITextFieldDelegate {
    func prepareTextField() {
        locationTextField.delegate = self
        mediaURLTextField.delegate = self
        locationTextField.text = ""
        mediaURLTextField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}

