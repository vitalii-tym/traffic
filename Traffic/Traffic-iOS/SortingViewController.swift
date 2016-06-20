//
//  FilterViewController.swift
//  Easy Jira
//
//  Created by Vitaliy Tim on 6/10/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.

import UIKit

class aSortingCell: UITableViewCell {
    @IBOutlet weak var label_sorting_name: UILabel!
}

class SortingViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    var caller: TasksViewViewController?
    var lastSelectedSearchIndexPath: NSIndexPath?
    var wereChangesApplied = false
    var sortingParameterToRevertTo = sortBy.rank
    var sortingDirectionToRevertTo = sortingDirection.ascending
    
    @IBOutlet weak var table_boards: UITableView!
    @IBOutlet weak var segment_sorting: UISegmentedControl!
    
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

        if let unwrappedDirectionIndex = caller?.currentSortingDirection.hashValue {
            segment_sorting.selectedSegmentIndex = unwrappedDirectionIndex
        }
        
        wereChangesApplied = false

        if let initialSortingParameter = caller?.currentSortingParameter,
            let initialSortingDirection = caller?.currentSortingDirection {
                sortingParameterToRevertTo = initialSortingParameter
                sortingDirectionToRevertTo = initialSortingDirection
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortBy.count
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if wereChangesApplied {
            caller?.archiveContext()
        } else {
            // Popover was dismissed, so we need to revert any possible changes and rebuild the tasks list
            caller?.aNetworkRequest.cancel()
            caller?.currentSortingParameter = sortingParameterToRevertTo
            caller?.currentSortingDirection = sortingDirectionToRevertTo
            if let wasFetchFromCacheSuccesfull = caller?.tryFetchDataFromCache() {
                if !wasFetchFromCacheSuccesfull {
                    caller?.tasksToBeRefreshedWhenNewDataGotFromNetwork = false
                    caller?.tryFetchDataFromNetwork(wasFetchFromCacheSuccesfull)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BoardCell", forIndexPath: indexPath) as! aSortingCell
        let cellItem = sortBy(rawValue: indexPath.row)
        cell.label_sorting_name.text = cellItem?.Name()

        if caller?.currentSortingParameter == cellItem {
            cell.accessoryType = .Checkmark
            lastSelectedSearchIndexPath = indexPath
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let selectedCellItem = sortBy(rawValue: indexPath.row) {
            caller?.currentSortingParameter = selectedCellItem
        }
        
        if lastSelectedSearchIndexPath != nil {
            tableView.reloadRowsAtIndexPaths([lastSelectedSearchIndexPath!, indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
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
    
    @IBAction func segment_sorting_pressed(sender: UISegmentedControl) {
        if let unwrappedCurrentSortingIndex = caller?.currentSortingDirection.hashValue {
            if !(segment_sorting.selectedSegmentIndex == unwrappedCurrentSortingIndex) {
                switch segment_sorting.selectedSegmentIndex {
                case 0 :
                    caller?.currentSortingDirection = sortingDirection.ascending
                case 1 :
                    caller?.currentSortingDirection = sortingDirection.descending
                default:
                    caller?.currentSortingDirection = sortingDirection.ascending
                }

                if let wasFetchFromCacheSuccesfull = caller?.tryFetchDataFromCache() {
                    if !wasFetchFromCacheSuccesfull {
                        caller?.tasksToBeRefreshedWhenNewDataGotFromNetwork = false
                        caller?.tryFetchDataFromNetwork(wasFetchFromCacheSuccesfull)
                    }
                }
            }
        }
    }
    
    @IBAction func action_apply_pressed(sender: UIButton) {
        caller?.view_collectionView.reloadData()
        if let theCaller = caller where theCaller.tasksToBeRefreshedWhenNewDataGotFromNetwork == false {
            // Means we have closed the popover earlier than the data finished refreshing
            caller?.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting tasks list...")
            caller?.tasksToBeRefreshedWhenNewDataGotFromNetwork = true
        }
        wereChangesApplied = true
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    //    @IBAction func unwindToFilter(segue: UIStoryboardSegue) {
    //        label_version_name.text = caller?.aVersion?.name
    //        label_version_name.font = UIFont.systemFontOfSize(15)
    //        table_statuses.reloadData()
    //    }
}