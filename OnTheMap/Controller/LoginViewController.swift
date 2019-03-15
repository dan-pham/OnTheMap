//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Dan Pham on 2/17/19.
//  Copyright © 2019 Dan Pham. All rights reserved.
//

import UIKit
import SafariServices

class LoginViewController: UIViewController {
    
    // MARK: Properties
    
    let signUpUrl = "https://auth.udacity.com/sign-up"
    var keyboardOnScreen = false

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: viewWillAppear Function
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setLoggingIn(false)
        prepareTextField()
    }
    
    // MARK: Log in functions
    
    @IBAction func loginTapped(_ sender: Any) {
        if (emailTextField.hasText && passwordTextField.hasText) {
            setLoggingIn(true)
            let email = emailTextField.text
            let password = passwordTextField.text
            
            UdacityClient.sharedInstance().login(username: email!, password: password!) { (success, error) in
                if success {
                    DispatchQueue.main.async {
                        let controller = self.storyboard!.instantiateViewController(withIdentifier: "completeLogin")
                        self.present(controller, animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.setLoggingIn(false)
                        self.showLoginFailure(message: "Login failed: Your email and/or password is wrong")
                    }
                }
            }
        } else if (!emailTextField.hasText && passwordTextField.hasText) {
            showLoginFailure(message: "Please enter your email")
        } else if (emailTextField.hasText && !passwordTextField.hasText) {
            showLoginFailure(message: "Please enter your password")
        } else {
            showLoginFailure(message: "Please enter your email and password")
        }
    }
    
    // MARK: Sign up functions
    
    @IBAction func signUpTapped(_ sender: Any) {
        signUpUsingSafari(for: signUpUrl)
    }
    
    //Function referenced from Sean Allen's video on YouTube (Swift Tutorial - How to Open a Link in Safari): https://www.youtube.com/watch?v=gnjXbR2eNDE
    func signUpUsingSafari(for url: String) {
        guard let url = URL(string: url) else {
            let alertVC = UIAlertController(title: "Sign up failed", message: nil, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            show(alertVC, sender: nil)
            return
        }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    // MARK: Activity Indicator function
    
    func setLoggingIn(_ loggingIn: Bool) {
        if loggingIn {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        emailTextField.isEnabled = !loggingIn
        passwordTextField.isEnabled = !loggingIn
        loginButton.isEnabled = !loggingIn
        signUpButton.isEnabled = !loggingIn
    }
    
    // MARK: Alert Function
    
    func showLoginFailure(message: String) {
        setLoggingIn(false)
        let alertVC = UIAlertController(title: "Login failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func prepareTextField() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
}
