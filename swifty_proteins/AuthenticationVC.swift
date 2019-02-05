//
//  AuthenticationVC.swift
//  swifty_proteins
//
//  Created by Nyameko RARANE on 2019/01/31.
//  Copyright © 2019 Nyameko RARANE. All rights reserved.
//

import UIKit
import LocalAuthentication

class AuthenticationVC: UIViewController {

    @IBOutlet weak var usernameLabel: UITextField!
    @IBOutlet weak var passwordLabel: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBAction func _login(_ sender: Any) {
        
    }
    
    @IBAction func touchIDButton(_ sender: Any) {
        let context:LAContext = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Please login using touchID", reply: {(success, error) in
                if success {
                    self.navigateToAuthenticatedVC()
                } else {
                    if let error = error as NSError? {
                        let message = self.errorMessageForLAErrorCode(errorCode: error.code)
                        self.showAlertViewAfterEvaluatingPolicyWithMessage(message: message)
                    }
                }
            })
        } else {
            showAlertForNoBio()
            return
        }
    }
    
    func showAlertViewAfterEvaluatingPolicyWithMessage(message: String) {
        showAlertWithTitle(title: "Error", message: message)
    }
    
    func errorMessageForLAErrorCode(errorCode: Int) -> String {
        var message = ""
        
        switch errorCode {
        case LAError.appCancel.rawValue:
            message = "Authentication cancelled by app"
        case LAError.authenticationFailed.rawValue:
            message = "Invalid user credentials"
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode not set on device"
        case LAError.systemCancel.rawValue:
            message = "Authentication cancelled by system"
        case LAError.biometryLockout.rawValue:
            message = "Too many failed attempts"
        case LAError.biometryNotAvailable.rawValue:
            message = "TouchID not available on device"
        case LAError.userCancel.rawValue:
            message = "Operation cancelled by user"
        case LAError.userFallback.rawValue:
            message = "User chose to fallback"
        default:
            message = "Unknown Error"
        }
        return message
    }
    
    func navigateToAuthenticatedVC() {
        if let loggedInVC = storyboard?.instantiateViewController(withIdentifier: "LoggedInVC") {
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(loggedInVC, animated: true)
            }
        }
    }
    
    func showAlertForNoBio() {
        showAlertWithTitle(title: "Error", message: "No touchID sensor")
    }
    
    func showAlertWithTitle(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertVC.addAction(okAction)
        
        DispatchQueue.main.async {
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
