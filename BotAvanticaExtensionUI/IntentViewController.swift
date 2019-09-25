//
//  IntentViewController.swift
//  BotAvanticaExtensionUI
//
//  Created by ricardo.guerrero on 8/23/18.


import IntentsUI

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

class IntentViewController: UIViewController, INUIHostedViewControlling, INUIHostedViewSiriProviding  {
    
    @IBOutlet weak var messageView: UITextView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configure(with interaction: INInteraction!, context: INUIHostedViewContext, completion: ((CGSize) -> Void)!) {
        // Do configuration here, including preparing views and calculating a desired size for presentation.

        let intent = interaction.intent as! INSendMessageIntent

        SendMessage( message : intent.content!);
        
        if let completion = completion {
            completion(self.desiredSize)
        }
    }
    
    var desiredSize: CGSize {
        return CGSize.init(width: 320, height: 320)
    }
    
    //Displays my custom message UI
    
    var displaysMessage: Bool {
        return true
    }
    
}

extension IntentViewController{
    
    func SendMessage(message :String){
        
        let userDefaults = UserDefaults(suiteName: "group.net.avantica.bot.calendar")
        messageView.text = "HEY HERE! \(userDefaults?.string(forKey: "Siri_AppId"))"
        
        
    }
}
