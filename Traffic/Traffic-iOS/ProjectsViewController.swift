//
//  ProjectsViewController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 5/23/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class ProjectsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
 
    var aNetworkRequest = JIRANetworkRequest()
    var projects: JIRAProjects? {
        didSet {
            self.view_projects_list.reloadData()
        }
    }
    var aProjectToPass: Project?
    
    @IBOutlet weak var view_projects_list: UITableView!
    @IBOutlet weak var button_log_out: UIBarButtonItem!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let URLEnding = "/rest/api/2/project"
        
        if projects == nil {
            parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting projects...")
        }

        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("get_projects", controller: self, data: data, response: response, error: error) {
                let projlist = JIRAProjects(data: data!)
                // Manually adding the "All Projects" item to the list
                projlist?.projectsList.insert(Project(id: "", key: "", projectTypeKey: "", name: "All projects", versions: []), atIndex: 0)
                self.projects = projlist
            }
            self.parentViewController?.stopActivityIndicator()
        }
        aProjectToPass = nil
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.projects != nil {
            return self.projects!.projectsList.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("project_сell", forIndexPath: indexPath) as! aProjectCell
        cell.label_name.text = projects?.projectsList[indexPath.row].name
        
        cell.button_expand.tag = indexPath.row
        cell.button_expand.addTarget(self, action: #selector(self.button_expand_pressed(_:)), forControlEvents: .TouchUpInside)
        // We don't need the expand button for "All Projects" type of project (which always goes first in the list)
        if indexPath.row == 0 {
            cell.button_expand.hidden = true
        }
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tasks_list" {
            guard let destionationViewController = segue.destinationViewController as? TasksViewViewController else {
                return
            }
            destionationViewController.aProject = self.aProjectToPass
            destionationViewController.navigationItem.title = self.aProjectToPass?.name
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        aProjectToPass = (projects?.projectsList[indexPath.row])!
        // refreshControl.endRefreshing()
        self.performSegueWithIdentifier("tasks_list", sender: nil)
    }
        
    @IBAction func button_expand_pressed(sender: UIButton) {
        if projects != nil {
            getVersionsForProject(projects!.projectsList[sender.tag])
        }
        print("Adding version to project: \(projects?.projectsList[sender.tag].name)")
    }
    
    func getVersionsForProject(project: Project) {
        let URLEnding = "/rest/api/2/project/\(project.id)/versions"
        parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting versions...")
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("get_versions", controller: self, data: data, response: response, error: error) {
                self.projects?.setVersionsForProject(data!, projectID: project.id)
            }
            self.parentViewController?.stopActivityIndicator()
        }
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
        } else {
            self.parentViewController?.stopActivityIndicator()
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
}