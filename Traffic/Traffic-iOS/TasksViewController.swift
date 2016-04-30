//
//  ViewController.swift
//  Traffic-iOS
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class TasksViewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var aNetworkRequest = JIRANetworkRequest()
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
    
        let URLEnding = "/rest/api/2/search?jql=assignee=currentUser()+order+by+rank+asc"
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil) { (data, response, error) -> Void in
            if !anyErrors("do_search", controller: self, data: data, response: response, error: error) {
                        self.tasks = JIRATasks(data: data!)
                    }
        }
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
    
    @IBAction func button_pressed_log_out(sender: UIButton) {
        let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
        let userLogin = NSUserDefaults.standardUserDefaults().objectForKey("login") as? String

        if let hasDomain = domain, hasLogin = userLogin {
            let loginURLsuffix = "/rest/auth/1/session"
            let baseURL = "https://\(hasDomain)"
          //  let URL = baseURL + loginURLsuffix
            aNetworkRequest.getdata("DELETE", URLEnding: loginURLsuffix, JSON: nil) { (data, response, error) -> Void in
                        let keychainQuery: [NSString: NSObject] = [
                            kSecClass: kSecClassGenericPassword,
                            kSecAttrAccount: hasLogin,
                            kSecAttrService: baseURL]
                        let keychain_delete_status: OSStatus = SecItemDelete(keychainQuery as CFDictionaryRef)
                        print("Keychain deleting code is: \(keychain_delete_status)")
                        // Logout was succesful, can go back to login screen
                        self.performSegueWithIdentifier("back_to_login", sender: self)
            }
        } else {
        // Don't know what to do in this case.
        // Looks like user happened to be logged in but for some reason his login or domain were not saved in User Data at all.
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func unwindToTasksList(segue: UIStoryboardSegue) {
    }
    
}

