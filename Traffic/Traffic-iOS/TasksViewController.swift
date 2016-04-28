//
//  ViewController.swift
//  Traffic-iOS
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class TasksViewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var urlSession: NSURLSession!
    var tasks: JIRATasks? {
        didSet {
            self.view_collectionView.reloadData()
            }
        }
    var aTasktoPass: Task!
    var errors: JIRAerrors?
    
    @IBOutlet weak var view_collectionView: UICollectionView!
    @IBOutlet weak var button_NewTask: UIBarButtonItem!
    @IBOutlet weak var button_log_out: UIBarButtonItem!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        let request = NSMutableURLRequest(URL: NSURL(string: "https://\(domain!)/rest/api/2/search?jql=assignee=currentUser()+order+by+rank+asc")!)
            //WARNING: JIRA query hardcoded in the line above - consider moving this logic out
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let dataTask: NSURLSessionDataTask = self.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if !anyErrors("do_search", controller: self, data: data, response: response, error: error) {
                        self.tasks = JIRATasks(data: data!)
                    }
            })
        }
        dataTask.resume()
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tasks?.taskslist.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TaskCell", forIndexPath: indexPath) as! aTask
        cell.label_name.text = tasks?.taskslist[indexPath.row].task_key
        cell.label_description.text = tasks?.taskslist[indexPath.row].task_summary
        cell.label_priority.text = tasks?.taskslist[indexPath.row].task_priority
        cell.label_status.text = tasks?.taskslist[indexPath.row].task_status

        switch cell.label_priority.text! {
        case "Highest":
            cell.label_priority.textColor = UIColor.redColor()
            cell.label_priority.font = UIFont.boldSystemFontOfSize(12.0)
        case "High":
            cell.label_priority.textColor = UIColor.redColor()
        case "Medium":
            cell.label_priority.textColor = UIColor.blackColor()
        case "Low":
            cell.label_priority.textColor = UIColor.greenColor()
        case "Lowest":
            cell.label_priority.textColor = UIColor.grayColor()
        default:
            cell.label_priority.textColor = UIColor.blackColor()
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        aTasktoPass = (tasks?.taskslist[indexPath.row])!
        self.performSegueWithIdentifier("issueDetails", sender: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "issueDetails" {
            guard let destionationViewController = segue.destinationViewController as? IssueDetailsViewController else {
                return
            }
            destionationViewController.aTask = aTasktoPass
        }
    }
    
    @IBAction func button_pressed_NewTask(sender: AnyObject) {
        let alert: UIAlertController = UIAlertController(title: "Wait!", message: "This feature is still in construction", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func button_pressed_log_out(sender: AnyObject) {
        logout()
    }
    
    func logout() {
        let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
        let userLogin = NSUserDefaults.standardUserDefaults().objectForKey("login") as? String

        if let hasDomain = domain, hasLogin = userLogin {
            let loginURLsuffix = "/rest/auth/1/session"
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            self.urlSession = NSURLSession(configuration: configuration)
            let theURL = "https://\(hasDomain)"
            let request = NSMutableURLRequest(URL: NSURL(string: theURL+loginURLsuffix)!)
            request.HTTPMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
            let dataTask: NSURLSessionDataTask = urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    if error == nil && data != nil {
                        let theResponse = response as? NSHTTPURLResponse
                        let responseStatus = theResponse!.statusCode
                        // 204 - Returned if the user was successfully logged out.
                        // 401 - Returned if the login fails due to invalid credentials.
                        // Documentation: https://docs.atlassian.com/jira/REST/latest/#auth/1/session-currentUser
                      
                        if 204 ~= responseStatus {
                            //Deleting users's credentials from Keychain
                            let keychainQuery: [NSString: NSObject] = [
                                kSecClass: kSecClassGenericPassword,
                                kSecAttrAccount: hasLogin,
                                kSecAttrService: theURL]
                            let keychain_delete_status: OSStatus = SecItemDelete(keychainQuery as CFDictionaryRef)
                            print("Keychain deleting code is: \(keychain_delete_status)")
                            // Loggin out was succesful, can go back to login screen
                            self.performSegueWithIdentifier("back_to_login", sender: self)
                        } else {
                            // Well, there was a problem with JIRA instance
                            self.errors = JIRAerrors(data: data!, response: theResponse!)
                            
                            let errorCode = self.errors?.errorslist[0].error_code
                            let JIRAerrorMessage = self.errors?.errorslist[0].error_message
                            var errorExplanation = ""
                            
                            switch errorCode! {
                                case 401: errorExplanation = "Looks like you have been logged out already."
                                default: errorExplanation = "Don't know what exactly went wrong. Try again and contact me if you the problem persists."
                            }
                            
                            let alert: UIAlertController = UIAlertController(title: "Oops", message: "JIRA says \"\(JIRAerrorMessage!)\". Code: \(errorCode!). \(errorExplanation)", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            self.presentViewController(alert, animated: true, completion: nil)
                            // But since the user has been already logged out we can also go back to login screen
                            self.performSegueWithIdentifier("back_to_login", sender: self)
                        }
                    } else {
                        // Worst case: we can't even access the JIRA instance.
                        var networkError: String = ""
                        switch error {
                        // There is still a case when there was no error, but we got here because of data == nil
                        case nil: networkError = "Seems there was no error, but the answer from JIRA unexpectedly was empty. Please contact developer to investigate this case."
                        default: networkError = (error?.localizedDescription)!
                        }
                        
                        let alert: UIAlertController = UIAlertController(title: "Oops", message: "\(networkError)", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    
                    }
                })
            }
            dataTask.resume()
        } else {
        // Don't know what to do in this case.
        // Looks like user was logged in but for some reason his login or domain were not saved in User Data at all.
        // We can't log user out because we simply don't know the JIRA URL to do this upon.
        // However most probaly he/she will get stuck on the login screen on next app launch because auto-login
        // won't work without valid User Data.
        // So... let's just ask inform him/her suggesting to relaunch the application.
            
            let alert: UIAlertController = UIAlertController(title: "Oops", message: "Something weird happened. We can't log you out. But restarting the applicaiton should get you to the login screen.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.urlSession.invalidateAndCancel()
        self.urlSession = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func unwindToTasksList(segue: UIStoryboardSegue) {
    }
    
}

