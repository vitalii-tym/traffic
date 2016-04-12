//
//  NetworkController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/12/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import Foundation

let jiraURL = "https://fastlane.atlassian.net"
let loginURLsuffix = "/rest/auth/1/session"
let loginParameters = "{ \"username\": \"admin\", \"password\": \"qwerty123456\" }"
let loginData:NSData = loginParameters.dataUsingEncoding(NSASCIIStringEncoding)!

func login() {

    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    let urlSession = NSURLSession(configuration: configuration)
    
    let request = NSMutableURLRequest(URL: NSURL(string: jiraURL+loginURLsuffix)!)
    request.HTTPMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.HTTPBody = loginData
    
    let dataTask: NSURLSessionDataTask = urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
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
                            print("name: \(cookie.name) value: \(cookie.value)")
                        }
                    }
        }
    }
    dataTask.resume()
}