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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let URLEnding = "/rest/api/2/project"
        
        self.parentViewController!.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting projects...")

        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
            if !anyErrors("get_projects", controller: self, data: data, response: response, error: error) {
                self.projects = JIRAProjects(data: data!)
            }
            self.parentViewController!.stopActivityIndicator()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("project_сell", forIndexPath: indexPath) as! aProject
        cell.label_name.text = projects?.projectsList[indexPath.row].name
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tasks_list" {
            guard let destionationViewController = segue.destinationViewController as? TasksViewViewController else {
                return
            }
            destionationViewController.aProject = self.aProjectToPass
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        aProjectToPass = (projects?.projectsList[indexPath.row])!
        
       // refreshControl.endRefreshing()
        self.performSegueWithIdentifier("tasks_list", sender: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        aNetworkRequest.cancel()
    }
}