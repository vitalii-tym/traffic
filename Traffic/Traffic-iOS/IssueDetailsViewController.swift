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

    var aTask: Task?
    var errors: JIRAerrors?
    var availableTransitions: JIRATransitions?
    var currentRequiredFieldForTransition: aReqiredField?
    var currentTransition: Transition?
    var IssueCreationMetadata: JIRAMetadataToCreateIssue?
    var currentUser: JIRAcurrentUser?
    var aNetworkRequest = JIRANetworkRequest()
    var fieldsQueue = [aReqiredField]()
    var JSON: String = ""
    var JSONfieldstoSend: Dictionary<String, [AnyObject]> = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // As soon as user opens a task we download possible transitions for the task.
        // When succesful, it becomes possible to change task status (respective button becomes enabled)
        if let theTask = aTask {
            let URLEnding = "/rest/api/2/issue/\(theTask.task_key)/transitions?expand=transitions.fields"
            aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil, domain: nil) { (data, response, error) -> Void in
                if !anyErrors("get_transitions", controller: self, data: data, response: response, error: error) {
                    self.availableTransitions = JIRATransitions(data: data!)
                    self.button_change_status.enabled = true
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if aTask == nil {
            // If after entering the screen we have no task, consider user intends to create new one
            action_create_new_task()
        }
    }
    
    func action_create_new_task() {
        if let metadata = IssueCreationMetadata {
            
            var aRequiredFieldOfTypeProject: aReqiredField?
            var aRequiredFieldOfTypeIssueType: aReqiredField?
            
            // Retrieving fields of type "project" and "issueType" and adding them to the data gathering Queue
            for project in metadata.availableProjects {
                for issueType in project.issueTypes {
                    if let requiredFields = issueType.requiredfields {
                        for requiredField in requiredFields {
                            if requiredField.fieldName == "project" {
                                if aRequiredFieldOfTypeProject == nil {
                                    aRequiredFieldOfTypeProject = requiredField
                                }
                            }
                            if requiredField.fieldName == "issuetype" {
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
            if (aRequiredFieldOfTypeProject != nil) {
                fieldsQueue.append(aRequiredFieldOfTypeProject!)
            }
            if (aRequiredFieldOfTypeIssueType != nil) {
                fieldsQueue.append(aRequiredFieldOfTypeIssueType!)
            }

            // This empty field added to the end of array will indicate to the processor that the job is not finished, there more required fields to find and add here
            fieldsQueue.append(aReqiredField(allowedValues: nil,operations: [],name: "",fieldName: "there_will_be_more_fields_to_be_added",type: ""))

            GatherUserDataIfNeeded()
        }
    }
        
    @IBAction func action_change_status_pressed(sender: AnyObject) {
        if let theTask = aTask {
        
            let change_status_actionSheet = UIAlertController(title: "Set status", message: nil, preferredStyle: .ActionSheet)
            for transition in (availableTransitions!.transitionsList) {
                change_status_actionSheet.addAction(UIAlertAction(title: "\(transition.transition_name)", style: .Default, handler: {
                    action in
                    if let theRequiredFields = transition.required_fields {
                        self.JSON = "{ \"transition\": { \"id\": \"\(transition.transition_id)\"}, \"fields\": {"
                        var fields = [aReqiredField]()
                        for field in theRequiredFields {
                            fields.append(field)
                        }
                        self.fieldsQueue = fields
                        self.currentTransition = transition
                        self.GatherUserDataIfNeeded()
                    } else {
                        let JSON = "{ \"transition\": { \"id\": \"\(transition.transition_id)\" } }"
                        let URLEnding = "/rest/api/2/issue/\(theTask.task_key)/transitions"
                        self.aNetworkRequest.getdata("POST", URLEnding: URLEnding, JSON: JSON, domain: nil) { (data, response, error) -> Void in
                            if !anyErrors("do_transition", controller: self, data: data, response: response, error: error) {
                                let alert: UIAlertController = UIAlertController(
                                    title: "Success",
                                    message: "Status changed to \"\(transition.target_status)\".",
                                    preferredStyle: UIAlertControllerStyle.Alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                                    action in self.performSegueWithIdentifier("back_to_tasks", sender: self)
                                }))
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }))
            }
            change_status_actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            self.presentViewController(change_status_actionSheet, animated: true, completion: nil)
        }
    }
        
    func GatherUserDataIfNeeded() {
        if !self.fieldsQueue.isEmpty {
            self.currentRequiredFieldForTransition = self.fieldsQueue.removeFirst()
            
            // here we need to choose an appropriate custom view for data gathering
            
            switch self.currentRequiredFieldForTransition!.fieldName as String! {
                case "project", "issuetype":
                    if let allowedValuesList = self.currentRequiredFieldForTransition!.allowedValues where !allowedValuesList.isEmpty {
                    
                        table_view_resolution.reloadData()
                        self.view.addSubview(self.view_list)
                        self.label_required_field_name.text = self.currentRequiredFieldForTransition!.name
                        self.view_list.translatesAutoresizingMaskIntoConstraints = false
                        let centerXconstraint = self.view_list.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor)
                        let centerYconstraint = self.view_list.centerYAnchor.constraintEqualToAnchor(self.view.centerYAnchor)
                        let width = self.view_list.widthAnchor.constraintEqualToConstant(300)
                        let height = self.view_list.heightAnchor.constraintEqualToConstant(300)
                        centerYconstraint.constant = -100
                        NSLayoutConstraint.activateConstraints([centerXconstraint, centerYconstraint, width, height])
                        self.view_list.layoutIfNeeded()
                    } else {
                        print("Error: Unexpectedly found no allowed values listed for required fields of types \"project\" and \"issue type\"")
                }
                case "reporter":
                    // No need to ask user anything on this step, automatically filling in the reporter field and going further
                    var dataArray: [Dictionary<String, AnyObject>] = []
                    dataArray.append(["name" : "\"\(currentUser!.name)\""])
                    self.JSONfieldstoSend["reporter"] = dataArray
                    GatherUserDataIfNeeded()
                
                case "summary":

                    self.view.addSubview(self.view_text_input)
                    //self.label_required_field_name.text = self.currentRequiredFieldForTransition!.name
                    self.view_text_input.translatesAutoresizingMaskIntoConstraints = false
                    let centerXconstraint = self.view_text_input.centerXAnchor.constraintEqualToAnchor(self.view.centerXAnchor)
                    let centerYconstraint = self.view_text_input.centerYAnchor.constraintEqualToAnchor(self.view.centerYAnchor)
                    let width = self.view_text_input.widthAnchor.constraintEqualToConstant(300)
                    let height = self.view_text_input.heightAnchor.constraintEqualToConstant(300)
                    centerYconstraint.constant = -100
                    NSLayoutConstraint.activateConstraints([centerXconstraint, centerYconstraint, width, height])
                    self.view_text_input.layoutIfNeeded()
                
                case "parent":
                    // TODO: We need to indicate the parent issue key here.
                    // This is when user has chosen to create a sub-task
                    
                    GatherUserDataIfNeeded()
                
                case "there_will_be_more_fields_to_be_added":
                    let theProject = JSONfieldstoSend["project"]
                    let theProjectID = theProject![0]["id"] as! String // Taking the first one assuming user can't choose more than one project for this kind of field
                    let theIssueType = JSONfieldstoSend["issuetype"]
                    let theIssueTypeID = theIssueType![0]["id"] as! String // Assuming user can'e choose more than one issue type for this kind of field
                    let ProjIndex = self.IssueCreationMetadata?.availableProjects.indexOf({$0.id == theProjectID})
                    let IssueTypeIndex = self.IssueCreationMetadata?.availableProjects[ProjIndex!].issueTypes.indexOf({$0.id == theIssueTypeID})
                    
                    // TODO: Need to get rid of the "!s" in the code above. Assuming all the data in place is very risky here.
                    
                    self.fieldsQueue = self.IssueCreationMetadata!.availableProjects[ProjIndex!].issueTypes[IssueTypeIndex!].requiredfields!
                    
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
                    print ("Error: operation with required field of type \"\(self.currentRequiredFieldForTransition!.fieldName)\" not supported yet. Process interrupted.")
            } // End of switch
            
        } else {

            // self.JSON = String(self.JSON.characters.dropLast()) + "}}" //Replacing last comma with curly brackets

            self.JSON = generateJSONString(JSONfieldstoSend)
            
            print("\(JSON)")
            
            // we have finished gathering data. Can fire the request here.
            
                let URLEnding = "/rest/api/2/issue"
                self.aNetworkRequest.getdata("POST", URLEnding: URLEnding, JSON: JSON, domain: nil) { (data, response, error) -> Void in
                if !anyErrors("create_issue", controller: self, data: data, response: response, error: error) {
                    let alert: UIAlertController = UIAlertController(
                        title: "Success",
                        message: "Create new issue.",
                        preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                        action in self.performSegueWithIdentifier("back_to_tasks", sender: self)
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            
            // TODO: Temporary hardcoded here to create tasks. Need to make the code analyze what user is doing and fire respective URLEnding.

            // if let theTask = aTask {
//                let URLEnding = "/rest/api/2/issue/\(theTask.task_key)/transitions"
//                self.aNetworkRequest.getdata("POST", URLEnding: URLEnding, JSON: JSON, domain: nil) { (data, response, error) -> Void in
//                    if !anyErrors("create_issue", controller: self, data: data, response: response, error: error) {
//                        let alert: UIAlertController = UIAlertController(
//                            title: "Success",
//                            message: "Status changed to \"\(self.currentTransition!.target_status)\".",
//                            preferredStyle: UIAlertControllerStyle.Alert)
//                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
//                            action in self.performSegueWithIdentifier("back_to_tasks", sender: self)
//                        }))
//                        self.presentViewController(alert, animated: true, completion: nil)
//                    }
                // }
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
            self.JSON += "\"resolution\": { \"name\": \"\(chosenValue!["name"]!)\" },"
            // TODO: Need to write JSON generator and remove the self.JSON as redundant
            
            var dataArray: [Dictionary<String, AnyObject>] = []
            dataArray.append(["name" : "\(chosenValue!["name"]!)"])
            self.JSONfieldstoSend["resolution"] = dataArray
        }

        if currentRequiredFieldForTransition?.fieldName == "fixVersions" &&
            (currentRequiredFieldForTransition?.operations.contains("set"))! {
            // Temporary treating fixVersions as one-selection.
            // TODO: Need to add logic here to treat the fixVersions field as an Array, not as a list
            let chosenValue = currentRequiredFieldForTransition?.allowedValues![indexPath.row]
            self.JSON += "\"fixVersions\": [{ \"name\": \"\(chosenValue!["name"]!)\" }],"
            
            var dataArray: [Dictionary<String, AnyObject>] = []
            dataArray.append(["name" : "\(chosenValue!["name"]!)"])
            self.JSONfieldstoSend["fixVersions"] = dataArray
        }
        
        if currentRequiredFieldForTransition?.fieldName == "project" &&
            (currentRequiredFieldForTransition?.operations.contains("set"))! {
            let chosenValue = currentRequiredFieldForTransition?.allowedValues![indexPath.row]
            self.JSON += "\"project\": { \"id\":  \"\(chosenValue!["id"]!)\" },"

            var dataArray: [Dictionary<String, AnyObject>] = []
            dataArray.append(["id" : "\(chosenValue!["id"]!)"])
            self.JSONfieldstoSend["project"] = dataArray
        }
        
        if currentRequiredFieldForTransition?.fieldName == "issuetype" {
            let chosenValue = currentRequiredFieldForTransition?.allowedValues![indexPath.row]
            self.JSON += "\"issuetype\": { \"id\":  \"\(chosenValue!["id"]!)\" },"
            
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
        
        // TODO: need to take user's text from the input field
        let dataArray = [textedit_input_text.text]
        JSONfieldstoSend["summary"] = dataArray
        
        view_text_input.removeFromSuperview()
        GatherUserDataIfNeeded()
    
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        // Preventing user from entering more than 250 characters in the text field.
        let maxtext: Int = 250
        textview_IssueSummary.text = textedit_input_text.text + text
        
        return textView.text.characters.count + (text.characters.count - range.length) <= maxtext
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        aNetworkRequest.cancel()
        aTask = nil
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
