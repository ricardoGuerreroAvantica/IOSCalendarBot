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

struct User {
    let id: String;
    let name: String;
}

class MessageViewController: JSQMessagesViewController {

    let speechSynthesizer = AVSpeechSynthesizer()
    
    var user = User(id: "1", name: "User")
    var bot = User(id: "2", name: "Bot")
    var currentUser: User{
        return user;
    }
    
    // Al the message of the chage
    var messages = [JSQMessage]();
}

extension MessageViewController{
    //This functions are in charge of sending the message:
    
    
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

//SET THE MESSAGES
extension MessageViewController{
    override func viewDidLoad(){
        super.viewDidLoad()

        // Set the current user
        self.senderId = currentUser.id;
        self.senderDisplayName = currentUser.name;
        self.navigationController?.isNavigationBarHidden = false;
        self.messages = getMessages()
    }
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

