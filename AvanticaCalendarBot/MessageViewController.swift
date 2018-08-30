//
//  MessageViewController.swift
//  AvanticaCalendarBot
//
//  Created by ricardo.guerrero on 8/17/18.
//  Copyright © 2018 Jason Kim. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MSAL
import ApiAI
import Speech

//The user default structure:
struct User {
    let id: String;
    let name: String;
}

class MessageViewController: JSQMessagesViewController, SFSpeechRecognizerDelegate {

    let speechSynthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    public let voiceButton = UIButton(type: .custom)
    
    var user = User(id: "1", name: "User")
    var bot = User(id: "2", name: "Bot")
    var currentUser: User{
        return user;
    }
    
    // Al the message of the chage
    var messages = [JSQMessage]();
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
    }

    override func viewDidLoad(){
        super.viewDidLoad()
        
        // Set the current user
        self.senderId = currentUser.id;
        self.senderDisplayName = currentUser.name;
        self.navigationController?.isNavigationBarHidden = false;
        self.messages = getMessages()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(voicePress(press:)))
        longPressGesture.minimumPressDuration = 0.3
        voiceButton.addGestureRecognizer(longPressGesture)
        
        let height: Float = Float(inputToolbar.contentView.leftBarButtonContainerView.frame.size.height)
        var image = UIImage(named: "Microphone")
        voiceButton.setImage(image, for: .normal)

        voiceButton.frame = CGRect(x: 10, y: 0, width: 50, height: 35)
        inputToolbar.contentView.leftBarButtonItem.isHidden = true;
        inputToolbar.contentView.leftBarButtonItemWidth = 55
        inputToolbar.contentView.leftBarButtonContainerView.addSubview(voiceButton) 
        
        
        //VOICE MESSAGE SETUP
        voiceButton.isEnabled = false
        
        speechRecognizer.delegate = self
        
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
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            voiceButton.isEnabled = true
        } else {
            voiceButton.isEnabled = false
        }
    }

    
    override func viewDidAppear(_ animated: Bool) {
        inputToolbar.contentView.leftBarButtonContainerView.bringSubview(toFront: voiceButton)
    }
    
    func voicePress(press:UILongPressGestureRecognizer){
        if press.state == .began{
            print("long Press began")
            buttonAction()
            voiceButton.backgroundColor = UIColor.gray
        }
        if press.state == .ended{
            print("long Press ended")
            voiceButton.backgroundColor = UIColor.clear
            buttonAction()
        }
    }
    
    func buttonAction() {

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
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                
                self.inputToolbar.contentView.textView.text = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.voiceButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        print("Say something, I'm listening!")
        
    }

    
    
}

//EXTENSION: API.AI send message
// This extension contains the methods in charge of connect and send messages to API.AI server and receive the feedback:
extension MessageViewController{
    
    //Add the message to the view
    func speechAndText(text: String) {
        let message =   JSQMessage(senderId: "2", displayName: "Bot", text: text);
        messages.append(message!);
        finishSendingMessage();
    }
    
    //Evaluates what happen when the SEND button is pressed
    override func didPressSend(_ button: UIButton!, withMessageText entryText: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let request = ApiAI.shared().textRequest()
        if let text = entryText, text != "" {
            let message =   JSQMessage(senderId: senderId, displayName: senderDisplayName, text: entryText);
            messages.append(message!);

            let defaults = UserDefaults.standard;
            let appId: String!;
            
            appId = defaults.string(forKey: "AppId");
            request?.query = text;
            print(appId);
            request?.contexts=[];
            request?.contexts=[appId];
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
    }
}

//EXTENSION: Voice chat extension
// this extension contains all the methos incharge of sending the new voice message to API.AI
extension MessageViewController{
    
    
}





//CREATE THE FIRST MESSAGES
extension MessageViewController{
    func getMessages() -> [JSQMessage]{
        var messages = [JSQMessage]()
        
        let message1 = JSQMessage(senderId: "2", displayName: "Bot", text: "Hello, how i can help you today?!")

        messages.append(message1!);

        return messages
    }
}

//EXTENSION: MESSAGES JSQMessages
//this extension contains all the methods from JSQMessages POD that are in charge of editing,creating and send new messages to the chat
extension MessageViewController{
    
    //Set te name tag to each message
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row];
        let messageUserName = message.senderDisplayName;
        
        return NSAttributedString(string: messageUserName!);
    }
    
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
            return bubbleFactory?.outgoingMessagesBubbleImage(with: .blue);
        } else{
            return bubbleFactory?.incomingMessagesBubbleImage(with: .blue);
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

//EXTENSION: Audio message
//This extension contains all the code about the voice message manager
extension MessageViewController{
    
}

