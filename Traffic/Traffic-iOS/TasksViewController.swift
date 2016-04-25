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
    
    @IBOutlet weak var view_collectionView: UICollectionView!
    @IBOutlet weak var button_NewTask: UIBarButtonItem!
    @IBOutlet weak var button_log_out: UIBarButtonItem!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        let request = NSMutableURLRequest(URL: NSURL(string: "https://fastlane.atlassian.net/rest/api/2/search?jql=assignee=currentUser()+order+by+rank+asc")!)
            //WARNING: Hardcode in the line above.
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let dataTask: NSURLSessionDataTask = self.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if error == nil && data != nil {
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
        cell.label_name.text = tasks?.taskslist[indexPath.row].task_name
        cell.label_description.text = tasks?.taskslist[indexPath.row].task_summary
        cell.label_priority.text = tasks?.taskslist[indexPath.row].task_priority
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
        let loginURLsuffix = "/rest/auth/1/session"
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        let domain = "https://fastlane.atlassian.net" //WARING: Severe hardcode here. Domain must be taken from user data.
        let request = NSMutableURLRequest(URL: NSURL(string: domain+loginURLsuffix)!)
        request.HTTPMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataTask: NSURLSessionDataTask = urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if error == nil && data != nil {
                    do {
                        let jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject> //to be parsed in future in order to show a reason of an error
                    }
                    catch {  }
                    
                    // Need to parse jsonObject to see whether there some answers from Jira that actually are errors
                    
                    //Deleting users's credentials from Keychain
                    let userAccount = "admin" //WARNING: Hardcode. Cosider taking this data from user data
                    let service = "Traffic" //WARNING: Hardcode. Cosider taking this data from user data
                    
                    let keychainQuery: [NSString: NSObject] = [
                        kSecClass: kSecClassGenericPassword,
                        kSecAttrAccount: userAccount,
                        kSecAttrService: service]
                    let keychain_delete_status: OSStatus = SecItemDelete(keychainQuery as CFDictionaryRef)
                    print("Keychain deleting code is: \(keychain_delete_status)")
                } else {
                    //check here for errors in "error" field
                    
                }
                   self.performSegueWithIdentifier("back_to_login", sender: self)
            })
        }
            dataTask.resume()
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

