//
//  FilterViewController.swift
//  Easy Jira
//
//  Created by Vitaliy Tim on 6/10/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.

import UIKit

//class aStatusFilterCell: UITableViewCell {
//    @IBOutlet weak var label_status_filter: UILabel!
//}

class aChooseBoardCell: UITableViewCell {
    @IBOutlet weak var label_board_name: UILabel!
}

//class ChooseVersionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
//    
//    var caller: TasksViewViewController?
//    var lastSelectedVersionIndexPath: NSIndexPath?
//    
//    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if let numOfVersionsInList = caller?.versions.count {
//            return (numOfVersionsInList + 1)
//        } else {
//            return 0
//        }
//    }
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier("ChooseVersionCell", forIndexPath: indexPath) as! aChooseVersionCell
//        if indexPath.row != 0 {
//            cell.label_version_name.text = caller?.versions[indexPath.row - 1].name
//            if cell.label_version_name.text == caller?.aVersion?.name {
//                cell.accessoryType = .Checkmark
//                lastSelectedVersionIndexPath = indexPath
//            }
//        } else {
//            cell.label_version_name.text = "(all versions)"
//            if caller?.aVersion == nil {
//                cell.accessoryType = .Checkmark
//                lastSelectedVersionIndexPath = indexPath
//            }
//        }
//        return cell
//    }
//    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        if indexPath.row == 0 {
//            caller?.aVersion = nil
//        } else {
//            caller?.aVersion = caller?.versions[indexPath.row - 1]
//        }
//        if lastSelectedVersionIndexPath != nil {
//            tableView.reloadRowsAtIndexPaths([lastSelectedVersionIndexPath!, indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
//        } else {
//            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
//        }
//        if let isFetchFromCacheSuccesfull = caller?.tryFetchDataFromCache() {
//            if !isFetchFromCacheSuccesfull {
//                caller?.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting tasks list...")
//                caller?.tryFetchDataFromNetwork(isFetchFromCacheSuccesfull)
//            }
//        }
//        performSegueWithIdentifier("backToFilter", sender: self)
//    }
//}

class BoardsViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    var caller: TasksViewViewController?
    var lastSelectedBoardIndexPath: NSIndexPath?
    var wereChangesApplied = false
    var aBoardToRevertTo: Board?

    @IBOutlet weak var table_boards: UITableView!

    override func viewDidLoad() {
        if self.preferredContentSize.height == caller?.view_collectionView.frame.height {
            table_boards.scrollEnabled = true
        } else {
            table_boards.scrollEnabled = false
        }
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        wereChangesApplied = false
        if let initialBoard = caller?.aBoard {
            aBoardToRevertTo = Board.init(id: initialBoard.id,
                                          name: initialBoard.name,
                                          type: initialBoard.type)
        } else {
            aBoardToRevertTo = nil
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if wereChangesApplied {
            caller?.archiveContext()
        } else {
            // Popover was dismissed, so we need to revert any possible changes and rebuild the tasks list
            caller?.aNetworkRequest.cancel()
            caller?.aBoard = aBoardToRevertTo
            if let wasFetchFromCacheSuccesfull = caller?.tryFetchDataFromCache() {
                if !wasFetchFromCacheSuccesfull {
                    caller?.tasksToBeRefreshedWhenNewDataGotFromNetwork = false
                    caller?.tryFetchDataFromNetwork(wasFetchFromCacheSuccesfull)
                }
            
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numOfBoardsInList = caller?.aProject?.boards.count {
            return (numOfBoardsInList + 1)
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BoardCell", forIndexPath: indexPath) as! aChooseBoardCell
        if indexPath.row == 0 {
            cell.label_board_name.text = "[All issues in this project]"
            if caller?.aBoard == nil {
                cell.accessoryType = .Checkmark
                lastSelectedBoardIndexPath = indexPath
            } else {
                cell.accessoryType = .None
            }
        } else {
            cell.label_board_name.text = caller?.aProject?.boards[indexPath.row - 1].name
            
            if caller?.aProject?.boards[indexPath.row - 1].id == caller?.aBoard?.id {
                cell.accessoryType = .Checkmark
                lastSelectedBoardIndexPath = indexPath
            } else {
                cell.accessoryType = .None
            }
            // This is for later. We will allow selecting Sprint or Backlog to show if the project is of type "scrum"
//            if caller?.aProject!.boards[indexPath.row - 1].type == "scrum" {
//                cell.accessoryType = .DisclosureIndicator
//            }
        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            caller?.aBoard = nil
        } else {
            caller?.aBoard = caller?.aProject?.boards[indexPath.row - 1]
        }
        if lastSelectedBoardIndexPath != nil {
            tableView.reloadRowsAtIndexPaths([lastSelectedBoardIndexPath!, indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        } else {
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
        
        if let wasFetchFromCacheSuccesfull = caller?.tryFetchDataFromCache() {
            if !wasFetchFromCacheSuccesfull {
                caller?.tasksToBeRefreshedWhenNewDataGotFromNetwork = false
                caller?.tryFetchDataFromNetwork(wasFetchFromCacheSuccesfull)
            }
        }
    }
    @IBAction func button_apply_pressed(sender: UIButton) {
        caller?.view_collectionView.reloadData()
        if let theCaller = caller where theCaller.tasksToBeRefreshedWhenNewDataGotFromNetwork == false {
            // Means we have closed the popover earlier than the data finished refreshing
            caller?.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting tasks list...")
            caller?.tasksToBeRefreshedWhenNewDataGotFromNetwork = true
        }
        wereChangesApplied = true
        self.dismissViewControllerAnimated(false, completion: nil)
    }

//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "openChooseVersions" {
//            guard let destionationViewController = segue.destinationViewController as? ChooseVersionViewController else {
//                return
//            }
//            destionationViewController.caller = self.caller
//        }
//    }

//    @IBAction func unwindToFilter(segue: UIStoryboardSegue) {
//        label_version_name.text = caller?.aVersion?.name
//        label_version_name.font = UIFont.systemFontOfSize(15)
//        table_statuses.reloadData()
//    }
}