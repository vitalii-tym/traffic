//
//  JIRANetworking.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/29/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import Foundation

class JIRANetworkRequest: NSObject, NSURLSessionDelegate {
    var urlSession: NSURLSession {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:nil)
        return session }
    let domainFromKeychain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(.UseCredential, NSURLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    func getdata(request_type: String, URLEnding: String, JSON: String?, domain: String?, completionHandler: (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void) {
        let URL = ((domain) ?? (domainFromKeychain) ?? "https://") + URLEnding //If we don't know domain it will show some error, but at least won't crash
        let request = NSMutableURLRequest(URL: NSURL(string: URL)!)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        switch request_type {
            case "POST":
                request.HTTPMethod = request_type
                if JSON != nil {
                    request.HTTPBody = JSON!.dataUsingEncoding(NSUTF8StringEncoding)
                } else {
                    print("Error: loks like your are trying to send POST request without providing it with JSON")
                    break
            }
            case "DELETE":
                request.HTTPMethod = request_type
            default:
                break
        }
        
        let dataTask: NSURLSessionDataTask = urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                completionHandler(data: data, response: response, error: error) })
            //-- for debugging only ---
         //    print ("Request: \(URL)")
         //    if (JSON != nil) { print ("JSON: \(JSON!)")
         //   }
            //-- end of debugging ---            
        }
        dataTask.resume()
    }
 
    func cancel() {
        urlSession.invalidateAndCancel()
    }
}