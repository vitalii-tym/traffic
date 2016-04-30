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

class IssueDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var textview_IssueDetails: UITextView!
    @IBOutlet weak var button_Back: UIBarButtonItem!
    @IBOutlet weak var textview_IssueSummary: UITextView!
    @IBOutlet weak var label_priority: UILabel!
    @IBOutlet weak var label_status: UILabel!
    @IBOutlet weak var button_change_status: UIButton!
    @IBOutlet var view_list: UIView!
    @IBOutlet weak var label_required_field_name: UILabel!
    @IBOutlet weak var table_view_resolution: UITableView!

    var aTask: Task!
    var errors: JIRAerrors?
    var availableTransitions: JIRATransitions?
    var currentRequiredFieldForTransition: aReqiredField?
    var currentTransition: Transition?
    var aNetworkRequest = JIRANetworkRequest()
    var fieldsQueue: [aReqiredField]!
    var JSON: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        textview_IssueSummary.text = aTask.task_summary
        if aTask.task_description != nil
            { textview_IssueDetails.text = aTask.task_description }
        else {
            textview_IssueDetails.text = "(no description)"
            textview_IssueDetails.font = UIFont.italicSystemFontOfSize(12.0)
            }
        label_priority.text = aTask.task_priority
        label_status.text = aTask.task_status
        button_change_status.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // As soon as user opens a task we download possible transitions for the task.
        // When succesful, it becomes possible to change task status (respective button becomes enabled)
        let URLEnding = "/rest/api/2/issue/\(aTask.task_key)/transitions?expand=transitions.fields"
        aNetworkRequest.getdata("GET", URLEnding: URLEnding, JSON: nil) { (data, response, error) -> Void in
                if !anyErrors("get_transitions", controller: self, data: data, response: response, error: error) {
                    self.availableTransitions = JIRATransitions(data: data!)
                    self.button_change_status.enabled = true
            }
        }
    }
    
    @IBAction func action_change_status_pressed(sender: AnyObject) {
        let change_status_actionSheet = UIAlertController(title: "Set status", message: nil, preferredStyle: .ActionSheet)
        for transition in (availableTransitions!.transitionsList) {
            change_status_actionSheet.addAction(UIAlertAction(title: "\(transition.transition_name)", style: .Default, handler: {
                action in

                if transition.required_fields.isEmpty {
                    let JSON = "{ \"transition\": { \"id\": \"\(transition.transition_id)\" } }"
                    let URLEnding = "/rest/api/2/issue/\(self.aTask.task_key)/transitions"
                    self.aNetworkRequest.getdata("POST", URLEnding: URLEnding, JSON: JSON) { (data, response, error) -> Void in
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
                } else {
                    // Do something only in case there are required fields
                    var fields = [aReqiredField]()
                    for field in transition.required_fields {
                        fields.append(field)
                    }
                    self.fieldsQueue = fields
                    self.queueGatheringDataAndSendThem()
                }
            }))
        }
        change_status_actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(change_status_actionSheet, animated: true, completion: nil)
    }
    
    func queueGatheringDataAndSendThem() {
        for field in self.fieldsQueue {
            if field.type == "resolution" {
                print ("need to gather resolution")
            }
            if field.type == "array" {
                print ("need to gather array")
            }
        }
        GatherUserDataIfNeeded()
    }
    
    func GatherUserDataIfNeeded() {
        if !self.fieldsQueue.isEmpty {
            self.currentRequiredFieldForTransition = self.fieldsQueue[0]
            table_view_resolution.reloadData()
            // self.currentTransition = transition
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
            self.fieldsQueue.removeFirst()
        } else {
            print("\(JSON)")
            self.JSON = ""
            // we have finished gathering data. Can fire the request here.
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("required_cell", forIndexPath: indexPath) as! required_action_cell
        cell.label_action.text = currentRequiredFieldForTransition!.allowedValues[indexPath.row]["name"] as? String
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let resolution = currentRequiredFieldForTransition?.allowedValues[indexPath.row]
        
      //  let required_field = "\"fields\": { \"resolution\": { \"name\": \"\(resolution!["name"]!)\" } }"
      //  let do_transition = "{ \(required_field),\"transition\": { \"id\": \"\(currentTransition!.transition_id)\" } }"
      //  print(do_transition)
        
        view_list.removeFromSuperview()

        // TODO: Create a function that generates JSON object according to rules applied for current 
        // required field and transition, and appends it to global JSON
        // The function will be called from each piece of interaction presented for user to gather their data
        
        self.JSON += "{JSON object}"

        GatherUserDataIfNeeded()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentRequiredFieldForTransition!.allowedValues.count
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        aNetworkRequest.cancel()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
