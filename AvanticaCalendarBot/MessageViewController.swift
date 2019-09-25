//
//  MessageViewController.swift
//  AvanticaCalendarBot
//
//  Created by ricardo.guerrero on 8/17/18.
//

import UIKit
import JSQMessagesViewController
import MSAL
import ApiAI
import Speech
import JGProgressHUD
import Alamofire

struct User {
    let id: String;
    let name: String;
}


class MessageViewController: JSQMessagesViewController, SFSpeechRecognizerDelegate, MenuModalViewControllerDelegate {
    
    @IBOutlet weak var OptionsButton: UIBarButtonItem!
    let hud = JGProgressHUD(style: .dark)
    let speechSynthesizer = AVSpeechSynthesizer() //This speechSynthesizer
    public var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!;// language of the voice recognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine() //the engine of the audio framework
    public let voiceButton = UIButton(type: .custom) // the button that trigger the voice record fuction
    var user = User(id: "1", name: "You") //user template information
    var bot = User(id: "2", name: "Bot") //bot fictional user
    var currentUser: User{return user;} // This varaible return the current user of the application
    var messages = [JSQMessage]();//This variable contains all the messages sended during the chat sesion
    var pressState = true;
    
    func startVoiceMessage() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            voiceButton.isEnabled = false
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true;
            print("Start Recording")
        } else {
            startRecording()
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = false;
            print("Stop Recording")
        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try audioSession.setMode(AVAudioSessionModeDefault)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            if result != nil {
                
                self.inputToolbar.contentView.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.voiceButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        print("Say something, I'm listening!")
        
    }
    
    //Button to show Options menu.
    @IBAction func showOptions(_ sender: Any) {
        print("clear chat")
        clearChatMessages()
    }
    
    func returnHome() {
        self.navigationController?.popToRootViewController(animated: true)
    }
}



extension MessageViewController{
    //This functions are in charge of sending the message:
    
    public override func didPressAccessoryButton(_ sender: UIButton!) {
    }

    //Evaluates what happen when the SEND button is pressed
    override func didPressSend(_ button: UIButton!, withMessageText entryText: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        self.inputToolbar.contentView.rightBarButtonItem.isEnabled = false;
        sendMessage(entryText : entryText, addToChat: true)
    }
    
    func sendMessage(entryText : String, addToChat : Bool){
        
        refreshTokenAuth();
        let defaults = UserDefaults.standard;
        let appId = defaults.string(forKey: "AppId");
        let token = defaults.string(forKey: "UserToken");
        print("Token: " + token!);
        print("appId: " + appId!);
        self.sendTokenToHeroku(token : token!, appId : appId!);
        
        let text = entryText;
        let request = ApiAI.shared().textRequest()
        if text != "" {
            hud.textLabel.text = "Loading"
            hud.show(in: self.view)
            
            let message =   JSQMessage(senderId: senderId, displayName: senderDisplayName, text: entryText);
            messages.append(message!);
            
            let defaults = UserDefaults.standard;
            let appId: String!;

            appId = defaults.string(forKey: "AppId");
            request?.query = text;
            print(appId);
            request?.contexts=[appId];
            print (request)
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true;
        } else {
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true;
            return
        }
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            if let textResponse = response.result.fulfillment.speech {
                if(addToChat){
                    self.speechAndText(text: textResponse)
                }
                else{
                    print(textResponse)
                }
            }
        }, failure: { (request, error) in
            print(error!)
        })
        
        ApiAI.shared().enqueue(request)
    }
    
    //This function is in charge of adding the message from dialogflow response to the chat.
    func speechAndText(text: String) {
        let message =   JSQMessage(senderId: "2", displayName: "Bot", text: text);
        messages.append(message!);
        print(message?.text);
        let speechUtterance = AVSpeechUtterance(string : (message?.text.replacingOccurrences(of: "▶", with: ""))!);
        speechSynthesizer.speak(speechUtterance)
        hud.dismiss()
        finishSendingMessage();
    }
}

//------------------------------------------------------------------------
//Sets all the initial variables to star the chat functions
//------------------------------------------------------------------------
extension MessageViewController{
    
    
    
    func back(sender: UIBarButtonItem) {
        // Perform your custom actions
        self.sendMessage(entryText: "cancel event now", addToChat: false);
        speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        AuthenticationClass.sharedInstance?.disconnect()
        
        // Go back to the previous ViewController
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()

        //Hides the option button
        self.OptionsButton.isEnabled=true;
        
        
        //Create and set the new navigation back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Log Out", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        // Set the current user
        self.senderId = currentUser.id;
        self.senderDisplayName = currentUser.name;
    
        self.messages = getMessages()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(voicePress(press:)))
        longPressGesture.minimumPressDuration = 0.3
        voiceButton.addGestureRecognizer(longPressGesture)
        
