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

    var target_text: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textview_IssueDetails.text = target_text
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
