//
//  ErrorManager.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/27/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//
//
//  An example on how to use the anyErrors() function:
//
//  let dataTask: NSURLSessionDataTask = self.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
//      NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
//          if !anyErrors("do_transition", controller: self, data: data, response: response, error: error, quiteMode: false) {
//                  // Do work need to do when there were no errors
//              } else {
//                  // If there's something else to do after user has dismissed the error
//                  // but mind the "cancel" type of errors - when the session was cancelled by user going away
//              }
//          })
//      }
//      dataTask.resume()
//  }))

import Foundation
import UIKit

let actionTypes: [String:
                    (String, [Int], [Int: String])
                                            ] =
    [
    "network": ("Oops",
                    [0],
                        [0:""]),
    "do_login": ("Oops",
                        [200],
                        [401: "Check your login and password and try again.",
                        403: "Looks like there is a problem with captcha.",
                        0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 200 - Returns information about the caller's session if the caller is authenticated.
        // 401 - Returned if the login fails due to invalid credentials.
        // 403 - Returned if the login is denied due to a CAPTCHA requirement, throtting, or any other reason.
        // In case of a 403 status code it is possible that the supplied credentials are valid but the user is not allowed to log in at this point in time.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#auth/1/session-login

    "do_logout": ("Oops",
                        [204],
                        [401: "Looks like you have been logged out already.",
                        0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 401 - Returned if the caller is not authenticated.
        // 204 - Returned if the user was successfully logged out.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#auth/1/session-logout

    "get_transitions": ("Oops",  // This is message header
                        [200],   // This is a list of successful codes
                            [404: "There was a problem with transitions", // This is the list of unsuccesful codes
                            0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),  // with respective messages to user
        // 0 - is a generic text for the case when we can't interpret the code
        // 200 - application/jsonReturns a full representation of the transitions possible for the specified issue and the fields required to perform the transition.
        // 404 - Returned if the requested issue is not found or the user does not have permission to view it.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-getTransitions
    
    "get_projects": ("Oops",  // This is message header
                        [200],   // This is a list of successful codes
                        [0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 0 - is a generic text for the case when we can't interpret the code
        // 200 - application/jsonReturns a list of projects for which the user has the BROWSE, ADMINISTER or PROJECT_ADMIN project permission.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-getTransitions

    "get_versions": ("Oops",  // This is message header
                        [200],   // This is a list of successful codes
                        [404: "Couldn't retreive versions list.", // This is the list of unsuccesful codes
                        0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 0 - is a generic text for the case when we can't interpret the code
        // 200 - application/jsonReturned if the project exists and the user has permission to view its versions. Contains a full representation of the project's versions in JSON format.
        // 404 - Returned if the project is not found, or the calling user does not have permission to view it.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-getTransitions

    "get_boards": ("Oops",
            [200],
            [400: "Incorrect request.",
            401: "You are not logged in.",
            403: "You don't have valid license for Agile.",
                0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 200 - application/jsonReturns the requested boards, at the specified page of the results.
        // 400 - Returned if the request is invalid.
        // 401 - Returned if the user is not logged in.
        // 403 - Returned if the user does not have valid license.
    
    "do_transition": ("Oops",
                        [204],
                            [400: "There was a problem with transition.",
                            404: "The issue does not exist or you don't have permission to view it",
                            0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 204 - Returned if the transition was successful.
        // 400 - If there is no transition specified.
        // 404 - The issue does not exist or the user does not have permission to view it
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-doTransition
        
    "do_search": ("Oops",
                        [200],
                        [400: "Search request failed. There was a problem with the jql query.",
                         0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 200 - application/json Returns a JSON representation of the search results.
        // 400 - Returned if there is a problem with the JQL query.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/search-searchUsingSearchRequest
        
    "get_create_meta": ("Oops",
                        [200],
                        [403: "There are no projects where you can create issues. Ask your administrator to give you permissions.",
                        0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 200 - application/jsonReturns the meta data for creating issues.
        // 403 - Returned if the user does not have permission to view any of the requested projects.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-getCreateIssueMeta
    "current_user": ("Oops",
            [200],
            [401: "Looks like you are not logged in. You can not create isses, sorry.",
                0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."]),
        // 200 - everything is fine
        // 401 - Returned if the caller is not authenticated.
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#auth/1/session-currentUser
    "create_issue": ("Oops",
            [201],
            [400: "Issue was not created.",
                0: "Don't know what exactly went wrong. Try again and contact me if you the problem persists."])
        // 201 - application/jsonReturns a link to the created issue.
        // 400 - Returned if the input is invalid (e.g. missing required fields, invalid field values, and so forth).
        // Documentation: https://docs.atlassian.com/jira/REST/latest/#api/2/issue-createIssue
    ]

func anyErrors(actionType: String, controller: UIViewController, data: NSData?, response: NSURLResponse?, error: NSError?, quiteMode: Bool) -> Bool {
    var is_there_error: Bool = true
    
    if error == nil && data != nil {
        let theResponse = response as? NSHTTPURLResponse
        let responseStatus = theResponse!.statusCode
    
        if let theActionType = actionTypes[actionType] {
        
            if theActionType.1.contains(responseStatus) {
                // Everything is fine, we found that the response code matches to one of succes codes in out list above
                // (usually these range from 200 to 205 or something)
                is_there_error = false
            } else {
                // Well, there was a problem with JIRA instance, let's try to parse answer from JIRA and show it if possible
                var errorExplanation = ""
                if let errors = JIRAerrors(data: data!, response: theResponse!) where !(errors.errorslist.isEmpty) {
                    for error in errors.errorslist {
                        let errorCode = error.error_code
                        let JIRAerrorMessage = error.error_message
                        // This is the case when we have some info from JIRA about what happened
                    
                        if let errorText = actionTypes[actionType]?.2[errorCode!] {
                            errorExplanation = errorText
                        } else {
                            errorExplanation = (actionTypes[actionType]?.2[0])! // That's a generic explanation when the code was not found in our list
                        }
                    
                        let alert: UIAlertController = UIAlertController(
                                title: actionTypes[actionType]!.0,
                                message: "\(errorExplanation) \n Error code: \(errorCode!) \n Message: \(JIRAerrorMessage!)",
                                preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        controller.presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                        // We couldn't get info from JIRA, so showing just a generic alert for the chosen type of action
                        // TODO: Parse HTML returned from JIRA to provide user with more info about the issue
                    errorExplanation = "Looks like something went wrong. There was an error, but we couldn't parse it, most probably JIRA returned HTML. This could happen in case we had wrong URL in request."
                    
                        let alert: UIAlertController = UIAlertController(
                                title: actionTypes[actionType]!.0,
                                message: "\(errorExplanation)",
                                preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        controller.presentViewController(alert, animated: true, completion: nil)
                }
            }
        } else {
            print("Error manager doesn't know about action type: \(actionType)")
        }
    } else {
        // Looks like we can't access the JIRA instance at all
        var networkError: String = ""

        switch error {
        // There is still a case when there was no error, but we got here because of data == nil, so double-checking "error"
        case nil: networkError = "Seems there was no error, but the answer from JIRA unexpectedly was empty. Please contact developer to investigate this case."
        default: networkError = (error?.localizedDescription)!
        }
        
        if error?.code != -999 {
            // code -999 means the request query was cancelled by the app itself
            // It is usually done in a viewWillDisappear by self.urlSession.invalidateAndCancel() and can be ignored.
     //       let alert: UIAlertController = UIAlertController(title: actionTypes["network"]!.0, message: "\(networkError)", preferredStyle: UIAlertControllerStyle.Alert)
     //       alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
     //       controller.presentViewController(alert, animated: true, completion: nil)
        }
    }
    return is_there_error
}