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
        
        let service = "Traffic"
        let userAccount = "admin"
        let keychainQuery: [String: AnyObject] =
            [kSecClass as String : kSecClassGenericPassword,
             kSecAttrService as String : service,
             kSecAttrAccount as String : userAccount,
             kSecReturnData as String : kCFBooleanTrue,
             kSecMatchLimit as String : kSecMatchLimitOne]
        var rawResult: AnyObject?
        
        let keychain_get_status: OSStatus = SecItemCopyMatching(keychainQuery, &rawResult)
        
        print("Keychain getting code is: \(keychain_get_status)")

        if (keychain_get_status == errSecSuccess) {
            let retrievedData = rawResult as? NSData
            print("Retrieved the following data from the keychain: \(retrievedData)")
            let str = NSString(data: retrievedData!, encoding: NSUTF8StringEncoding)
            print("The decoded string is \(str)")
            
            
            let loginParameters: String = "{ \"username\": \"\(userAccount)\", \"password\": \"\(str!)\" }"
            let domain: String = "https://\(textfield_domain.text!)"
            
            login(with: loginParameters, and: domain)
            
        } else {
            print("Nothing was retrieved from the keychain.")
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
        login(with: loginParameters, and: domain)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func login(with logincredentials: String, and domain: String) {

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
                    
                    
                    // Saving login and password into Keychain if the user choose to save it
                    if self.switch_remember_me.on == true {
                    
                        let userAccount = self.textfield_login.text!
                        let service = "Traffic"
                        let passwordData: NSData = self.textfield_password.text!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

                        let keychainQuery: [String: AnyObject] =
                                [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrAccount as String: userAccount,
                                kSecAttrService as String: service,
                                kSecValueData as String: passwordData]
                    
                        SecItemDelete(keychainQuery as CFDictionaryRef)
                        let keychain_save_status: OSStatus = SecItemAdd(keychainQuery as CFDictionaryRef, nil)
                        print("Keychain saving code is: \(keychain_save_status)")
                    }

                    self.performSegueWithIdentifier("afterLogin", sender: nil)
                }
            })
        }
        dataTask.resume()
    }
}