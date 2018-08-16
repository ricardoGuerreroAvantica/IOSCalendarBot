//
//  MessageBoxViewController.swift
//  AvanticaCalendarBot
//
//  Created by ricardo.guerrero on 8/14/18.
//  Copyright © 2018 Jason Kim. All rights reserved.
//

import UIKit
import ApiAI
import AVFoundation

class MessageBoxViewController: UIViewController {

    @IBOutlet weak var chipResponse: UITextView!
    @IBOutlet weak var messageField: UITextField!
    var userName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do
        {
            try self.userName = AuthenticationClass.sharedInstance?.authenticationProvider.users()[0].name!
            self.chipResponse.text = "Calendar Bot: \n Hi \(self.userName! )!, how i can help you today?"
            
            
        } catch _ as NSError{
            self.chipResponse.text = "You need to be logged to access my information!";
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //This functions are in charge of sending the message:
    let speechSynthesizer = AVSpeechSynthesizer()
    
    func speechAndText(text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechSynthesizer.speak(speechUtterance)
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseInOut, animations: {
            self.chipResponse.text = self.chipResponse.text+"\n\nCalendar Bot: \n" + text
        }, completion: nil)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        let request = ApiAI.shared().textRequest()
        
        
        
        if let text = self.messageField.text, text != "" {
            self.chipResponse.text = self.chipResponse.text + "\n\(self.userName! ): \n" + text;
            let defaults = UserDefaults.standard;
            let appId = defaults.string(forKey: "AppId");
            request?.query = text + " #### \(appId)";
            request?.name = defaults.string(forKey: "AppId");
            print(request?.name);
        } else {
            return
        }
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            if let textResponse = response.result.fulfillment.speech {
                self.speechAndText(text: textResponse)
            }
        }, failure: { (request, error) in
            print(error!)
        })
        
        ApiAI.shared().enqueue(request)
        messageField.text = ""
    }
    
    
}
