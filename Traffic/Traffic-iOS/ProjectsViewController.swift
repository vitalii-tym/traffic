//
//  ProjectsViewController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 5/23/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class aProjectCell: UITableViewCell {
    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var button_expand: UIButton!
}

class aVersionCell: UITableViewCell {
    @IBOutlet weak var label_name: UILabel!
}

class projectsVersionsMap: NSObject, NSCoding {
    // This structure will be used for tables. Once we retreive versions for a project they will be incorporated into this atructure
    // so that the structure continues to be flat, while any its item will represent either a project or a version in a project,
    // then a project can be accessed in projectsList by knowing ProjIndex or version can be accessed by known ProjIndex and VerIndex.
    var theMap: [(Type: String, ProjIndex: Int, VerIndex: Int?, ButtonSelected: Bool?)] = [] // This is a flattened representation of projects and versions in them
    
    override init() {
        self.theMap = []
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        var decodedMapping = [(Type: String, ProjIndex: Int, VerIndex: Int?, ButtonSelected: Bool?)]()
        var aMapItem: (Type: String, ProjIndex: Int, VerIndex: Int?, ButtonSelected: Bool?)? = nil
        var index = 0
        while true {
            if let type = aDecoder.decodeObjectForKey("mapobject"+String(index)+"type") as? String,
                let projIndex = aDecoder.decodeObjectForKey("mapobject"+String(index)+"ProjIndex") as? Int {
                    let verIndex = aDecoder.decodeObjectForKey("mapobject"+String(index)+"VerIndex") as? Int
                    let buttonSelected = aDecoder.decodeObjectForKey("mapobject"+String(index)+"ButtonSelected") as? Bool
                    aMapItem = (type, projIndex, verIndex, buttonSelected)
                    decodedMapping.append(aMapItem!)
                    index += 1
            } else {
                break
            }
        }
        self.init()
        theMap = decodedMapping
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        for (index, object) in theMap.enumerate() {
            aCoder.encodeObject(object.0, forKey: "mapobject"+String(index)+"type")
            aCoder.encodeObject(object.1, forKey: "mapobject"+String(index)+"ProjIndex")
            aCoder.encodeObject(object.2, forKey: "mapobject"+String(index)+"VerIndex")
            aCoder.encodeObject(object.3, forKey: "mapobject"+String(index)+"ButtonSelected")
        }
    }
    
    class func path() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
        let path = documentsPath?.stringByAppendingString("/PVMap")
        return path!
    }
}

class ProjectsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var PVMap = projectsVersionsMap()
    var aNetworkRequest = JIRANetworkRequest()
    var projects: JIRAProjects? {
        didSet {
            if PVMap.theMap.isEmpty {
                for (index, _) in projects!.projectsList.enumerate() {
                    PVMap.theMap.append((Type: "Project", ProjIndex: index, VerIndex: nil, ButtonSelected: false))
                self.view_projects_list.reloadData()
                }
            }
        }
    }
    var aProjectToPass: Project?
    var aVersionToPass: Version?
    var aBoardToPass: Board?

    var refreshControl: UIRefreshControl!
    @IBOutlet weak var view_projects_list: UITableView!
    @IBOutlet weak var button_log_out: UIBarButtonItem!
    
    override func viewDidLoad() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: #selector(ProjectsViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        view_projects_list!.addSubview(refreshControl)
        // Retrieving saved list of projects, if any.
        if let archivedCopyOfProjects = NSKeyedUnarchiver.unarchiveObjectWithFile(JIRAProjects.path()) as? JIRAProjects {
            projects = archivedCopyOfProjects
        }
        if let archivedCopyOfPVMap = NSKeyedUnarchiver.unarchiveObjectWithFile(projectsVersionsMap.path()) as? projectsVersionsMap {
            PVMap = archivedCopyOfPVMap
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let URLEnding = "/rest/api/2/project"
        if projects == nil { // "projects" will be absent if this is the first time login or if unarchiving projects was unsuccesful. So user will have to wait a while.
            parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting projects...")
            aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                if !anyErrors("get_projects", controller: self, data: data, response: response, error: error, quiteMode: false) {
                    let projlist = JIRAProjects(data: data!)
                    // Manually adding the "All Projects" item to the list
                    projlist?.projectsList.insert(Project(id: "", key: "", projectTypeKey: "", name: "All projects", versions: [], boards: []), atIndex: 0)
                    self.projects = projlist
                    NSKeyedArchiver.archiveRootObject(self.projects!, toFile: JIRAProjects.path())
                }
                self.parentViewController?.stopActivityIndicator()
            }
        }
        aProjectToPass = nil
        aVersionToPass = nil
        aBoardToPass = nil
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PVMap.theMap.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentMaping = PVMap.theMap[indexPath.row]
        if currentMaping.Type == "Project" {
            let projectCell = tableView.dequeueReusableCellWithIdentifier("project_сell", forIndexPath: indexPath) as! aProjectCell
                projectCell.label_name.text = projects?.projectsList[currentMaping.ProjIndex].name
                projectCell.button_expand.tag = indexPath.row
                projectCell.button_expand.hidden = false
                if let isSelected = currentMaping.ButtonSelected {
                    projectCell.button_expand.selected = isSelected
                }
                projectCell.button_expand.addTarget(self, action: #selector(button_expand_pressed(_:event:)), forControlEvents: .TouchUpInside)
                if currentMaping.ProjIndex == 0 { // We don't need the expand button for "All Projects" type of project (which always goes first in the list)
                    projectCell.button_expand.hidden = true
                }
                return projectCell
        } else if currentMaping.Type == "Version" {
            let versionCell = tableView.dequeueReusableCellWithIdentifier("version_cell", forIndexPath: indexPath) as! aVersionCell
            if projects?.projectsList[currentMaping.ProjIndex].versions.count > 0 {
                versionCell.label_name.text = projects?.projectsList[currentMaping.ProjIndex].versions[currentMaping.VerIndex!].name
            } else {
                print("Couldn't get version name. Looks like PVM not in sync with projects list.")
            }
            return versionCell
        } else if currentMaping.Type == "Board" {
            let versionCell = tableView.dequeueReusableCellWithIdentifier("version_cell", forIndexPath: indexPath) as! aVersionCell
            if projects?.projectsList[currentMaping.ProjIndex].boards.count > 0 {
                versionCell.label_name.text = projects?.projectsList[currentMaping.ProjIndex].boards[currentMaping.VerIndex!].name
            } else {
                print("Couldn't get board name. Looks like PVM not in sync with projects list.")
            }
            return versionCell
        } else {
            print ("Error in determining mapping type. Check: tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) in ProjectViewController.swift")
            return UITableViewCell()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tasks_list" {
            guard let destionationViewController = segue.destinationViewController as? TasksViewViewController else {
                return
            }
            destionationViewController.aProject = self.aProjectToPass
            destionationViewController.aVersion = self.aVersionToPass
            destionationViewController.aBoard = self.aBoardToPass
            destionationViewController.navigationItem.title = self.aProjectToPass?.name
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentMaping = PVMap.theMap[indexPath.row]
        aProjectToPass = projects?.projectsList[currentMaping.ProjIndex]
        if let versionIndex = currentMaping.VerIndex {
            if currentMaping.Type == "Version" {
                aVersionToPass = projects?.projectsList[currentMaping.ProjIndex].versions[versionIndex]
            } else {
                aBoardToPass = projects?.projectsList[currentMaping.ProjIndex].boards[versionIndex]
            }
        }
        self.performSegueWithIdentifier("tasks_list", sender: nil)
    }
    
    @IBAction func button_expand_pressed(sender: UIButton, event: UIEvent) {
        self.view_projects_list.beginUpdates()
        var indexPathsToDeleteForAnimation: [NSIndexPath] = []
        var indexPathsToAddForAnimation: [NSIndexPath] = []
        if let touchPos = event.allTouches()?.first?.locationInView(self.view_projects_list),
            let selectedCellIndex = self.view_projects_list.indexPathForRowAtPoint(touchPos)?.row {
            var insertionPoint = selectedCellIndex
            if sender.selected {
                // Collapsing the cell
                sender.selected = false
                PVMap.theMap[selectedCellIndex].ButtonSelected = false
                if projects != nil {
                    let currentProject = projects!.projectsList[PVMap.theMap[selectedCellIndex].ProjIndex]
                    let numOfVersionsToRemove = self.projects?.getVersionsForProject(currentProject.id).count ?? 0
                    let numOfBoardsToRemove = self.projects?.getBoardsForProject(currentProject.id).count ?? 0
                    var numOfItemsToRemove = numOfVersionsToRemove + numOfBoardsToRemove
                    if selectedCellIndex + numOfItemsToRemove < PVMap.theMap.count {
                        while numOfItemsToRemove > 0 {  // Removing all versions of the chosen project from the projectsVerwionsMap
                            self.PVMap.theMap.removeAtIndex(selectedCellIndex + 1)
                            indexPathsToDeleteForAnimation.append(NSIndexPath(forRow: selectedCellIndex+numOfItemsToRemove, inSection: 0))
                            numOfItemsToRemove -= 1
                        }
                        self.view_projects_list.deleteRowsAtIndexPaths(indexPathsToDeleteForAnimation, withRowAnimation: UITableViewRowAnimation.Right)
                    }
                }
                self.view_projects_list.endUpdates()
            } else {
                // Expanding the cell with getting data from network
                sender.selected = true
                PVMap.theMap[selectedCellIndex].ButtonSelected = true
                if projects != nil {
                    let currentProject = projects!.projectsList[PVMap.theMap[selectedCellIndex].ProjIndex]
                    if currentProject.versions.isEmpty && currentProject.boards.isEmpty { // We don't download versions if they already exist
                        let URLEnding = "/rest/api/2/project/\(currentProject.id)/versions"
                        parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting versions...")
                        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                            // Beginning of 1st level block
                            if !anyErrors("get_versions", controller: self, data: data, response: response, error: error, quiteMode: false) {
                                self.projects?.setVersionsForProject(data!, projectID: currentProject.id)
                                if let versions = self.projects?.getVersionsForProject(currentProject.id) {
                                    var versionsMapToInsert: [(Type: String, ProjIndex: Int, VerIndex: Int?, ButtonSelected: Bool?)] = []
                                    for (vIndex, _) in versions.enumerate() {
                                        insertionPoint = selectedCellIndex + vIndex + 1
                                        versionsMapToInsert.append((Type: "Version", ProjIndex: self.PVMap.theMap[selectedCellIndex].ProjIndex, VerIndex: vIndex, ButtonSelected: nil))
                                        indexPathsToAddForAnimation.append(NSIndexPath(forRow: insertionPoint, inSection: 0))
                                    }
                                    if !versionsMapToInsert.isEmpty {  // Inserting the versions map right after the expanded project
                                        self.PVMap.theMap[selectedCellIndex+1..<selectedCellIndex+1] = versionsMapToInsert[0..<versionsMapToInsert.count]
                                        NSKeyedArchiver.archiveRootObject(self.projects!, toFile: JIRAProjects.path())
                                    } else {
                                        self.showMessage("no versions found", mood: "Bad")
                                        sender.selected = false
                                        self.PVMap.theMap[selectedCellIndex].ButtonSelected = false
                                    }
                                }
                                self.parentViewController?.stopActivityIndicator()
                                self.parentViewController?.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Getting boards...")
                                let URLEndingAgile = "/rest/agile/1.0/board?projectKeyOrId=\(currentProject.id)"
                                self.aNetworkRequest.getdata("GET", URLEnding: URLEndingAgile, JSON: nil, domain: nil) { (data, response, error) -> Void in
                                    // Beginning of 2nd level block
                                    if !anyErrors("get_boards", controller: self, data: data, response: response, error: error, quiteMode: false) {
                                        self.projects?.setBoardsForProject(data!, projectID: currentProject.id)
                                        if let boards = self.projects?.getBoardsForProject(currentProject.id) {
                                            var boardsMapToInsert: [(Type: String, ProjIndex: Int, VerIndex: Int?, ButtonSelected: Bool?)] = []
                                            for (bIndex, _) in boards.enumerate() {
                                                boardsMapToInsert.append((Type: "Board", ProjIndex: self.PVMap.theMap[selectedCellIndex].ProjIndex, VerIndex: bIndex, ButtonSelected: nil))
                                                indexPathsToAddForAnimation.append(NSIndexPath(forRow: insertionPoint + bIndex + 1, inSection: 0))
                                            }
                                            if !boardsMapToInsert.isEmpty{
                                                self.PVMap.theMap[insertionPoint+1..<insertionPoint+1] = boardsMapToInsert[0..<boardsMapToInsert.count]
                                                NSKeyedArchiver.archiveRootObject(self.projects!, toFile: JIRAProjects.path())
                                                sender.selected = true
                                                self.PVMap.theMap[selectedCellIndex].ButtonSelected = true
                                            } else {
                                                self.showMessage("no boards found", mood: "Bad")
                                            }
                                        }
                                        self.view_projects_list.insertRowsAtIndexPaths(indexPathsToAddForAnimation, withRowAnimation: UITableViewRowAnimation.Right)
                                        self.view_projects_list.endUpdates()
                                    }
                                    self.parentViewController?.stopActivityIndicator()
                                    self.view_projects_list.endUpdates()
                                } // END of 2nd level block
                            } else {
                                self.parentViewController?.stopActivityIndicator()
                                self.view_projects_list.endUpdates()
                                sender.selected = false
                                self.PVMap.theMap[selectedCellIndex].ButtonSelected = false
                            }
                        } // END of 1st level block.
                    } else {
                        // Expanding the cell without getting data from network (we already have it in the brojects object)
                        if let versions = self.projects?.getVersionsForProject(currentProject.id),
                            let boards = self.projects?.getBoardsForProject(currentProject.id) {
                            var itemsMapToInsert: [(Type: String, ProjIndex: Int, VerIndex: Int?, ButtonSelected: Bool?)] = []
                            for (vIndex, _) in versions.enumerate() {
                                insertionPoint = selectedCellIndex + vIndex + 1
                                itemsMapToInsert.append((Type: "Version", ProjIndex: self.PVMap.theMap[selectedCellIndex].ProjIndex, VerIndex: vIndex, ButtonSelected: nil))
                                indexPathsToAddForAnimation.append(NSIndexPath(forRow: insertionPoint, inSection: 0))
                            }  // Inserting the versions right after the expanded project into the mapping array
                            for (bIndex, _) in boards.enumerate() {
                                itemsMapToInsert.append((Type: "Board", ProjIndex: self.PVMap.theMap[selectedCellIndex].ProjIndex, VerIndex: bIndex, ButtonSelected: nil))
                                indexPathsToAddForAnimation.append(NSIndexPath(forRow: insertionPoint + bIndex + 1, inSection: 0))
                            }  // Inserting the boards right after the versions
                            self.PVMap.theMap[selectedCellIndex+1..<selectedCellIndex+1] = itemsMapToInsert[0..<itemsMapToInsert.count]
                            self.view_projects_list.insertRowsAtIndexPaths(indexPathsToAddForAnimation, withRowAnimation: UITableViewRowAnimation.Right)
                            self.view_projects_list.endUpdates()
                        }
                    }
                }
            }
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
                let projlist = JIRAProjects(data: data!)
                // Manually adding the "All Projects" item to the list
                projlist?.projectsList.insert(Project(id: "", key: "", projectTypeKey: "", name: "All projects", versions: [], boards: []), atIndex: 0)
                self.projects = projlist
                NSKeyedArchiver.archiveRootObject(self.projects!, toFile: JIRAProjects.path())
                self.PVMap.theMap.removeAll()
                for (index, _) in self.projects!.projectsList.enumerate() {
                    self.PVMap.theMap.append((Type: "Project", ProjIndex: index, VerIndex: nil, ButtonSelected: false))
                    self.view_projects_list.reloadData()
                }
                self.refreshControl.endRefreshing()
                self.showMessage("projects up to date", mood: "Good")
            } else {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        aNetworkRequest.cancel()
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        NSKeyedArchiver.archiveRootObject(PVMap, toFile: projectsVersionsMap.path())
        // We don't archive projects here, because they are always archived as soon as they are succesfully fetched from network
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        // We do decoding in the ViewDidLoad. Since the latter always executes on restoration, we don't have to anything here.
        super.decodeRestorableStateWithCoder(coder)
    }
    
}