        let _: Float = Float(inputToolbar.contentView.leftBarButtonContainerView.frame.size.height)
        let image = UIImage(named: "Microphone")
        voiceButton.setImage(image, for: .normal)
        voiceButton.imageView?.contentMode = .scaleAspectFit
        //checks the current language of the voice recorder
        checkLanguague()
        
        
        // Sets the voice recorder button
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MessageViewController.voiceButtonTapped))
        tapGesture.numberOfTapsRequired = 1
        voiceButton.addGestureRecognizer(tapGesture)
        voiceButton.frame = CGRect(x: 0, y: 0, width: 46, height: 36)
        inputToolbar.contentView.leftBarButtonItem.isHidden = true;
        inputToolbar.contentView.leftBarButtonItemWidth = 40
        inputToolbar.contentView.leftBarButtonContainerView.addSubview(voiceButton)
        

        

        //VOICE MESSAGE SETUP
        voiceButton.isEnabled = false
        askVoiceAuth()
    }
    
    func checkLanguague(){
        let defaults = UserDefaults.standard;
        let language: String!;
        language = defaults.string(forKey: "laguange");
        if(language==nil){
            defaults.set("ENG", forKey: "laguange")
        }
        else{
            if(language == "ESP"){
                speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "es-MX"))!
            }
            else{
                speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
            }
        }
    }
    
    func returnToHome(){
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    func voiceButtonTapped() {
        print("Button tapped")
        
    }
    
    //This function is in charge of refresing the autentification token from microsoft graph.
    func refreshTokenAuth() {
        let scopes = ApplicationConstants.kScopes
        
        AuthenticationClass.sharedInstance?.connectToGraph( scopes: scopes) {
            (result: ApplicationConstants.MSGraphError?, accessToken: String) -> Bool  in
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
                    
                    let appId: String!
                    appId = defaults.string(forKey: "AppId")
                    let logInStarted = defaults.string(forKey: "logInStarted")
                        defaults.set(nil, forKey: "logInStarted")
                        if (appId != nil){
                            let token = defaults.string(forKey: "UserToken");
                            print("Token: " + token!);
                            print( "LogInSucessfull")
                        }
                    }
                }
                return true
            }
            
        }
    
    
    func showError(message:String) {
        DispatchQueue.main.async(execute: {
            let alertControl = UIAlertController(title: NSLocalizedString("ERROR", comment: ""), message: message, preferredStyle: .alert)
            alertControl.addAction(UIAlertAction(title: NSLocalizedString("CLOSE", comment: ""), style: .default, handler: nil))
            
            self.present(alertControl, animated: true, completion: nil)
        })
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showModal"){
            (segue.destination as! menuModalViewController).menuModalDelegate = self
        }
        
    }
    
    func drag(control: UIControl, event: UIEvent) {
        if let center = event.allTouches!.first?.location(in: self.view) {
            control.center = center
        }
    }
}

//------------------------------------------------------------------------
//Ask to the user if they give autorization to use their microphone
//------------------------------------------------------------------------
extension MessageViewController{
    //this function is in charge of asking autorization to use the celphone microphone
    func askVoiceAuth() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                print("voice is enabled")
                self.voiceButton.isEnabled = isButtonEnabled
            }
        }
        
    }
    
    //Checks if the voice authorization is set to True:
    //if true: enable voice button.
    //if false: disable voice button
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            voiceButton.isEnabled = true
        } else {
            voiceButton.isEnabled = false
        }
    }
    
    //Checks if voice button is press and trigger "Create New Voice Message"
    func voicePress(press:UILongPressGestureRecognizer){
        if press.state == .began{
            print("long Press began")
            speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
            startVoiceMessage()
            voiceButton.backgroundColor = UIColor.gray
        }
        if press.state == .ended{
            print("long Press ended")
            startVoiceMessage()
            voiceButton.backgroundColor = UIColor.clear
            
        }
    }
}

//------------------------------------------------------------------------
//This extension contains the methods to clear the chat bubbles from the screen.
//------------------------------------------------------------------------
extension MessageViewController{
    func clearChatMessages(){
        messages = []
        collectionView.reloadData()
    }
}


//------------------------------------------------------------------------
//When the application starts create the first message
//------------------------------------------------------------------------
extension MessageViewController{
    func getMessages() -> [JSQMessage]{
        var messages = [JSQMessage]()
        
        let message1 = JSQMessage(senderId: "2", displayName: "Bot", text: "Hello, how i can help you today?\n\nYou can ask me for \"Help\" at any moment.")

        let speechUtterance = AVSpeechUtterance(string : "Hello, how I can help you today?!");
        speechSynthesizer.speak(speechUtterance)
        
        messages.append(message1!);

        return messages
    }
}


//------------------------------------------------------------------------
// this extension contains the request to alamofire to send the token node to the heroku server
//------------------------------------------------------------------------
extension MessageViewController{
    public func sendTokenToHeroku(token: String, appId:String){
        Alamofire.request("https://sjo-calendar-bot.azurewebsites.net/signIn?token_body=\(token)&state=IOS&session_state=\(appId.lowercased())").responseJSON { response in
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }
}

//------------------------------------------------------------------------
// this extension contains all the methods from JSQMessages POD that are in
// charge of editing,creating and send new messages to the chat
//------------------------------------------------------------------------
extension MessageViewController{
    
    //Set te name tag to each message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row];
        let messageUserName = message.senderDisplayName;
        
        return NSAttributedString(string: messageUserName!);
    }
    //
    //Set the size of the Tag message near the chat
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    
    //Sets the image of the message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    //Set the format of the message (Color, and arrow direction)
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory();
        let message = messages[indexPath.row];
        if currentUser.id == message.senderId{
            return bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(red:0.18, green:0.18, blue:0.27, alpha:1.0));
        } else{
            return bubbleFactory?.incomingMessagesBubbleImage(with: UIColor(red:0.24, green:0.68, blue:0.78, alpha:1.0));
        }
    }
    
    //Sets the size of the message lists
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    //Sets the size of the message lists
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
}



