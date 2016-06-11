//
//  ViewController.swift
//  Traffic-iOS
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.

import UIKit

class aTask: UICollectionViewCell {
    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var label_summary: UILabel!
    @IBOutlet weak var label_priority: UILabel!
    @IBOutlet weak var label_status: UILabel!
    @IBOutlet weak var label_assignee: UILabel!
    @IBOutlet weak var label_type: UILabel!
    @IBOutlet weak var label_description: UILabel!
}

class TasksViewViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIPopoverPresentationControllerDelegate {

    var aProject: Project?
    var aVersion: Version?
    var aBoard: Board?
    var aNetworkRequest = JIRANetworkRequest()
    var tasks: JIRATasks? { didSet { self.view_collectionView.reloadData() } }
    var aTasktoPass: Task?
    var IssueCreationMetadata: JIRAMetadataToCreateIssue?
    var currentUser: JIRAcurrentUser?
    var statusFilter: JIRAStatuses?
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var view_collectionView: UICollectionView!
    @IBOutlet weak var button_NewTask: UIBarButtonItem!
    @IBOutlet weak var label_no_tasks: UILabel!
    @IBOutlet weak var label_context: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: #selector(TasksViewViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        view_collectionView!.addSubview(refreshControl)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.tasks == nil {
            self.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting tasks list...")
        }

        let URLEnding: String = GenerateURLEndingDependingOnContext()
        if let maybeTasksList = NSKeyedUnarchiver.unarchiveObjectWithFile(JIRATasks.path(URLEnding)) as? JIRATasks {
            self.tasks = maybeTasksList
            parentViewController?.stopActivityIndicator()
            regenerateFilter()
        } else {
            aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                if !anyErrors("do_search", controller: self, data: data, response: response, error: error, quiteMode: false) {
                            self.tasks = JIRATasks(data: data!)
                            NSKeyedArchiver.archiveRootObject(self.tasks!, toFile: JIRATasks.path(URLEnding))
                            self.regenerateFilter()
                }
                self.parentViewController?.stopActivityIndicator()
            }
        }
        aTasktoPass = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Retreiving metadata for issue creation and enabling the "+" button as soon as metadata loading succesful
        let URLEnding = "/rest/api/2/issue/createmeta?expand=projects.issuetypes.fields"
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("get_create_meta", controller: self, data: data, response: response, error: error, quiteMode: false) {
                self.IssueCreationMetadata = JIRAMetadataToCreateIssue(data: data!)
                // We have got metadata, but to be able to create tasks we still need to know current user, so that we can fill in the "creator" field
                let URLEnding = "/rest/auth/1/session"
                self.aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                    if !anyErrors("current_user", controller: self, data: data, response: response, error: error, quiteMode: false) {
                        self.currentUser = JIRAcurrentUser(data: data!)
                        self.button_NewTask.enabled = true
                    }
                }
            }
        }
        refresh(nil)
        _ = NSTimer.scheduledTimerWithTimeInterval(420, target: self, selector: #selector(TasksViewViewController.refresh(_:)), userInfo: nil, repeats: true)
    }
    
    func regenerateFilter() {
        if aProject != nil {
            let URLEnding = "/rest/api/2/project/\(aProject!.key)/statuses"
            aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                if !anyErrors("get_statuses", controller: self, data: data, response: response, error: error, quiteMode: false) {
                    self.statusFilter = JIRAStatuses(data: data!)
                }
            }
        }
    }
    
    func GenerateURLEndingDependingOnContext() -> String {
        var URLEnding = ""
        if aProject?.key != "" {
            if aVersion != nil {
                URLEnding = "/rest/api/2/search?jql=project=\(aProject!.key)+AND+fixVersion=\(aVersion!.id)+AND+status+not+in+(Done)+order+by+rank+asc"
                label_context.text = "[\(aVersion!.name)]"
            } else if aBoard != nil {
                URLEnding = "/rest/agile/1.0/board/\(aBoard!.id)/issue?jql=status+not+in+(Done)"
                label_context.text = "[\(aBoard!.name)]"
            } else {
                URLEnding = "/rest/api/2/search?jql=project=\(aProject!.key)+AND+status+not+in+(Done)+order+by+rank+asc"
                label_context.text = "[All issues for project]"
            }
        } else {
            URLEnding = "/rest/api/2/search?jql=status+not+in+(Done)+order+by+rank+asc"
            label_context.text = "[All issues for all projects]"
        }
        return URLEnding
    }
    
    func refresh(sender: AnyObject?) {
        let URLEnding: String = GenerateURLEndingDependingOnContext()
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("do_search", controller: self, data: data, response: response, error: error, quiteMode: false) {
                self.tasks = JIRATasks(data: data!)
                NSKeyedArchiver.archiveRootObject(self.tasks!, toFile: JIRATasks.path(URLEnding))
                self.regenerateFilter()
                self.refreshControl.endRefreshing()
                self.showMessage("refresh succesful", mood: "Good")
            } else {
                self.refreshControl.endRefreshing()
            }
        }
        aTasktoPass = nil
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
        cell.label_summary.text = tasks?.taskslist[indexPath.row].task_summary
        cell.label_assignee.text = tasks?.taskslist[indexPath.row].task_assignee
        cell.label_type.text = tasks?.taskslist[indexPath.row].task_type
        cell.label_description.text = tasks?.taskslist[indexPath.row].task_description
        cell.label_priority.text = tasks?.taskslist[indexPath.row].task_priority
        cell.label_status.text = tasks?.taskslist[indexPath.row].task_status
        switch cell.label_priority.text! {
            case "Highest": cell.label_priority.textColor = UIColor.redColor()
                            cell.label_priority.font = UIFont.boldSystemFontOfSize(12.0)
            case "High":    cell.label_priority.textColor = UIColor.redColor()
            case "Medium":  cell.label_priority.textColor = UIColor.blackColor()
            case "Low":     cell.label_priority.textColor = UIColor.greenColor()
            case "Lowest":  cell.label_priority.textColor = UIColor.grayColor()
            default:        cell.label_priority.textColor = UIColor.blackColor()
        }
        switch cell.label_status.text! {
            case "In Progress": cell.label_status.backgroundColor = UIColor.yellowColor()
            default:        cell.label_status.backgroundColor = UIColor.clearColor()
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
            destionationViewController.aProject = self.aProject
        }
        
        if segue.identifier == "showFilters" {
            guard let destinationViewController = segue.destinationViewController as? FilterViewController else {
                return
            }
            if let unwrappedStatusesList = statusFilter?.statusesList {
                destinationViewController.statusFilter = unwrappedStatusesList
            }
            let popover = destinationViewController.popoverPresentationController
            if popover != nil {
                popover?.delegate = self
                destinationViewController.preferredContentSize = CGSizeMake(200,200)
            }
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    @IBAction func button_pressed_NewTask(sender: AnyObject) {
        self.performSegueWithIdentifier("issueDetails", sender: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        aNetworkRequest.cancel()
    }
    
    @IBAction func unwindToTasksList(segue: UIStoryboardSegue) {
    }
    
    @IBAction func action_open_filters(sender: AnyObject) {
        self.performSegueWithIdentifier("showFilters", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        if let projectToEncode = aProject { Project.encodeForCoder(projectToEncode, coder: coder, index: 1) }
        if let versionToEncode = aVersion { coder.encodeObject(versionToEncode, forKey: "version") }
        if let boardToEncode = aBoard { coder.encodeObject(boardToEncode, forKey: "board") }
        if let aCurrenUserToEncode = currentUser { coder.encodeObject(aCurrenUserToEncode, forKey: "currentUser") }
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        aProject = Project.decode(coder, index: 1)
        aVersion = coder.decodeObjectForKey("version") as? Version
        aBoard = coder.decodeObjectForKey("board") as? Board
        currentUser = coder.decodeObjectForKey("currentUser") as? JIRAcurrentUser
        super.decodeRestorableStateWithCoder(coder)
    }
}