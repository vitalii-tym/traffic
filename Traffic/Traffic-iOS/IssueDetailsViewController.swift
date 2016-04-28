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
        button_change_status.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
                
        let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        let request = NSMutableURLRequest(URL: NSURL(string: "https://\(domain!)/rest/api/2/issue/\(aTask.task_key)/transitions?expand=transitions.fields")!)
        //WARNING: JIRA query hardcoded in the line above - consider moving this logic out
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let dataTask: NSURLSessionDataTask = self.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if !anyErrors("get_transitions", controller: self, data: data, response: response, error: error) {
                    self.availableTransitions = JIRATransitions(data: data!)
                    self.button_change_status.enabled = true
                }
            })
        }
        dataTask.resume()
    }
    
    @IBAction func action_change_status_pressed(sender: AnyObject) {
        let new_photo_actionSheet = UIAlertController(title: "Set status", message: nil, preferredStyle: .ActionSheet)
        
        for transition in (availableTransitions!.transitionsList) {
            new_photo_actionSheet.addAction(UIAlertAction(title: "\(transition.transition_name)", style: .Default, handler: {
                action in
                
                let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
                let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
                self.urlSession = NSURLSession(configuration: configuration)
                let do_transition: String = "{ \"transition\": { \"id\": \"\(transition.transition_id)\" } }"
                
                let request = NSMutableURLRequest(URL: NSURL(string: "https://\(domain!)/rest/api/2/issue/\(self.aTask.task_key)/transitions")!)

                request.HTTPMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.HTTPBody = do_transition.dataUsingEncoding(NSASCIIStringEncoding)!
                let dataTask: NSURLSessionDataTask = self.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        if !anyErrors("do_transition", controller: self, data: data, response: response, error: error) {

                            let alert: UIAlertController = UIAlertController(
                                title: "Success",
                                message: "Status succesfully changed to \(transition.target_status).",
                                preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                                action in
                                self.performSegueWithIdentifier("back_to_tasks", sender: self)
                            }))
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                    })
                }
                dataTask.resume()
            }))
        }
        new_photo_actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(new_photo_actionSheet, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.urlSession.invalidateAndCancel()
        self.urlSession = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
