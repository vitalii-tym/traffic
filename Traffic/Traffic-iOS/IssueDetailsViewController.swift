//
//  IssueDetailsViewController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/13/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class required_action_cell : UITableViewCell {
    @IBOutlet weak var label_action: UILabel!
}

class IssueDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    
    @IBOutlet weak var textview_IssueDetails: UITextView!
    @IBOutlet weak var button_Back: UIBarButtonItem!
    @IBOutlet weak var textview_IssueSummary: UITextView!
    @IBOutlet weak var label_priority: UILabel!
    @IBOutlet weak var label_status: UILabel!
    @IBOutlet weak var button_change_status: UIButton!
    @IBOutlet var view_list: UIView!
    @IBOutlet var view_text_input: UIView!
    @IBOutlet weak var label_required_field_name: UILabel!
    @IBOutlet weak var table_view_resolution: UITableView!
    @IBOutlet weak var button_done_editing: UIButton!
    @IBOutlet weak var textedit_input_text: UITextView!
    @IBOutlet weak var label_require_text_name: UILabel!
    
    var aProject: Project?
    var aTask: Task?
    var errors: JIRAerrors?
    var availableTransitions: JIRATransitions?
    var currentRequiredFieldForTransition: aReqiredField?
    var currentTransition: Transition?
    var IssueCreationMetadata: JIRAMetadataToCreateIssue?
    var currentUser: JIRAcurrentUser?
    var aNetworkRequest = JIRANetworkRequest()
    var fieldsQueue = [aReqiredField]()
    var caller: TasksViewViewController?
    var JSON: String = ""
    var JSONfieldstoSend: Dictionary<String, [AnyObject]> = [:]
    var currentUserIntention: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // As soon as user opens a task we download possible transitions for the task.
        // When succesful, it becomes possible to change task status (respective button becomes enabled)
        if let theTask = aTask {
            let URLEnding = "/rest/api/2/issue/\(theTask.task_key)/transitions?expand=transitions.fields"
            aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                if !anyErrors("get_transitions", controller: self, data: data, response: response, error: error, quiteMode: false) {
                    self.availableTransitions = JIRATransitions(data: data!)
                    self.button_change_status.enabled = true
                }
            }
        }
        textedit_input_text.delegate = self
        if let theTask = aTask {
            textview_IssueSummary.text = theTask.task_summary
            if theTask.task_description != nil
            { textview_IssueDetails.text = theTask.task_description }
            else {
                textview_IssueDetails.text = "(no description)"
                textview_IssueDetails.font = UIFont.italicSystemFontOfSize(12.0)
            }
            label_priority.text = theTask.task_priority
            label_status.text = theTask.task_status
            
        } else {
            textview_IssueSummary.text = ""
            textview_IssueDetails.text = ""
            label_priority.text = ""
            label_status.text = ""
        }
        button_change_status.enabled = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if aTask == nil { // If after entering the screen we have no task, consider user intends to create new one
            action_create_new_task()
        }
    }
    
    func action_create_new_task() {
        currentUserIntention = "create_issue"
        if let metadata = IssueCreationMetadata {
            
            var aRequiredFieldOfTypeProject: aReqiredField?
            
            // Retrieving fields of type "project" and "issueType" and adding them to the data gathering Queue
            for project in metadata.availableProjects {
                for issueType in project.issueTypes {
                    if let requiredFields = issueType.requiredfields {
                        for requiredField in requiredFields {
                            if requiredField.fieldName == "project" {
                                if aRequiredFieldOfTypeProject == nil {
                                    aRequiredFieldOfTypeProject = requiredField
                                } else {
                                    // Since AllowedValues fields go separately in different projects and issue types, we'll have to merge them
                                    // together in one list of allowed values, but make sure there are no dublicates.
                                    // We assume AllowedValues for an issueType for a project always contains one item.
                                    if aRequiredFieldOfTypeProject!.allowedValues != nil && requiredField.allowedValues != nil {
                                        if let allowedValues = aRequiredFieldOfTypeProject!.allowedValues! as NSArray?
                                            where !allowedValues.containsObject(requiredField.allowedValues![0]) {
                                            aRequiredFieldOfTypeProject!.allowedValues!.append(requiredField.allowedValues![0])
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        print("unexpectedly found an issue type in a project with no required fields at all")
                    }
                }
            }
            if (aRequiredFieldOfTypeProject != nil) {
                fieldsQueue.append(aRequiredFieldOfTypeProject!)
            }

            // This empty field added to the end of array will indicate to the processor that the job is not finished, there more required fields to find and add here
            fieldsQueue.append(aReqiredField(allowedValues: nil,operations: [],name: "",fieldName: "",type: "there_are_still_issue_types_to_choose"))

            GatherUserDataIfNeeded()
        } else {
            print("There is neither a task in context, no creation metadata provided. Returning back to list, because there is nothing to show and to do for IssueDetailsViewController")
            self.performSegueWithIdentifier("back_to_tasks", sender: self)
        }
    }
        
    @IBAction func action_change_status_pressed(sender: AnyObject) {
        currentUserIntention = "transition_issue"
        if aTask != nil {
            let change_status_actionSheet = UIAlertController(title: "Set status", message: nil, preferredStyle: .ActionSheet)
            for transition in (availableTransitions!.transitionsList) {
                change_status_actionSheet.addAction(UIAlertAction(title: "\(transition.transition_name)", style: .Default, handler: {
                    action in
                    if let theRequiredFields = transition.required_fields {
                        var fields = [aReqiredField]()
                        for field in theRequiredFields {
                            fields.append(field)
                        }
                        self.fieldsQueue = fields
                    }
                    self.JSON = "{ \"transition\": { \"id\": \"\(transition.transition_id)\" } }"
                    self.currentTransition = transition
                    self.GatherUserDataIfNeeded()
                }))
            }
            change_status_actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            // required for iPad
            change_status_actionSheet.popoverPresentationController?.sourceView = button_change_status
            change_status_actionSheet.popoverPresentationController?.sourceRect = button_change_status.bounds
            
            self.presentViewController(change_status_actionSheet, animated: true, completion: nil)
        } else {
            print("Error: There was an attempt to do a transition for an issue without context (no issue was provided)")
        }
    }
        
    func GatherUserDataIfNeeded() {
        if !self.fieldsQueue.isEmpty {
            self.currentRequiredFieldForTransition = self.fieldsQueue.removeFirst()
            
            switch self.currentRequiredFieldForTransition?.type as String! {  // We need to choose an appropriate custom view for data gathering
                case "project", "issuetype", "array", "resolution":
                    if self.currentRequiredFieldForTransition?.type == "project" && aProject != nil && aProject?.id != "" {
                        // If we are in a context of some project we can fill it in right away without asking user to choose project
                        var dataArray: [Dictionary<String, AnyObject>] = []
                        dataArray.append(["id" : "\(aProject!.id)"])
                        self.JSONfieldstoSend["project"] = dataArray
                        GatherUserDataIfNeeded()
                    } else if let allowedValuesList = self.currentRequiredFieldForTransition!.allowedValues where !allowedValuesList.isEmpty {
                        // Hiding the "Sub-Task" issue type, because we don't support it yet
                        for (index, allowedValue) in (self.currentRequiredFieldForTransition!.allowedValues?.enumerate())! {
                            if allowedValue["name"] as? String == "Sub-task" {
                                currentRequiredFieldForTransition?.allowedValues?.removeAtIndex(index)
                                break
                            }
                        }
                        table_view_resolution.reloadData()
                        self.view.addSubview(self.view_list)
                        self.label_required_field_name.text = self.currentRequiredFieldForTransition!.name
                        layoutView(view_list, layoutTarget: self.view)
                    } else {
                        print("Error: Unexpectedly found no allowed values listed for required fields of types \"project\" and \"issue type\"")
                }
                case "user":
                    // No need to ask user anything on this step, automatically filling in the reporter field and going further
                    var dataArray: [Dictionary<String, AnyObject>] = []
                    dataArray.append(["name" : "\(currentUser!.name)"])
                    self.JSONfieldstoSend["reporter"] = dataArray
                    GatherUserDataIfNeeded()
                
                case "string":
                    self.view.addSubview(self.view_text_input)
                    self.label_require_text_name.text = self.currentRequiredFieldForTransition!.name
                    layoutView(view_text_input, layoutTarget: self.view)
                
                case "parent":
                    // TODO: We need to indicate the parent issue key here.
                    // This is when user has chosen to create a sub-task
                    GatherUserDataIfNeeded()
                
                case "there_are_still_issue_types_to_choose":
                    var chosenProject: MetadataProject
                    var aRequiredFieldOfTypeIssueType: aReqiredField?
                    
                    for aProject in (IssueCreationMetadata?.availableProjects)! {
                        if aProject.id == JSONfieldstoSend["project"]![0]["id"] as! String {
                            chosenProject = aProject
                    
                            for issueType in chosenProject.issueTypes {
                                if let requiredFields = issueType.requiredfields {
                                    for requiredField in requiredFields {
                                        if requiredField.fieldName == "issuetype" || requiredField.fieldName == "issueType" || requiredField.fieldName == "IssueType" {
                                            if aRequiredFieldOfTypeIssueType == nil {
                                                aRequiredFieldOfTypeIssueType = requiredField
                                            } else {
                                                aRequiredFieldOfTypeIssueType?.allowedValues?.append(requiredField.allowedValues![0])
                                            }
                                        }
                                    }
                                } else {
                                    print("unexpectedly found an issue type in a project with no required fields at all")
                                }
                            }
                        }
                    }
                    if (aRequiredFieldOfTypeIssueType != nil) {
                            fieldsQueue.append(aRequiredFieldOfTypeIssueType!)
                    }
                    fieldsQueue.append(aReqiredField(allowedValues: nil,operations: [],name: "",fieldName: "",type: "there_will_be_more_fields_to_be_added"))
                    GatherUserDataIfNeeded()
                
                case "there_will_be_more_fields_to_be_added":
                    if let theProject = JSONfieldstoSend["project"],
                       let theIssueType = JSONfieldstoSend["issuetype"] {
                        if let theProjectID = theProject[0]["id"] as? String, // Taking the first one assuming user can't choose more than one project for this kind of field
                            let theIssueTypeID = theIssueType[0]["id"] as? String { // Assuming user can'e choose more than one issue type for this kind of field
                        let ProjIndex = self.IssueCreationMetadata?.availableProjects.indexOf({$0.id == theProjectID})
                        let IssueTypeIndex = self.IssueCreationMetadata?.availableProjects[ProjIndex!].issueTypes.indexOf({$0.id == theIssueTypeID})
                        self.fieldsQueue = self.IssueCreationMetadata!.availableProjects[ProjIndex!].issueTypes[IssueTypeIndex!].requiredfields!
                        }
                    }
                    // TODO: Need to get rid of the "!s" in the code above. Assuming all the data in place is very risky here.
                    
                    // Since user has already chosen the project and issuetype we should get rid of these fields from the additinal fields array to not ask them again
                    for (index, aRequiredField) in self.fieldsQueue.enumerate() {
                        if aRequiredField.fieldName == "project" {
                            self.fieldsQueue.removeAtIndex(index)
                            break
                        }
                    }
                    
                    for (index, aRequiredField) in self.fieldsQueue.enumerate() {
                        if aRequiredField.fieldName == "issuetype" {
                            self.fieldsQueue.removeAtIndex(index)
                            break
                        }
                    }
                    GatherUserDataIfNeeded()
                
                default:
                    print ("Error: operation with required field of type \"\(self.currentRequiredFieldForTransition!.type)\" not supported yet. Process interrupted.")
            } // End of switch
            
        } else {
            // we have finished gathering data. Can fire the request here.
            JSON = generateJSONString(JSON ,inputDataForGeneration: JSONfieldstoSend)
            print("\(JSON)")
            
            switch currentUserIntention {
            case "create_issue":
                self.parentViewController!.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Creating issue...")
                let URLEnding = "/rest/api/2/issue"
                self.aNetworkRequest.getdata("POST", URLEnding: URLEnding, JSON: JSON, domain: nil) { (data, response, error) -> Void in
                    if !anyErrors("create_issue", controller: self, data: data, response: response, error: error, quiteMode: false) {
                        self.caller?.listNeedsRefreshing = true
                        self.performSegueWithIdentifier("back_to_tasks", sender: self)
                    }
                    self.parentViewController!.stopActivityIndicator()
                }
            case "transition_issue":
                 if let theTask = aTask {
                    self.parentViewController!.startActivityIndicator(.WhiteLarge, location: nil, activityText: "Changing status...")
                    let URLEnding = "/rest/api/2/issue/\(theTask.task_key)/transitions"
                    self.aNetworkRequest.getdata("POST", URLEnding: URLEnding, JSON: JSON, domain: nil) { (data, response, error) -> Void in
                        if !anyErrors("do_transition", controller: self, data: data, response: response, error: error, quiteMode: false) {
                            self.caller?.listNeedsRefreshing = true
                            self.performSegueWithIdentifier("back_to_tasks", sender: self)
                        }
                        self.parentViewController!.stopActivityIndicator()
                    }
                }
            default:
                print("No action provided. Doing nothing.")
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("required_cell", forIndexPath: indexPath) as! required_action_cell
        cell.label_action.text = currentRequiredFieldForTransition!.allowedValues![indexPath.row]["name"] as? String
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        view_list.removeFromSuperview()
        
        if currentRequiredFieldForTransition?.fieldName == "resolution" &&
            (currentRequiredFieldForTransition!.operations.contains("set")) {
            let chosenValue = currentRequiredFieldForTransition?.allowedValues![indexPath.row]
            var dataArray: [Dictionary<String, AnyObject>] = []
            dataArray.append(["name" : "\(chosenValue!["name"]!)"])
            self.JSONfieldstoSend["resolution"] = dataArray
        }

        if currentRequiredFieldForTransition?.fieldName == "fixVersions" &&
            (currentRequiredFieldForTransition?.operations.contains("set"))! {
            // Temporary treating fixVersions as one-selection.
            // TODO: Need to add logic here to treat the fixVersions field as an Array, not as a list
            let chosenValue = currentRequiredFieldForTransition?.allowedValues![indexPath.row]
            var dataArray: [Dictionary<String, AnyObject>] = []
            dataArray.append(["name" : "\(chosenValue!["name"]!)"])
            self.JSONfieldstoSend["fixVersions"] = dataArray
        }
        
        if currentRequiredFieldForTransition?.fieldName == "project" &&
            (currentRequiredFieldForTransition?.operations.contains("set"))! {
            let chosenValue = currentRequiredFieldForTransition?.allowedValues![indexPath.row]
            var dataArray: [Dictionary<String, AnyObject>] = []
            dataArray.append(["id" : "\(chosenValue!["id"]!)"])
            self.JSONfieldstoSend["project"] = dataArray
        }
        
        if currentRequiredFieldForTransition?.fieldName == "issuetype" {
            let chosenValue = currentRequiredFieldForTransition?.allowedValues![indexPath.row]
            var dataArray: [Dictionary<String, AnyObject>] = []
            dataArray.append(["id" : "\(chosenValue!["id"]!)"])
            self.JSONfieldstoSend["issuetype"] = dataArray
        }
        GatherUserDataIfNeeded()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentRequiredFieldForTransition!.allowedValues!.count
    }
    
    @IBAction func action_done_editing(sender: UIButton) {
        // TODO: need to correctly determine different types of fields + validate text input depending on its type
        var dataArray = [textedit_input_text.text]
        dataArray[0] = dataArray[0].stringByReplacingOccurrencesOfString("\\", withString:"\\\\")
        dataArray[0] = dataArray[0].stringByReplacingOccurrencesOfString("\"", withString:"\\\"")
        JSONfieldstoSend["\(currentRequiredFieldForTransition!.fieldName)"] = dataArray
        textedit_input_text.text = ""
        view_text_input.removeFromSuperview()
        GatherUserDataIfNeeded()
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        // Preventing user from entering more than 250 characters in the text field.
        let maxtext: Int = 250
        textview_IssueSummary.text = textedit_input_text.text + text
        return textView.text.characters.count + (text.characters.count - range.length) <= maxtext
    }
    
    func textViewDidChange(textView: UITextView) {
        button_done_editing.enabled = !textedit_input_text.text.isEmpty
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        aNetworkRequest.cancel()
        aTask = nil
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        if let aTaskToEncode = aTask { Task.encodeForCoder(aTaskToEncode, coder: coder, index: 1) }
        if let aCurrenUserToEncode = currentUser { coder.encodeObject(aCurrenUserToEncode, forKey: "currentUser") }
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        aTask = Task.decode(coder, index: 1)
        currentUser = coder.decodeObjectForKey("currentUser") as? JIRAcurrentUser
        super.decodeRestorableStateWithCoder(coder)
    }

    func layoutView(layoutSource: UIView, layoutTarget: UIView) {
        layoutSource.translatesAutoresizingMaskIntoConstraints = false
        let centerXconstraint = NSLayoutConstraint(item: layoutSource,
                                                   attribute: NSLayoutAttribute.CenterX,
                                                   relatedBy: NSLayoutRelation.Equal,
                                                   toItem: layoutTarget,
                                                   attribute: NSLayoutAttribute.CenterX,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        
        let centerYconstraint = NSLayoutConstraint(item: layoutSource,
                                                   attribute: NSLayoutAttribute.CenterY,
                                                   relatedBy: NSLayoutRelation.Equal,
                                                   toItem: layoutTarget,
                                                   attribute: NSLayoutAttribute.CenterY,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        
        let width = NSLayoutConstraint(item: layoutSource,
                                       attribute: NSLayoutAttribute.Width,
                                       relatedBy: NSLayoutRelation.Equal,
                                       toItem: nil,
                                       attribute: NSLayoutAttribute.NotAnAttribute,
                                       multiplier: 1.0,
                                       constant: 300)
        
        let height = NSLayoutConstraint(item: layoutSource,
                                        attribute: NSLayoutAttribute.Height,
                                        relatedBy: NSLayoutRelation.Equal,
                                        toItem: nil,
                                        attribute: NSLayoutAttribute.NotAnAttribute,
                                        multiplier: 1.0,
                                        constant: 250)
        centerYconstraint.constant = -90
        NSLayoutConstraint.activateConstraints([centerXconstraint, centerYconstraint, width, height])
        layoutSource.layoutIfNeeded()
    }
}