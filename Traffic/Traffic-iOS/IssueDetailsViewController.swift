//
//  IssueDetailsViewController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/13/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class IssueDetailsViewController: UIViewController {
    
    @IBOutlet weak var textview_IssueDetails: UITextView!
    @IBOutlet weak var button_Back: UIBarButtonItem!
    @IBOutlet weak var textview_IssueSummary: UITextView!
    @IBOutlet weak var label_priority: UILabel!
    @IBOutlet weak var label_status: UILabel!
    @IBOutlet weak var button_change_status: UIButton!

    var aTask: Task!
    var urlSession: NSURLSession!
    var errors: JIRAerrors?
    var availableTransitions: JIRATransitions?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textview_IssueSummary.text = aTask.task_summary
        if aTask.task_description != nil
            { textview_IssueDetails.text = aTask.task_description }
        else {
            textview_IssueDetails.text = "(no description)"
            textview_IssueDetails.font = UIFont.italicSystemFontOfSize(12.0)
            }
        label_priority.text = aTask.task_priority
        label_status.text = aTask.task_status
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
                
        let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        let request = NSMutableURLRequest(URL: NSURL(string: "https://\(domain!)/rest/api/2/issue/TEST-18/transitions")!)
        //WARNING: JIRA query hardcoded in the line above - consider moving this logic out
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let dataTask: NSURLSessionDataTask = self.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if error == nil && data != nil {
                    let theResponse = response as? NSHTTPURLResponse
                    let responseStatus = theResponse!.statusCode
                    // STATUS 200 - application/jsonReturns a full representation of the transitions possible for 
                    // the specified issue and the fields required to perform the transition.
                    // STATUS 404 - Returned if the requested issue is not found or the user does not have permission to view it.
                    // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-getTransitions
                    
                    if 200 ~= responseStatus {
                        // Everything is fine, forming the tasks list
                        
                        self.availableTransitions = JIRATransitions(data: data!)
                        
                    } else {
                        // Well, there was a problem with JIRA instance
                        self.errors = JIRAerrors(data: data!, response: theResponse!)
                        var errorExplanation = ""
                        let errorCode = "(empty)"
                        let JIRAerrorMessage = "(empty)"
                        if
                            let errorCode = self.errors?.errorslist[0].error_code,
                            let JIRAerrorMessage = self.errors?.errorslist[0].error_message {
                            
                                switch errorCode {
                                    case 404: errorExplanation = "Could not get transitions list."
                                    default: errorExplanation = "Don't know what exactly went wrong. Try again and contact me if you the problem persists."
                                }
                            } else {
                                errorExplanation = "Something weird happened. Couldn't parse JIRA error codes."
                        }
                        let alert: UIAlertController = UIAlertController(
                            title: "Oops",
                            message: "\(errorExplanation) \n Error code: \(errorCode) \n Message: \(JIRAerrorMessage)",
                            preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    // Looks like we can't access the JIRA instance.
                    var networkError: String = ""
                    switch error {
                    // There is still a case when there was no error, but we got here because of data == nil
                    case nil: networkError = "Seems there was no error, but the answer from JIRA unexpectedly was empty. Please contact developer to investigate this case."
                    default: networkError = (error?.localizedDescription)!
                    }
                    
                    if networkError != "cancelled" {
                        let alert: UIAlertController = UIAlertController(title: "Oops", message: "\(networkError)", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    
                }
            })
        }
        dataTask.resume()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
