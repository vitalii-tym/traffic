//
//  ViewController.swift
//  Traffic-iOS
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class TasksViewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var aProject: Project?
    var aNetworkRequest = JIRANetworkRequest()
    var tasks: JIRATasks? {
        didSet {
            self.view_collectionView.reloadData()
            }
        }
    var aTasktoPass: Task?
    var errors: JIRAerrors?
    var IssueCreationMetadata: JIRAMetadataToCreateIssue?
    var currentUser: JIRAcurrentUser?

    var refreshControl: UIRefreshControl!
    @IBOutlet weak var view_collectionView: UICollectionView!
    @IBOutlet weak var button_NewTask: UIBarButtonItem!
    @IBOutlet weak var button_log_out: UIBarButtonItem!
    @IBOutlet weak var label_no_tasks: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(TasksViewViewController.refresh(_:)),   forControlEvents: UIControlEvents.ValueChanged)
        view_collectionView!.addSubview(refreshControl)
    }

    func refresh(sender:AnyObject) {
        print ("refreshing tasks...")
        let URLEnding = "/rest/api/2/search?jql=project=\(aProject?.key)+AND+status+not+in+(Done)+order+by+rank+asc"
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("do_search", controller: self, data: data, response: response, error: error) {
                self.tasks = JIRATasks(data: data!)
                self.refreshControl.endRefreshing()
            }
        }
        aTasktoPass = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let URLEnding = "/rest/api/2/search?jql=project=\(aProject!.key)+AND+status+not+in+(Done)+order+by+rank+asc"
        if self.tasks == nil {
            self.parentViewController!.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting tasks list...")
        }
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("do_search", controller: self, data: data, response: response, error: error) {
                        self.tasks = JIRATasks(data: data!)
                    }
            self.parentViewController!.stopActivityIndicator()
        }
        aTasktoPass = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Retreiving metadata for issue creation and enabling the "+" button as soon as metadata loading succesful
        let URLEnding = "/rest/api/2/issue/createmeta?expand=projects.issuetypes.fields"
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("get_create_meta", controller: self, data: data, response: response, error: error) {
                self.IssueCreationMetadata = JIRAMetadataToCreateIssue(data: data!)
                // We have got metadata, but to be able to create tasks we still need to know current user, so that we can fill in the "creator" field
                let URLEnding = "/rest/auth/1/session"
                self.aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                    if !anyErrors("current_user", controller: self, data: data, response: response, error: error) {
                        self.currentUser = JIRAcurrentUser(data: data!)
                        self.button_NewTask.enabled = true
                    }
                }
            }
        }
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.tasks != nil {
            label_no_tasks.hidden = !(self.tasks?.taskslist.isEmpty)!
        }
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
        refreshControl.endRefreshing()
        self.performSegueWithIdentifier("issueDetails", sender: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "issueDetails" {
            guard let destionationViewController = segue.destinationViewController as? IssueDetailsViewController else {
                return
            }
            destionationViewController.aTask = self.aTasktoPass
            destionationViewController.IssueCreationMetadata = self.IssueCreationMetadata
            destionationViewController.currentUser = self.currentUser
        }
    }
    
    @IBAction func button_pressed_NewTask(sender: AnyObject) {
        self.performSegueWithIdentifier("issueDetails", sender: nil)
    }
    
    @IBAction func button_pressed_log_out(sender: UIButton) {
        let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
        let userLogin = NSUserDefaults.standardUserDefaults().objectForKey("login") as? String

        self.parentViewController!.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Logging you out...")
        if let hasDomain = domain, hasLogin = userLogin {
            let loginURLsuffix = "/rest/auth/1/session"
            aNetworkRequest.getdata("DELETE", URLEnding: loginURLsuffix, JSON: nil, domain: nil) { (data, response, error) -> Void in
                        let keychainQuery: [NSString: NSObject] = [
                            kSecClass: kSecClassGenericPassword,
                            kSecAttrAccount: hasLogin,
                            kSecAttrService: hasDomain]
                        let keychain_delete_status: OSStatus = SecItemDelete(keychainQuery as CFDictionaryRef)
                        print("Keychain deleting code is: \(keychain_delete_status)")
                        // Logout was succesful, can go back to login screen
                        self.performSegueWithIdentifier("back_to_login", sender: self)
                        self.parentViewController!.stopActivityIndicator()
            }
        } else {
            self.parentViewController!.stopActivityIndicator()
            // Don't know what to do. Looks like user happened to be logged in but for some reason his login or domain were not saved in User Data at all.
            // We can't log user out because we simply don't know the JIRA URL to do this upon.
            // However most probaly he/she will land on the login screen on next app launch because auto-login
            // won't work without valid User Data. So... let's just inform him/her suggesting to relaunch the application.
            let alert: UIAlertController = UIAlertController(title: "Oops", message: "Something weird happened. We can't log you out. But restarting the applicaiton should get you to the login screen.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        aNetworkRequest.cancel()
    }
    
    @IBAction func unwindToTasksList(segue: UIStoryboardSegue) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

