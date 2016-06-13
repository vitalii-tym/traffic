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
    var caller: ProjectsViewController?
    var aProject: Project?
    var aVersion: Version?
    var versions: [Version] = []
    var aBoard: Board?
    var aNetworkRequest = JIRANetworkRequest()
    var tasks: JIRATasks?
    var filteredtasks: JIRATasks? { didSet { self.view_collectionView.reloadData() } }
    var aTasktoPass: Task?
    var IssueCreationMetadata: JIRAMetadataToCreateIssue?
    var currentUser: JIRAcurrentUser?
    var statusFilter: JIRAStatuses?
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var view_collectionView: UICollectionView!
    @IBOutlet weak var button_NewTask: UIBarButtonItem!
    @IBOutlet weak var label_no_tasks: UILabel!
    @IBOutlet weak var label_context: UILabel!
    @IBOutlet weak var button_open_filter: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: #selector(TasksViewViewController.tryFetchDataFromNetwork(_:)), forControlEvents: UIControlEvents.ValueChanged)
        view_collectionView!.addSubview(refreshControl)
        button_open_filter.enabled = false
        let isFetchFromCacheSuccesfull = tryFetchDataFromCache()
        if !isFetchFromCacheSuccesfull {
            // If we fail to load at least anything from cache user will have to wait.
            self.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting tasks list...")
        }
        tryFetchDataFromNetwork(isFetchFromCacheSuccesfull)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        aTasktoPass = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Silently retreiving metadata for issue creation and enabling the "+" button as soon as metadata loading succesful
        let URLEnding = "/rest/api/2/issue/createmeta?expand=projects.issuetypes.fields"
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("get_create_meta", controller: self, data: data, response: response, error: error, quiteMode: true) {
                self.IssueCreationMetadata = JIRAMetadataToCreateIssue(data: data!)
                // We have got metadata, but to be able to create tasks we still need to know current user, so that we can fill in the "creator" field
                let URLEnding = "/rest/auth/1/session"
                self.aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                    if !anyErrors("current_user", controller: self, data: data, response: response, error: error, quiteMode: true) {
                        self.currentUser = JIRAcurrentUser(data: data!)
                        self.button_NewTask.enabled = true
                    }
                }
            }
        }
        _ = NSTimer.scheduledTimerWithTimeInterval(420, target: self, selector: #selector(TasksViewViewController.tryFetchDataFromNetwork(_:)), userInfo: nil, repeats: true)
    }
    
    func tryFetchDataFromCache() -> Bool {
        var isResultSuccesful: Bool = false
        if let currentProject = aProject {
            // Trying to load tasks from cache
            let URLEnding: String = GenerateURLEndingDependingOnContext()
            if let maybeTasksList = NSKeyedUnarchiver.unarchiveObjectWithFile(JIRATasks.path(URLEnding)) as? JIRATasks {
                tasks = maybeTasksList
                // If succesfull with tasks trying to load version from cache
                if let maybeVersions = self.caller?.projects?.getVersionsForProject(currentProject.id) {
                    versions = maybeVersions
                    // If we are succesfull with versions we try to load statuses from cache
                    if let maybeStatusesFilter = NSKeyedUnarchiver.unarchiveObjectWithFile(JIRAStatuses.path(currentProject.id)) as? JIRAStatuses {
                        statusFilter = maybeStatusesFilter
                        button_open_filter.enabled = true
                        // If we have everything loaded from cache we apply filters
                        applyFilter()
                        isResultSuccesful = true
                    }
                }
            }
        } else { print("No project in context. Something very bad might have happened.") }
        return isResultSuccesful
    }
    
    func tryFetchDataFromNetwork(sender: AnyObject?) {
        // Trying to fetch and update tasks
        let URLEnding: String = GenerateURLEndingDependingOnContext()
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("do_search", controller: self, data: data, response: response, error: error, quiteMode: false) {
                self.tasks = JIRATasks(data: data!)
                NSKeyedArchiver.archiveRootObject(self.tasks!, toFile: JIRATasks.path(URLEnding))
            } else {
              //  self.showMessage("Failed to load tasks", mood: "Bad")
                self.refreshControl.endRefreshing()
                if sender != nil && sender as? Bool == false {
                    // In case we previously failed to load tasks from cache "sender" will be false
                    // If the network fetch didn't work either it is better to clear the tasks list
                    self.filteredtasks?.taskslist.removeAll()
                    self.view_collectionView.reloadData()
                    self.showMessage("No internet to get tasks and no tasks cached. Sorry.", mood: "Bad")
                    // TODO: Change this little message to some big message telling we can't show the tasks because of Internet absence and we don't have them in cache.
                }
            }
            // As soon as we finished fetching tasks, we try to get and update versions
            if let currentProject = self.aProject {
                let URLEndingForVersions = "/rest/api/2/project/\(currentProject.id)/versions"
                if let parentVC = self.parentViewController where parentVC.isActivityIndicatorActive() == true {
                    // If activity indicator is not running, this means we are doing work in backgrounf and don't need to show furher indicators
                    self.parentViewController?.stopActivityIndicator()
                    self.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting versions...")
                }
                self.aNetworkRequest.getdata("GET", URLEnding: URLEndingForVersions, JSON: nil, domain: nil) { (data, response, error) -> Void in
                    if !anyErrors("get_versions", controller: self, data: data, response: response, error: error, quiteMode: false) {
                        if self.caller != nil {
                            self.caller!.projects?.setVersionsForProject(data!, projectID: currentProject.id)
                            self.caller!.archiveProjects()
                            self.versions = self.caller!.projects!.getVersionsForProject(currentProject.id)
                        }
                    } else {
                      //  self.showMessage("Failed to load versions", mood: "Bad")
                        self.refreshControl.endRefreshing()
                    }
                    // As soon as versions finished we try to get and update statuses
                    let URLEndingForStatuses = "/rest/api/2/project/\(currentProject.id)/statuses"
                    if let parentVC = self.parentViewController where parentVC.isActivityIndicatorActive() == true {
                        self.parentViewController?.stopActivityIndicator()
                        self.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting statuses...")
                    }
                    self.aNetworkRequest.getdata("GET", URLEnding: URLEndingForStatuses, JSON: nil, domain: nil) { (data, response, error) -> Void in
                        if !anyErrors("get_statuses", controller: self, data: data, response: response, error: error, quiteMode: false) {
                            self.statusFilter = JIRAStatuses(data: data!)
                            self.button_open_filter.enabled = true
                            // As soon as we have got new data from JIRA we redraw everything
                            self.applyFilter()
                            self.parentViewController?.stopActivityIndicator()
                            self.refreshControl.endRefreshing()
                            self.showMessage("Tasks list updated", mood: "Good")
                            NSKeyedArchiver.archiveRootObject(self.statusFilter!, toFile: JIRAStatuses.path(currentProject.id))
                        } else {
                            self.parentViewController?.stopActivityIndicator()
                            self.refreshControl.endRefreshing()
                         //   self.showMessage("Failed to load statuses", mood: "Bad")
                        }
                    }
                }
            }
        }
    }

    func applyFilter() {
        var itemsToShow: [String] = [] // Here we'll hold a list of allowed statuses
        let tasksSelectedAsFiltered = JIRATasks.init(tasks: [])
        
        if statusFilter != nil && !statusFilter!.statusesList.isEmpty {
            for status in (statusFilter?.statusesList)! {
                if !itemsToShow.contains(status.0) && status.1 {
                    itemsToShow.append(status.0)
                }
            }
            for aTask in (tasks?.taskslist)! {
                if itemsToShow.contains(aTask.task_status) { // Filtering by status
                    if ((statusFilter?.onlyMyIssues) == true) { // Filtering tasks that assigned only to current user
                        if aTask.task_assigneeInternalName == currentUser?.name {
                            tasksSelectedAsFiltered.taskslist.append(aTask)
                        }
                    } else {
                        tasksSelectedAsFiltered.taskslist.append(aTask)
                    }
                }
            }
            filteredtasks = tasksSelectedAsFiltered
        } else {
            print("couldn't apply filter as it doesn't exist")
        }
    }
    
    func GenerateURLEndingDependingOnContext() -> String {
        var URLEnding = ""
        if aProject?.key != "" {
            if aVersion != nil {
                URLEnding = "/rest/api/2/search?jql=project=\(aProject!.id)+AND+fixVersion=\(aVersion!.id)+order+by+rank+asc&maxResults=200"
                label_context.text = "[\(aVersion!.name)]"
            } else if aBoard != nil {
                URLEnding = "/rest/agile/1.0/board/\(aBoard!.id)/issue"
                label_context.text = "[\(aBoard!.name)]"
            } else {
                URLEnding = "/rest/api/2/search?jql=project=\(aProject!.id)+AND+status+not+in+(Done)+order+by+rank+asc&maxResults=200"
                label_context.text = "[All issues for project]"
            }
        } else {
            URLEnding = "/rest/api/2/search?jql=status+not+in+(Done)+order+by+rank+asc&maxResults=200"
            label_context.text = "[All issues for all projects]"
        }
        return URLEnding
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.filteredtasks != nil { // Showing or hiding the label that says that there are not tasks to show.
            label_no_tasks.hidden = !(self.tasks?.taskslist.isEmpty)!
        }
        var numOfRows = self.filteredtasks?.taskslist.count ?? 0
        if statusFilter != nil && statusFilter!.isActive() { // When filter is active, we add additional cell, which will hold notice to user mentioning that there are filtered items.
            numOfRows += 1
        }
        return numOfRows
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TaskCell", forIndexPath: indexPath) as! aTask
        if indexPath.row < filteredtasks?.taskslist.count {
            cell.backgroundColor = UIColor.lightGrayColor()
            cell.label_name.text = filteredtasks?.taskslist[indexPath.row].task_key
            cell.label_summary.text = filteredtasks?.taskslist[indexPath.row].task_summary
            cell.label_summary.textColor = UIColor.blackColor()
            cell.label_assignee.text = filteredtasks?.taskslist[indexPath.row].task_assigneeDisplayName
            cell.label_type.text = filteredtasks?.taskslist[indexPath.row].task_type
            cell.label_description.text = filteredtasks?.taskslist[indexPath.row].task_description
            cell.label_priority.text = filteredtasks?.taskslist[indexPath.row].task_priority
            cell.label_status.text = filteredtasks?.taskslist[indexPath.row].task_status
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
        } else {
            cell.backgroundColor = UIColor.clearColor()
            cell.label_summary.text = "Please check filter, as there might be more items hidden."
            cell.label_summary.textColor = UIColor.lightGrayColor()
            cell.label_name.text = ""
            cell.label_assignee.text = ""
            cell.label_type.text = ""
            cell.label_description.text = ""
            cell.label_priority.text = ""
            cell.label_status.text = ""
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        aTasktoPass = (filteredtasks?.taskslist[indexPath.row])!
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
            destinationViewController.caller = self
            let popover = destinationViewController.popoverPresentationController
            if popover != nil && statusFilter != nil {
                popover?.delegate = self
                let popoverHeight: CGFloat = min(CGFloat(statusFilter!.statusesList.count * 44 + 95), view_collectionView.frame.height) // WARNING: Hardcoded popover height here
                destinationViewController.preferredContentSize = CGSizeMake(280,popoverHeight)
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