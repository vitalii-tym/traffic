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

class FilterViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    var statusFilter: [(String, Bool)] = []
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statusFilter.count
    }
        
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FilterCell", forIndexPath: indexPath) as! aStatusFilterCell
        cell.label_status_filter.text = statusFilter[indexPath.row].0
        if statusFilter[indexPath.row].1 == true {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        statusFilter[indexPath.row].1 = !statusFilter[indexPath.row].1
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
    }
}