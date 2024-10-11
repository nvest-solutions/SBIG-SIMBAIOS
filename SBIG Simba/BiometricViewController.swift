//
//  BiometricViewController.swift
//  SBIG Simba
//
//  Created by abhilash on 24/09/24.
//

import UIKit
import LocalAuthentication

enum BiometricType {
    case none
    case touch
    case face
}

class BiometricViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let button = UIButton()
        button.frame = CGRect(x: 50, y: 100, width: 100, height: 50)
        //        button.setTitle("Press ME", for: .normal)
        let biometricType = biometricType()
        if biometricType == .face {
            button.setTitle("Face ID", for: .normal)
        } else if biometricType == .touch {
            button.setTitle("Biometry", for: .normal)
        } else {
            button.setTitle("Password", for: .normal)
        }
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        //        button.addTarget(self, action: #selector(self.buttonClicked()), for: .touchUpInside)
        self.view.addSubview(button)
    }
    
}

extension BiometricViewController {
    
    func biometricType() -> BiometricType {
        let authContext = LAContext()
        if #available(iOS 11, *) {
            let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch(authContext.biometryType) {
            case .none:
                return .none
            case .touchID:
                return .touch
            case .faceID:
                return .face
            @unknown default:
                return .none
            }
        } else {
            return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touch : .none
        }
    }
    
    
    @objc func buttonClicked() {
        //Instance of LAContext
        let context = LAContext()
        var error: NSError?
        // checking the device has capability to do so.
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            //explaining the reason for authentication
            let reason = "Touch ID for appName"
            // system biometric check by calling evaluate policy
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                [weak self] success, authenticationError in
                DispatchQueue.main.async{
                    //                    self?.blurView.removeFromSuperview()
                    if success {
                        
                        self?.performSegue(withIdentifier: "HomeView", sender: nil)
                        // Welcome Screen on successful authentication.
                        //  let welcomeVC = ViewController()
                        // self?.navigationController?.pushViewController(welcomeVC,animated:true)
                    } else {
                        //                        Error message for authentication failed
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                        
                        
                    }
                }
            }
        }
        else {
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured forbiometric authentication", preferredStyle: .alert)
            ac.addAction (UIAlertAction(title: "OK", style: .default))
            self.present (ac, animated: true)
        }
    }
}
