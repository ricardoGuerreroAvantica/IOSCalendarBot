//  AuthenticationClass.swift
//  Graph-iOS-Swift-Connect

import Foundation
import MSAL
import UIKit
import Alamofire

class AuthenticationClass {
    
    // MARK: Properties and variables
    // Singleton class
    class var sharedInstance: AuthenticationClass? {
        struct Singleton {
            static let instance = AuthenticationClass.init()
        }
        return Singleton.instance
    }

    var authenticationProvider = MSALPublicClientApplication.init()
    var accessToken: String = ""
    var refreshToken: String = ""
    
    var lastInitError: String? = ""
    
    init () {

        do {
            
            //Get the MSAL client Id for this Azure app registration. We store it in the main bundle
            var redirectUrl: String = "";
            var myDict: NSDictionary?
            if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
                myDict = NSDictionary(contentsOfFile: path)
            }
            if let dict = myDict {
                let array: NSArray =  (dict.object(forKey: "CFBundleURLTypes") as? NSArray)!;
                redirectUrl = getRedirectUrlFromMSALArray(array: array);
            }
            //  var NSRange range = [redirectUrl rangeOfString:@"msal"];
            let range: Range<String.Index> = redirectUrl.range(of: "msal")!;
            let kClientId: String = redirectUrl.substring(from: range.upperBound);
            
            authenticationProvider = try MSALPublicClientApplication.init(clientId: kClientId, authority: ApplicationConstants.kAuthority)
        } catch  let error as NSError  {
            self.lastInitError = error.userInfo.description
            authenticationProvider = MSALPublicClientApplication.init()
        }
    }
    /**
     Authenticates to Microsoft Graph.
     If a user has previously signed in before and not disconnected, silent log in
     will take place.
     If not, authentication will ask for credentials
     */
    func connectToGraph(scopes: [String],
                        completion:@escaping (_ error: ApplicationConstants.MSGraphError?, _ accessToken: String) -> Bool)  {
        
        do {
            if let initError = self.lastInitError {
                if initError.lengthOfBytes(using: String.Encoding.ascii) > 1 {
                    throw NSError.init(domain: initError, code: 0, userInfo: nil)
                }
            }
            // We check to see if we have a current logged in user. If we don't, then we need to sign someone in.
            // We throw an interactionRequired so that we trigger the interactive signin.
            
            if  try authenticationProvider.users().isEmpty {
                throw NSError.init(domain: "MSALErrorDomain", code: MSALErrorCode.interactionRequired.rawValue, userInfo: nil)
            } else {
                
                // Acquire a token for an existing user silently
                
                try authenticationProvider.acquireTokenSilent(forScopes: scopes, user: authenticationProvider.users().first) { (result, error) in
                    
                    if error == nil {
                        let defaults = UserDefaults.standard;
                        self.accessToken = (result?.accessToken)!
                        _ = completion(nil, self.accessToken);
                        
                        
                        defaults.set(self.accessToken,forKey: "UserToken");

                        if (defaults.string(forKey: "AppId")==nil){
                            defaults.set(UUID().uuidString,forKey: "AppId");
                        }
                        print(defaults.string(forKey: "AppId")!)
                        print(defaults.string(forKey: "UserToken")!)
                        self.sendTokenToHeroku(token: defaults.string(forKey: "UserToken")!, appId: defaults.string(forKey: "AppId")!)
                        
                    } else {
                        self.disconnect()
                        //"Could not acquire token silently: \(error ?? "No error information" as! Error )"
                       var _ = completion(ApplicationConstants.MSGraphError.nsErrorType(error: error! as NSError), "");
                        
                    }
                }
            }
        }  catch let error as NSError {
            
            // interactionRequired means we need to ask the user to sign-in. This usually happens
            // when the user's Refresh Token is expired or if the user has changed their password
            // among other possible reasons.
            
            if error.code == MSALErrorCode.interactionRequired.rawValue {
                
                authenticationProvider.acquireToken(forScopes: scopes) { (result, error) in
                    if error == nil {
                        self.accessToken = (result?.accessToken)!
                        var _ = completion(nil, self.accessToken);
                        
                        
                    } else  {
                        var _ = completion(ApplicationConstants.MSGraphError.nsErrorType(error: error! as NSError), "");
                        
                    }
                }
                
            } else {
                var _ = completion(ApplicationConstants.MSGraphError.nsErrorType(error: error as NSError), error.localizedDescription);

            }
            
        } catch {
            
            // This is the catch all error.
            
            
            var _ = completion(ApplicationConstants.MSGraphError.nsErrorType(error: error as NSError), error.localizedDescription);
            
        }
    }
    func disconnect() {
        
        do {
            try authenticationProvider.remove(authenticationProvider.users().first)
            
        } catch _ {
            print("log out fail");
        }
        
    }
    
    // Get client id from bundle
    
    func getRedirectUrlFromMSALArray(array: NSArray) -> String {
        let arrayElement: NSDictionary = array.object(at: 0) as! NSDictionary;
        let redirectArray: NSArray = arrayElement.value(forKeyPath: "CFBundleURLSchemes") as! NSArray;
        let subString: NSString = redirectArray.object(at: 0) as! NSString;
        return subString as String;
    }

    
    func sendTokenToHeroku(token: String, appId:String){
        let parameters = [
            "token_body" : token,
            "state" : "mobile",
            "session_state" : appId.lowercased()
        ]
        
        Alamofire.request("https://sjo-calendar-bot.azurewebsites.net/signIn", method: .post, parameters: parameters).responseJSON { response in
            guard case let .failure(error) = response.result else { return }
            
            if let error = error as? AFError {
                switch error {
                case .invalidURL(let url):
                    print("Invalid URL: \(url) - \(error.localizedDescription)")
                case .parameterEncodingFailed(let reason):
                    print("Parameter encoding failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                case .multipartEncodingFailed(let reason):
                    print("Multipart encoding failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                case .responseValidationFailed(let reason):
                    print("Response validation failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                    
                    switch reason {
                    case .dataFileNil, .dataFileReadFailed:
                        print("Downloaded file could not be read")
                    case .missingContentType(let acceptableContentTypes):
                        print("Content Type Missing: \(acceptableContentTypes)")
                    case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                        print("Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)")
                    case .unacceptableStatusCode(let code):
                        print("Response status code was unacceptable: \(code)")
                    }
                case .responseSerializationFailed(let reason):
                    print("Response serialization failed: \(error.localizedDescription)")
                    print("Failure Reason: \(reason)")
                }
                
                print("Underlying error: \(error.underlyingError)")
            } else if let error = error as? URLError {
                print("URLError occurred: \(error)")
            } else {
                print("Unknown error: \(error)")
            }
            
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }

}
