//
//  menuModalViewController.swift
//  AvanticaCalendarBot
//
//  Created by ricardo.guerrero on 8/30/18.
//  Copyright © 2018 Jason Kim. All rights reserved.
//

import UIKit

protocol MenuModalViewControllerDelegate {
    func returnHome()
    func checkLanguague()
}

class menuModalViewController: UIViewController {
    @IBOutlet weak var viewVoice: UIView!
    @IBOutlet weak var viewOptions: UIView!
    @IBOutlet var mainView: UIView!
    @IBOutlet var segmentedLanguage: UISegmentedControl!
    var menuModalDelegate: MenuModalViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard;
        let language: String!;
        language = defaults.string(forKey: "laguange");
        if(language == "ESP"){
            segmentedLanguage.selectedSegmentIndex = 1
        }

        
        
        viewVoice.layer.cornerRadius = 10
        viewOptions.layer.cornerRadius = 10
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.close))
        tapGesture.numberOfTapsRequired = 1
        mainView.addGestureRecognizer(tapGesture)
    }
    
    
    @IBAction func returnButton(_ sender: Any) {
        demiss()
        menuModalDelegate?.returnHome()
        //self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func changeLanguague(_ sender: UISegmentedControl) {
        let defaults = UserDefaults.standard;
        let language: String!;
        language = defaults.string(forKey: "laguange");
        if(language == "ESP"){
            print("ESP changed to ENG")
            defaults.set("ENG", forKey: "laguange")
        }
        else{
            if (language == "ENG"){
                print("ENG changed to ESP")
                defaults.set("ESP", forKey: "laguange")
            }
        }
        menuModalDelegate?.checkLanguague()
    }
    
    
    @IBAction func logOutButton(_ sender: Any) {
        
        demiss()
        let defaults = UserDefaults.standard
        let appId: String!
        defaults.set(nil,forKey: "UserToken");
        menuModalDelegate?.returnHome()
        AuthenticationClass.sharedInstance?.disconnect()
    }
    
    func close(){
        self.dismiss(animated: true, completion: nil)
    }
    
    func demiss(){
        self.dismiss(animated: false, completion: nil)
    }
    func loguout(){
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

}
