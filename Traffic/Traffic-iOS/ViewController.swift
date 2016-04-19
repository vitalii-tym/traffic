//
//  ViewController.swift
//  Traffic-iOS
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var urlSession: NSURLSession!
    var tasks: Tasks? {
        didSet {
            self.view_collectionView.reloadData()
            }
        }
    var aTasktoPass: Task!
    
    @IBOutlet weak var view_collectionView: UICollectionView!
    @IBOutlet weak var button_NewTask: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        let request = NSMutableURLRequest(URL: NSURL(string: "https://fastlane.atlassian.net/rest/api/2/search?jql=assignee=currentUser()+order+by+rank+asc")!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let dataTask: NSURLSessionDataTask = self.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if error == nil && data != nil {
                    self.tasks = Tasks(data: data!)
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
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.urlSession.invalidateAndCancel()
        self.urlSession = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

