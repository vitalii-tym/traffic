//
//  LoginViewController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/12/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var textfield_login: UITextField!
    @IBOutlet weak var textfield_password: UITextField!
    @IBOutlet weak var button_login: UIButton!
    
    var urlSession: NSURLSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button_login.enabled = false
        textfield_login.addTarget(self, action: #selector(LoginViewController.checkFields(_:)), forControlEvents: .AllEvents)
        textfield_password.addTarget(self, action: #selector(LoginViewController.checkFields(_:)), forControlEvents: .AllEvents)
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
                return }
        button_login.enabled = true
    }
    
    @IBAction func action_login_pressed(sender: UIButton) {
            print("Login pressed")
            let loginParameters: String = "{ \"username\": \"\(textfield_login.text!)\", \"password\": \"\(textfield_password.text!)\" }"
            login(with: loginParameters)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func login(with logincredentials: String) {
        let jiraURL = "https://fastlane.atlassian.net"
        let loginURLsuffix = "/rest/auth/1/session"
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        let request = NSMutableURLRequest(URL: NSURL(string: jiraURL+loginURLsuffix)!)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = logincredentials.dataUsingEncoding(NSASCIIStringEncoding)!
        
        let dataTask: NSURLSessionDataTask = urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if error == nil && data != nil {
                    self.performSegueWithIdentifier("afterLogin", sender: nil)
                }
            })
        }
        dataTask.resume()
    }
}