//
//  ProjectsViewController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 5/23/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.

import UIKit

class aProjectCell: UITableViewCell {
    @IBOutlet weak var label_name: UILabel!
}

class ProjectsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var aNetworkRequest = JIRANetworkRequest()
    var projects: JIRAProjects? { didSet { view_projects_list.reloadData() } }
    var aProjectToPass: Project?
    var refreshControl: UIRefreshControl = UIRefreshControl()
    @IBOutlet weak var view_projects_list: UITableView!
    @IBOutlet weak var button_log_out: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl.addTarget(self, action: #selector(ProjectsViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        view_projects_list!.addSubview(refreshControl)
        if let archivedCopyOfProjects = NSKeyedUnarchiver.unarchiveObjectWithFile(JIRAProjects.path()) as? JIRAProjects {
            projects = archivedCopyOfProjects
        }
        _ = NSTimer.scheduledTimerWithTimeInterval(420, target: self, selector: #selector(ProjectsViewController.refresh(_:)), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if projects == nil { // "projects" will be absent if this is the first time login or if unarchiving projects was unsuccesful. So user will have to wait a while.
            parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting projects...")
            refresh(nil)
        }
        aProjectToPass = nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects?.projectsList.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let projectCell = tableView.dequeueReusableCellWithIdentifier("project_сell", forIndexPath: indexPath) as! aProjectCell
        projectCell.label_name.text = projects?.projectsList[indexPath.row].name
        return projectCell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tasks_list" {
            guard let destionationViewController = segue.destinationViewController as? TasksViewViewController else { return }
            destionationViewController.aProject = self.aProjectToPass
            destionationViewController.navigationItem.title = self.aProjectToPass?.name
            destionationViewController.caller = self
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        aProjectToPass = projects?.projectsList[indexPath.row]
        self.performSegueWithIdentifier("tasks_list", sender: nil)
    }
    
    @IBAction func action_log_out(sender: UIBarButtonItem) {
        print("logging out")
        let domain = NSUserDefaults.standardUserDefaults().objectForKey("JIRAdomain") as? String
        let userLogin = NSUserDefaults.standardUserDefaults().objectForKey("login") as? String
        
        self.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Logging you out...")
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
                self.parentViewController?.stopActivityIndicator()
            }
        } else {    // Don't know what to do. Looks like user happened to be logged in but for some reason his login or domain were not saved in User Data at all.
                    // We can't log user out because we simply don't know the JIRA URL to do this upon.
                    // However most probaly he/she will land on the login screen on next app launch because auto-login
                    // won't work without valid User Data. So... let's just inform him/her suggesting to relaunch the application.
            self.parentViewController?.stopActivityIndicator()
            let alert: UIAlertController = UIAlertController(title: "Oops", message: "Something weird happened. We can't log you out. But restarting the applicaiton should get you to the login screen.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func refresh(sender: AnyObject?) {
        let URLEnding = "/rest/api/2/project"
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("get_projects", controller: self, data: data, response: response, error: error, quiteMode: false) {
                let projlist = JIRAProjects(data: data)
                // Manually adding the "All Projects" item to the list
                // projlist?.projectsList.insert(Project(id: "", key: "", projectTypeKey: "", name: "All projects", versions: [], boards: []), atIndex: 0)
                self.projects = projlist
                if let unwrappedProjects = self.projects {
                    NSKeyedArchiver.archiveRootObject(unwrappedProjects, toFile: JIRAProjects.path())
                }
                self.refreshControl.endRefreshing()
                self.showMessage("projects up to date", mood: "Good")
                self.parentViewController?.stopActivityIndicator()
            } else {
                self.refreshControl.endRefreshing()
                self.parentViewController?.stopActivityIndicator()
            }
        }
    }
    
    func archiveProjects() {
        if let projects = self.projects {
            NSKeyedArchiver.archiveRootObject(projects, toFile: JIRAProjects.path())
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        aNetworkRequest.cancel()
    }
}