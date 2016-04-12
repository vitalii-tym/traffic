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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button_login.enabled = false
        textfield_password.addTarget(self, action: #selector(LoginViewController.checkFields(_:)), forControlEvents: .EditingDidEnd)
        textfield_login.addTarget(self, action: #selector(LoginViewController.checkFields(_:)), forControlEvents: .EditingDidEnd)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func checkFields(sender: UITextField) {
        sender.text = sender.text?.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
        guard
            let login = textfield_login.text where !login.isEmpty,
            let pass = textfield_password.text where !pass.isEmpty
            else { return }
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
        let urlSession = NSURLSession(configuration: configuration)
        let request = NSMutableURLRequest(URL: NSURL(string: jiraURL+loginURLsuffix)!)
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = logincredentials.dataUsingEncoding(NSASCIIStringEncoding)!
        
        let dataTask: NSURLSessionDataTask = urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if error == nil && data != nil {
                    let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("Body: \(strData)")
                    
                    if let httpResponse = response as? NSHTTPURLResponse,
                        let fields = httpResponse.allHeaderFields as? [String : String]
                    {
                        let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(fields, forURL: response!.URL!)
                        NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies(cookies, forURL: response!.URL!, mainDocumentURL: nil)
                        for cookie in cookies {
                            var cookieProperties = [String: AnyObject]()
                            cookieProperties[NSHTTPCookieName] = cookie.name
                            cookieProperties[NSHTTPCookieValue] = cookie.value
                            cookieProperties[NSHTTPCookieDomain] = cookie.domain
                            cookieProperties[NSHTTPCookiePath] = cookie.path
                            cookieProperties[NSHTTPCookieVersion] = NSNumber(integer: cookie.version)
                            cookieProperties[NSHTTPCookieExpires] = NSDate().dateByAddingTimeInterval(31536000)
                            let newCookie = NSHTTPCookie(properties: cookieProperties)
                            NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(newCookie!)
                            
                            self.performSegueWithIdentifier("afterLogin", sender: nil)
                            
                            print("name: \(cookie.name) value: \(cookie.value)")
                        }
                    }
                }
            })
        }
        
        dataTask.resume()
    }
}