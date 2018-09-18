/*
* Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license.
* See LICENSE in the project root for license information.
*/

import UIKit

/**
 ConnectViewController is responsible for authenticating the user.
 Upon success, open SendMailViewController using predefined segue.
 Otherwise, show an error.
 
 In this sample a user-invoked cancellation is considered an error.
 */
class ConnectViewController: UIViewController {
    
    
    // Outlets
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        connectButton.backgroundColor = .clear
        connectButton.layer.cornerRadius = 5
        connectButton.layer.borderWidth = 1
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    
    // Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LogInSucessfull" {
          //  let _: SendMailViewController = segue.destination as! SendMailViewController
        }
    }

}

// MARK: Actions
private extension ConnectViewController {
    @IBAction func connect(_ sender: AnyObject) {
        authenticate()
    }
    @IBAction func disconnect(_ sender: AnyObject) {
        AuthenticationClass.sharedInstance?.disconnect()
        self.navigationController?.popViewController(animated: true)
    }
}


// MARK: Authentication
private extension ConnectViewController {
    func authenticate() {
        loadingUI(show: true)
        
        let scopes = ApplicationConstants.kScopes
        
        AuthenticationClass.sharedInstance?.connectToGraph( scopes: scopes) {
            (result: ApplicationConstants.MSGraphError?, accessToken: String) -> Bool  in
            
            defer {self.loadingUI(show: false)}
            
            if let graphError = result {
                switch graphError {
                case .nsErrorType(let nsError):
                    print(NSLocalizedString("ERROR", comment: ""), nsError.userInfo)
                    self.showError(message: NSLocalizedString("CHECK_LOG_ERROR", comment: ""))
                }
                return false
            }
            else {
                // run on main thread!!
                DispatchQueue.main.async {
                    let defaults = UserDefaults.standard
                    let appId: String!
                    appId = defaults.string(forKey: "AppId")
                    if (appId != nil){
                        self.performSegue(withIdentifier: "LogInSucessfull", sender: nil)
                    }
                    
                }
                
                return true
            }
                
        }
    }
}



// MARK: UI Helper
private extension ConnectViewController {
    func loadingUI(show: Bool) {
        if show {
            self.activityIndicator.startAnimating()
            self.connectButton.setTitle(NSLocalizedString("CONNECTING", comment: ""), for: UIControlState())
            self.connectButton.isEnabled = false;
        }
        else {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.connectButton.setTitle(NSLocalizedString("ENTER", comment: ""), for: UIControlState())
                self.connectButton.isEnabled = true;

            }
        }
    }
    
    func showError(message:String) {
        DispatchQueue.main.async(execute: {
            let alertControl = UIAlertController(title: NSLocalizedString("ERROR", comment: ""), message: message, preferredStyle: .alert)
            alertControl.addAction(UIAlertAction(title: NSLocalizedString("CLOSE", comment: ""), style: .default, handler: nil))
            
            self.present(alertControl, animated: true, completion: nil)
        })
    }
}

