
import UIKit

/**
 ConnectViewController is responsible for authenticating the user.
 Upon success, open SendMailViewController using predefined segue.
 Otherwise, show an error.
 
 In this sample a user-invoked cancellation is considered an error.
 */
class ConnectViewController: UIViewController {
    
    let pageString = ["create new events", "check coworkers availability", "check your events"]
    var timer : Timer?
    
    // Outlets
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var pageController: UIPageControl!
    
    @IBOutlet weak var textLabelScroll: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(self.pageChanged), userInfo: nil, repeats: true)
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    
    @IBAction func LogOutAction(_ sender: Any) {
        AuthenticationClass.sharedInstance?.disconnect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let pageCount : CGFloat = CGFloat(pageString.count)
        pageController.addTarget(self, action: #selector(self.pageChanged), for: .valueChanged)
        pageController.numberOfPages = Int(pageCount)
        
        
        //connectButton.backgroundColor = .clear
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
        self.timer?.invalidate()
        self.timer = nil
        authenticate()
        
    }
    @IBAction func disconnect(_ sender: AnyObject) {
        AuthenticationClass.sharedInstance?.disconnect()
        self.navigationController?.popViewController(animated: true)
    }
}


private extension ConnectViewController {

    @objc func pageChanged() {
        var pageNumber : Int
        if(pageController.currentPage >= pageString.count-1){
            pageNumber = 0
        }
        else{
            pageNumber = pageController.currentPage + 1
        }
        pageController.currentPage = pageNumber;
        textLabelScroll.text = pageString[pageNumber]
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
                        
                        let defaults = UserDefaults.standard;
    //                    let token = (result?.accessToken)!
    //                        defaults.set(token,forKey: "UserToken");
                        print(accessToken)
                        let appId: String!
                        appId = defaults.string(forKey: "AppId")
                        let logInStarted = defaults.string(forKey: "logInStarted")
                        if(logInStarted == nil){
                            defaults.set("On", forKey: "logInStarted")
                            self.authenticate()
                        }
                        else{
                            defaults.set(nil, forKey: "logInStarted")
                            if (appId != nil){
                                self.performSegue(withIdentifier: "LogInSucessfull", sender: nil)
                            }
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
            let alertControl = UIAlertController(title: NSLocalizedString("ERROR", comment: ""), message: "Log in not sucessfull", preferredStyle: .alert)
            alertControl.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default, handler: nil))
            
            self.present(alertControl, animated: true, completion: nil)
        })
    }
}

