//
//  LoginViewController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/12/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit
import Security
import Foundation

class LoginViewController: UIViewController {
    
    @IBOutlet weak var textfield_domain: UITextField!
    @IBOutlet weak var textfield_login: UITextField!
    @IBOutlet weak var textfield_password: UITextField!
    @IBOutlet weak var button_login: UIButton!
    @IBOutlet weak var switch_remember_me: UISwitch!
    
    var urlSession: NSURLSession!
    var errors: JIRAerrors?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button_login.enabled = false
        textfield_login.addTarget(self, action: #selector(LoginViewController.checkFields(_:)), forControlEvents: .AllEvents)
        textfield_password.addTarget(self, action: #selector(LoginViewController.checkFields(_:)), forControlEvents: .AllEvents)
        
        // Cheking whether there are saved login and pass in User Data and if exists we try to get pass from
        // keychain and automatically login
        let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
        let userLogin = NSUserDefaults.standardUserDefaults().objectForKey("login") as? String
        
        if let hasDomain = domain, hasLogin = userLogin {
            self.textfield_domain.text = hasDomain
            self.textfield_login.text = hasLogin
            let theURL: String = "https://\(hasDomain)"
            
            let keychainQuery: [NSString: NSObject] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: theURL, // we use JIRA URL as service string for Keychain
                kSecAttrAccount: hasLogin,
                kSecReturnData: kCFBooleanTrue,
                kSecMatchLimit: kSecMatchLimitOne]
            var rawResult: AnyObject?
            let keychain_get_status: OSStatus = SecItemCopyMatching(keychainQuery, &rawResult)
            print("Keychain getting code is: \(keychain_get_status)")

            if (keychain_get_status == errSecSuccess) {
                let retrievedData = rawResult as? NSData
                let str = NSString(data: retrievedData!, encoding: NSUTF8StringEncoding)
                let loginParameters: String = "{ \"username\": \"\(hasLogin)\", \"password\": \"\(str!)\" }"
            login(with: loginParameters, and: theURL, save_to_keychain: false)
        } else {
            print("No login data found in Keychain.")
            // We don't autologin in this case and simply leave user on login screen
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.urlSession.invalidateAndCancel()
        self.urlSession = nil
    }
    
    func checkFields(sender: UITextField) {
        sender.text = sender.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
        guard
            let login = textfield_login.text where !login.isEmpty,
            let pass = textfield_password.text where !pass.isEmpty
            else {
                button_login.enabled = false
                switch_remember_me.enabled = false
                return }
        button_login.enabled = true
        switch_remember_me.enabled = true
    }
    
    @IBAction func action_login_pressed(sender: UIButton) {
        let userLogin: String = textfield_login.text!
        let loginParameters: String = "{ \"username\": \"\(userLogin)\", \"password\": \"\(textfield_password.text!)\" }"
        let domain = textfield_domain.text!
        let theURL: String = "https://\(domain)"
        
        // Saving login and URL for user's convenience
        NSUserDefaults.standardUserDefaults().setObject(userLogin, forKey: "login")
        NSUserDefaults.standardUserDefaults().setObject(domain, forKey: "JIRAdomain")
        
        login(with: loginParameters, and: theURL, save_to_keychain: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func login(with logincredentials: String, and domain: String, save_to_keychain: Bool) {
        let loginURLsuffix = "/rest/auth/1/session"
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        let request = NSMutableURLRequest(URL: NSURL(string: domain+loginURLsuffix)!)
        
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = logincredentials.dataUsingEncoding(NSASCIIStringEncoding)!
        
        let dataTask: NSURLSessionDataTask = urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                
                if error == nil && data != nil {
                    let theResponse = response as? NSHTTPURLResponse
                    let responseStatus = theResponse!.statusCode

                    if 200...202 ~= responseStatus {
                        // Authorization succesfull. Great!
                        // Saving login and password into Keychain if the user choose to save it and if it is not saved to Keychain yet
                        if self.switch_remember_me.on == true && save_to_keychain == true {
                            let userAccount = self.textfield_login.text!
                            let passwordData: NSData = self.textfield_password.text!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                            let keychainQuery: [NSString: NSObject] = [
                                kSecClass: kSecClassGenericPassword,
                                kSecAttrAccount: userAccount,
                                kSecAttrService: domain, // we use JIRA URL as service string for Keychain
                                kSecValueData: passwordData]
                            SecItemDelete(keychainQuery as CFDictionaryRef) //Deletes the item just in case it already exists
                            let keychain_save_status: OSStatus = SecItemAdd(keychainQuery as CFDictionaryRef, nil)
                            print("Keychain saving code is: \(keychain_save_status)")
                        }
                        self.performSegueWithIdentifier("afterLogin", sender: nil)
                    } else {
                        // Well, there was a problem with JIRA instance
                        self.errors = JIRAerrors(data: data!, response: theResponse!)

                        let errorCode = self.errors?.errorslist[0].error_code
                        let JIRAerrorMessage = self.errors?.errorslist[0].error_message
                        var errorExplanation = ""

                        switch errorCode! {
                            //There are two possible codes for /rest/auth/1/session call:
                            // 401 - Returned if the login fails due to invalid credentials.
                            // 403 - Returned if the login is denied due to a CAPTCHA requirement, throtting, or any other reason. In case of a 403 status code it is possible that the supplied credentials are valid but the user is not allowed to log in at this point in time.
                            // Documentation: https://developer.atlassian.com/static/rest/jira/5.0.html
                        case 401: errorExplanation = "Check your login and password and try again."
                        case 403: errorExplanation = "Looks like there is a problem with captcha."
                        default: errorExplanation = "Don't know what exactly went wrong. Try again and contact me if you the problem persists."
                        }

                        let alert: UIAlertController = UIAlertController(title: "Oops", message: "JIRA says \"\(JIRAerrorMessage!)\". Code: \(errorCode!). \(errorExplanation)", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }

                } else {
                    // Worst case: we can't even access the JIRA instance.
                    var networkError: String = ""
                    switch error {
                        // There is still a case when there was no error, but we got here because of data == nil
                    case nil: networkError = "Seems there were no error, but the answer from JIRA unexpectedly was empty. Please contact developer to investigate this case."
                    default: networkError = (error?.localizedDescription)!
                    }
                    
                    let alert: UIAlertController = UIAlertController(title: "Oops", message: "\(networkError)", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            })
        }
        dataTask.resume()
    }
    
    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {
    }
}