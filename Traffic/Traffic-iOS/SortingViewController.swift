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
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortBy.count
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
//        caller?.archiveContext()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BoardCell", forIndexPath: indexPath) as! aSortingCell
        let cellItem = sortBy(rawValue: indexPath.row)
        cell.label_sorting_name.text = cellItem?.Name()

        if caller?.currentSortingOrder == cellItem {
            cell.accessoryType = .Checkmark
            lastSelectedSearchIndexPath = indexPath
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let selectedCellItem = sortBy(rawValue: indexPath.row) {
            caller?.currentSortingOrder = selectedCellItem
        }
        
        if lastSelectedSearchIndexPath != nil {
            tableView.reloadRowsAtIndexPaths([lastSelectedSearchIndexPath!, indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        } else {
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
        
        if let isFetchFromCacheSuccesfull = caller?.tryFetchDataFromCache() {
            if isFetchFromCacheSuccesfull {
                caller?.view_collectionView.reloadData()
            } else {
                caller?.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting tasks list...")
                caller?.tryFetchDataFromNetwork(isFetchFromCacheSuccesfull)
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

                if let isFetchFromCacheSuccesfull = caller?.tryFetchDataFromCache() {
                    if isFetchFromCacheSuccesfull {
                        caller?.view_collectionView.reloadData()
                    } else {
                        caller?.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting tasks list...")
                        caller?.tryFetchDataFromNetwork(isFetchFromCacheSuccesfull)
                    }
                }
            }
        }
    }
    
    //    @IBAction func unwindToFilter(segue: UIStoryboardSegue) {
    //        label_version_name.text = caller?.aVersion?.name
    //        label_version_name.font = UIFont.systemFontOfSize(15)
    //        table_statuses.reloadData()
    //    }
}