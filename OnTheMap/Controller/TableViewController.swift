//
//  TableViewController.swift
//  OnTheMap
//
//  Created by Dan Pham on 3/2/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import Foundation
import UIKit

class TableViewController: UITableViewController {
    
    // MARK: Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.reloadData()
    }
    
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
        let informationPostingVC = self.storyboard!.instantiateViewController(withIdentifier: "InformationPostingViewController") as! InformationPostingViewController
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
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StudentLocation.studentInformation.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let studentLocation: StudentInformation = StudentLocation.studentInformation[(indexPath as NSIndexPath).row]
        
        let row = tableView.dequeueReusableCell(withIdentifier: "StudentTableViewCell")!
        
        let firstName = studentLocation.firstName ?? ""
        let lastName = studentLocation.lastName ?? ""
        let mediaURL = studentLocation.mediaURL ?? ""
        
        row.textLabel?.text = "\(firstName) \(lastName)"
        row.detailTextLabel?.text = mediaURL
    
        return row
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let toOpen = StudentLocation.studentInformation[(indexPath as NSIndexPath).row].mediaURL, let url = URL(string: toOpen) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
