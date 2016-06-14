//
//  FilterViewController.swift
//  Easy Jira
//
//  Created by Vitaliy Tim on 6/10/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class aStatusFilterCell: UITableViewCell {
    @IBOutlet weak var label_status_filter: UILabel!
}

class aChooseVersionCell: UITableViewCell {
    @IBOutlet weak var label_version_name: UILabel!
}

class ChooseVersionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var caller: TasksViewViewController?
    var lastSelectedVersionIndexPath: NSIndexPath?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numOfVersionsInList = caller?.aProject!.versions.count {
            return (numOfVersionsInList + 1)
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChooseVersionCell", forIndexPath: indexPath) as! aChooseVersionCell
        if indexPath.row != 0 {
            cell.label_version_name.text = caller?.aProject?.versions[indexPath.row - 1].name
            if cell.label_version_name.text == caller?.aVersion?.name {
                cell.accessoryType = .Checkmark
                lastSelectedVersionIndexPath = indexPath
            }
        } else {
            cell.label_version_name.text = "(all versions)"
            if caller?.aVersion == nil {
                cell.accessoryType = .Checkmark
                lastSelectedVersionIndexPath = indexPath
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            caller?.aVersion = nil
        } else {
            caller?.aVersion = caller?.aProject!.versions[indexPath.row - 1]
        }
        if lastSelectedVersionIndexPath != nil {
            tableView.reloadRowsAtIndexPaths([lastSelectedVersionIndexPath!, indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        } else {
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
        caller?.applyFilter()
        caller?.view_collectionView.reloadData()
        performSegueWithIdentifier("backToFilter", sender: self)
    }
}

class FilterViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    var caller: TasksViewViewController?
    
    @IBOutlet weak var table_statuses: UITableView!
    @IBOutlet weak var switch_my_issues_only: UISwitch!
    @IBOutlet weak var label_version_name: UILabel!
    
    override func viewDidLoad() {
        if self.preferredContentSize.height == caller?.view_collectionView.frame.height {
            table_statuses.scrollEnabled = true
        } else {
            table_statuses.scrollEnabled = false
        }
        switch_my_issues_only.on = (caller?.statusFilter?.onlyMyIssues)!
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if caller?.aVersion != nil {
            label_version_name.text = caller?.aVersion?.name
            label_version_name.font = UIFont.systemFontOfSize(15)
        } else {
            label_version_name.text = "(all versions)"
            label_version_name.font = UIFont.italicSystemFontOfSize(12)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return caller?.statusFilter?.statusesList.count ?? 0
    }
        
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FilterCell", forIndexPath: indexPath) as! aStatusFilterCell
        cell.label_status_filter.text = caller?.statusFilter?.statusesList[indexPath.row].0
        if caller?.statusFilter?.statusesList[indexPath.row].1 == true {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        if cell.label_status_filter.text == "Done" {
            if caller?.aBoard != nil || caller?.aVersion != nil { // Temporarilty disabling possibility to show "Done" issues if this is not a board or version.
                cell.userInteractionEnabled = true
                cell.label_status_filter.textColor = UIColor.blackColor()
            } else {
                cell.userInteractionEnabled = false
                cell.label_status_filter.textColor = UIColor.lightGrayColor()
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let currentCheckmark = caller?.statusFilter?.statusesList[indexPath.row].1 {
            caller?.statusFilter?.statusesList[indexPath.row].1 = !currentCheckmark
        }
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        caller?.applyFilter()
        caller?.view_collectionView.reloadData()
    }
    
    @IBAction func switch_changed_my_issues_only(sender: UISwitch) {
        caller?.statusFilter?.onlyMyIssues = switch_my_issues_only.on
        caller?.applyFilter()
        caller?.view_collectionView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        caller?.archiveContext()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "openChooseVersions" {
            guard let destionationViewController = segue.destinationViewController as? ChooseVersionViewController else {
                return
            }
            destionationViewController.caller = self.caller
        }
    }
    
    @IBAction func unwindToFilter(segue: UIStoryboardSegue) {
        label_version_name.text = caller?.aVersion?.name
        label_version_name.font = UIFont.systemFontOfSize(15)
        table_statuses.reloadData()
    }
}