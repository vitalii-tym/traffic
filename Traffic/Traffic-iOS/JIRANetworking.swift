//
//  JIRANetworking.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/29/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import Foundation

class JIRANetworkRequest: NSObject {
    var urlSession: NSURLSession {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        return session }
    
    func getdata(request_type: String, URL: String, JSON: String?, completionHandler: (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: URL)!)

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        switch request_type {
            case "POST":
                request.HTTPMethod = request_type
                if JSON != nil {
                request.HTTPBody = JSON!.dataUsingEncoding(NSASCIIStringEncoding)
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
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in completionHandler(data: data, response: response, error: error) })
            
            //-- for debuggin only ---
            print ("Request: \(URL)")
            if (JSON != nil) { print ("JSON: \(JSON!)")
            //-- end of debugging ---
            }
        }
        dataTask.resume()
    }
 
    func cancel() {
        urlSession.invalidateAndCancel()
//      urlSession = nil
    }
    
}