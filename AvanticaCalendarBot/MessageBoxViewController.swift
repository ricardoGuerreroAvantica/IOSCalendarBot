//
//  MessageBoxViewController.swift
//  AvanticaCalendarBot
//
//  Created by ricardo.guerrero on 8/14/18.
//  Copyright © 2018 Jason Kim. All rights reserved.
//

import UIKit

class MessageBoxViewController: UIViewController {

    @IBOutlet weak var chipResponse: UITextView!
    @IBOutlet weak var messageField: UITextField!
    var userName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do
        {
            try self.userName = AuthenticationClass.sharedInstance?.authenticationProvider.users()[0].name!
            self.chipResponse.text = "Calendar Bot: Hi \(self.userName! )!, how i can help you today?"
            
            
        } catch _ as NSError{
            self.chipResponse.text = "You need to be logged to access my information!";
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
