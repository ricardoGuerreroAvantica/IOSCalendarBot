//
//  IntentViewController.swift
//  AvanticaCalendarBotExtensionUI
//
//  Created by ricardo.guerrero on 8/24/18.


import IntentsUI
import ApiAI
import AVFoundation

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

class IntentViewController: UIViewController, INUIHostedViewControlling, INUIHostedViewSiriProviding {
    @IBOutlet weak var messageLabel: UILabel!
    var executed = true;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configure(with interaction: INInteraction!, context: INUIHostedViewContext, completion: ((CGSize) -> Void)!) {
        // Do configuration here, including preparing views and calculating a desired size for presentation.
        if(executed){
            let intent = interaction.intent as! INSendMessageIntent
            let message = intent.content
            makeRequestToApiAi(message: message ?? "Vacio")
            
            
            if let completion = completion {
                completion(self.desiredSize)
            }
        }
        
    }
    
    var desiredSize: CGSize {
        return self.extensionContext!.hostedViewMaximumAllowedSize
    }
    
    //Displays my custom message UI
    
    var displaysMessage: Bool {
        return true
    }
    
}

extension IntentViewController{
    //This function checks if the message its empty if not send the message to sendmessage funtion.
    func makeRequestToApiAi(message : String){
        let userDefaultsValue = UserDefaults(suiteName: "group.net.avantica.bot")
        userDefaultsValue?.synchronize()
        
        if (userDefaultsValue?.string(forKey: "SiriAppId") == nil){
            messageLabel.text = "Please autenticate your Microsoft 365 account inside the AvanticaBot Application"
        }
        else{
            sendmessage(message: message, appId: (userDefaultsValue?.string(forKey: "SiriAppId"))!)
        }
    }
    
    
    
    
    
    func speechAndText(text: String) {
        let speechSynthesizer = AVSpeechSynthesizer()
        let speechUtterance = AVSpeechUtterance(string: text)
        speechSynthesizer.speak(speechUtterance)
        print(text)
        print("------------------")
    }
    
    
    //This function its in charge of sending the message to API.Ai
    func sendmessage(message:String, appId: String){
    
        let request = ApiAI.shared().textRequest()
        if (message != "") {
            
            request?.query = message;
            request?.contexts=[];
            request?.contexts=[appId];
            print(appId)
            print(message)
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
        messageLabel.text = "error"
    }
    
}
