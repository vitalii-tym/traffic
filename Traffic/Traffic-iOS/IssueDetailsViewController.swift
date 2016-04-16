//
//  IssueDetailsViewController.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/13/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class IssueDetailsViewController: UIViewController {
    
    @IBOutlet weak var textview_IssueDetails: UITextView!
    @IBOutlet weak var button_Back: UIBarButtonItem!
    @IBOutlet weak var textview_IssueSummary: UITextView!
    @IBOutlet weak var label_priority: UILabel!
    @IBOutlet weak var label_status: UILabel!

    var aTask: Task!
    
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

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
