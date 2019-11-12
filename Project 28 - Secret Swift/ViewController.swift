//
//  ViewController.swift
//  Project 28 - Secret Swift
//
//  Created by Sean Williams on 12/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var secret: UITextView!
    
    var doneButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "NOTHING TO SEE HERE"
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        
        doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveSecretMessage))
        navigationItem.rightBarButtonItem = doneButton
        doneButton.isEnabled = false
        
    }
    
    
    func unlockSecretMessage() {
        secret.isHidden = false
        title = "Secret Stuff!"
        doneButton.isEnabled = true
        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }
        
        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        doneButton.isEnabled = false
        title = "Nothing to see here!"
    }
    
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEnd = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEnd, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    
    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify Yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        // Show error
                        let ac = UIAlertController(title: "FACE ID Failed", message: "You could not be identified.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            if let password = KeychainWrapper.standard.string(forKey: "Password") {
                                self?.passwordAuthenticate(password: password)
                            } else {
                                self?.passwordAuthenticate(password: nil)
                            }
                        }))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            // No biometry
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
    
    
    func passwordAuthenticate(password: String?) {
        let ac = UIAlertController(title: "Enter Password", message: "If you are a new user, please create a password.", preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            guard let text = ac.textFields?[0].text else { return }
            if password == nil {
                KeychainWrapper.standard.set(text, forKey: "Password")
                self.unlockSecretMessage()
                
            } else if password == text {
                self.unlockSecretMessage()

            } else {
                let ac = UIAlertController(title: "User Authentication Failed", message: "You could not be identified.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
        }))
        
        present(ac, animated: true)
    }
    
}

