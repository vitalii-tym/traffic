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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button_login.enabled = false
        textfield_login.addTarget(self, action: #selector(LoginViewController.checkFields(_:)), forControlEvents: .AllEvents)
        textfield_password.addTarget(self, action: #selector(LoginViewController.checkFields(_:)), forControlEvents: .AllEvents)
        
        //Cheking whether there are saved login and pass
        let service = "Traffic"   //WARNING: Hardcode here. Consider saving in user data.
        let userAccount = "admin" //WARNING: Hardcode here. Consider saveing in user data.
        let keychainQuery: [NSString: NSObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: userAccount,
            kSecReturnData: kCFBooleanTrue,
            kSecMatchLimit: kSecMatchLimitOne]
        var rawResult: AnyObject?
        let keychain_get_status: OSStatus = SecItemCopyMatching(keychainQuery, &rawResult)
        print("Keychain getting code is: \(keychain_get_status)")

        if (keychain_get_status == errSecSuccess) {
            let retrievedData = rawResult as? NSData
            let str = NSString(data: retrievedData!, encoding: NSUTF8StringEncoding)
            let loginParameters: String = "{ \"username\": \"\(userAccount)\", \"password\": \"\(str!)\" }"
            let domain: String = "https://\(textfield_domain.text!)" // WARNING: the field is supposed to be epty. Consider taking this info from user data instead.
            login(with: loginParameters, and: domain, save_to_keychain: false)
        } else {
            print("No login data found in Keychain.")
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
        let loginParameters: String = "{ \"username\": \"\(textfield_login.text!)\", \"password\": \"\(textfield_password.text!)\" }"
        let domain: String = "https://\(textfield_domain.text!)"
        login(with: loginParameters, and: domain, save_to_keychain: true)
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
                    do {
                        let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject> //to be parsed in future in order to show a reason of an error
                    }
                    catch {  }
                    
                    // Saving login and password into Keychain if the user choose to save it and if it is not saved to Keychain yet
                    if self.switch_remember_me.on == true && save_to_keychain == true {
                        let userAccount = self.textfield_login.text!
                        let service = "Traffic" //WARNING: Hardcode here. Consider using app name BundleID
                        let passwordData: NSData = self.textfield_password.text!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

                        let keychainQuery: [NSString: NSObject] = [
                            kSecClass: kSecClassGenericPassword,
                            kSecAttrAccount: userAccount,
                            kSecAttrService: service,
                            kSecValueData: passwordData]
                    
                        SecItemDelete(keychainQuery as CFDictionaryRef) //Deletes the item just in case it already exists
                        let keychain_save_status: OSStatus = SecItemAdd(keychainQuery as CFDictionaryRef, nil)
                        print("Keychain saving code is: \(keychain_save_status)")
                    }

                    self.performSegueWithIdentifier("afterLogin", sender: nil)
                }
            })
        }
        dataTask.resume()
    }
    
    
    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {
    
    }
}