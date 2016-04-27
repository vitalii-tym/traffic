//
//  ErrorManager.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/27/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import Foundation
import UIKit

let actionTypes: [String:
                    (String, [Int], [Int: String])
                                            ] =
    [
    "network": ("Oops",
                    [0],
                        [0:""]),
    "get_transitions": ("Oops",  // This is message header
                        [200],   // This is a list of successful codes
                            [404: "There was a problem with transitions", // This is the list of unsuccesful codes
                            0: "unknown problem"]),                       // with respective messages to user
                                                                          // 0 - is a generic text for the case when we can't interpret the code
        // STATUS 200 - application/jsonReturns a full representation of the transitions possible for
        // the specified issue and the fields required to perform the transition.
        // STATUS 404 - Returned if the requested issue is not found or the user does not have permission to view it.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-getTransitions
    
    "do_transition": ("Oops",
                        [204],
                            [400: "There was a problem with doing your transition",
                            404: "There was a problem with doing your transition",
                            0: "unknown problem"])
        // STATUS 204 - Returned if the transition was successful.
        // STATUS 400 - If there is no transition specified.
        // STATUS 404 - The issue does not exist or the user does not have permission to view it
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-doTransition
    ]

func anyErrors(actionType: String, controller: UIViewController, data: NSData?, response: NSURLResponse?, error: NSError?) -> Bool {
    var is_there_error: Bool
    var errors: JIRAerrors?
    
    if error == nil && data != nil {
        let theResponse = response as? NSHTTPURLResponse
        let responseStatus = theResponse!.statusCode
        
        if  actionTypes[actionType]!.1.contains(responseStatus) {
            // Everything is fine, we found that the response code matches to one of succes codes in out list above
            // (usually these range from 200 to 205 or something)
            is_there_error = false
            
        } else {
            // Well, there was a problem with JIRA instance, let's try to parse answer from JIRA and show it if possible
            is_there_error = true
            
            errors = JIRAerrors(data: data!, response: theResponse!)
            
            var errorExplanation = ""
            if  let errorCode = errors?.errorslist[0].error_code,
                let JIRAerrorMessage = errors?.errorslist[0].error_message {
                    // This is the case when we have some info from JIRA about what happened
                
                    if let errorText = actionTypes[actionType]?.2[errorCode] {
                        errorExplanation = errorText
                    } else {
                        errorExplanation = (actionTypes[actionType]?.2[0])! // That's a generic explanation when the code was not found in our list
                    }
                
                    let alert: UIAlertController = UIAlertController(
                            title: actionTypes[actionType]!.0,
                            message: "\(errorExplanation) \n Error code: \(errorCode) \n Message: \(JIRAerrorMessage)",
                            preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    controller.presentViewController(alert, animated: true, completion: nil)

            } else {
                    // We couldn't get info from JIRA, so showing just a generic alert for the chosen type of action
                
                    let alert: UIAlertController = UIAlertController(
                            title: actionTypes[actionType]!.0,
                            message: "\(errorExplanation)",
                            preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    controller.presentViewController(alert, animated: true, completion: nil)
            }
        }
    } else {
        // Looks like we can't access the JIRA instance at all
        is_there_error = true
        var networkError: String = ""

        switch error {
        // There is still a case when there was no error, but we got here because of data == nil, so double-checking "error"
        case nil: networkError = "Seems there was no error, but the answer from JIRA unexpectedly was empty. Please contact developer to investigate this case."
        default: networkError = (error?.localizedDescription)!
        }
        
        if networkError != "cancelled" {
            // showing this alert only if the network call was not cancelled by user simply leaving the respective screen
            let alert: UIAlertController = UIAlertController(title: actionTypes["network"]!.0, message: "\(networkError)", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            controller.presentViewController(alert, animated: true, completion: nil)
        }
    }
    return is_there_error
}