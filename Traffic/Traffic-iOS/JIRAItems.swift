//
//  File.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import Foundation

func fixJsonData (data: NSData) -> NSData {
    var dataString = String(data: data, encoding: NSUTF8StringEncoding)!
    dataString = dataString.stringByReplacingOccurrencesOfString("\\'", withString: "'")
    return dataString.dataUsingEncoding(NSUTF8StringEncoding)!
}

struct Task {
    var task_key: String
    var task_summary: String
    var task_priority: String
    var task_description: String? //optional, because some tasks might have no description (JIRA returns "null")
    var task_status: String
}

struct Error {
    var error_code: Int?
    var error_message: String?
}

struct aReqiredField {
    var allowedValues: [Dictionary<String, AnyObject>]
    var operations: [String]
    var name: String
    var type: String
}

struct Transition {
    var transition_id: String
    var transition_name: String
    var target_status: String
    var required_fields: [aReqiredField] //this one will never be nil, but still can be just an empty array
}

class JIRATasks {
    var taskslist: [Task]
    
    init (tasks newTasks: [Task]) {
        self.taskslist = newTasks
    }

    convenience init? (data: NSData) {
        let fixedData = fixJsonData(data)
        var newTasks = [Task]()
        var jsonObject: Dictionary<String, AnyObject>?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(fixedData, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
        }
        catch {  }
        guard let jsonObjectRoot = jsonObject else {
            return nil
        }
        guard let items = jsonObjectRoot["issues"] as? Array<AnyObject> else {
            return nil
        }
        
        for item in items {
            if let itemDict = item as? Dictionary<String,AnyObject> {
                if let issue_key = itemDict["key"] as? String,
                       issue_fields_Dict = itemDict["fields"] as? Dictionary<String,AnyObject> {
                    if let issue_priority_Dict = issue_fields_Dict["priority"] as? Dictionary<String,AnyObject>,
                           issue_status_Dict = issue_fields_Dict["status"] as? Dictionary<String,AnyObject>,
                           issue_summary = issue_fields_Dict["summary"] as? String {
                        let issue_description = issue_fields_Dict["description"] as? String
                            // issue_description can acutally be empty
                        if let issue_priority = issue_priority_Dict["name"] as? String,
                               issue_status = issue_status_Dict["name"] as? String {
                            
                            newTasks.append(Task(task_key: issue_key ?? "(no title)",
                                                task_summary: issue_summary,
                                                task_priority: issue_priority,
                                                task_description: issue_description,
                                                task_status: issue_status))
                        }
                    }
                }
            }
        }
        self.init(tasks: newTasks)
    }
}

class JIRAerrors {
    var errorslist: [Error]
    
    init (errors: [Error]) {
        self.errorslist = errors
    }
    
    convenience init? (data: NSData, response: NSHTTPURLResponse) {
        let fixedData = fixJsonData (data)
        var newErrors = [Error]()
        let response_code = response.statusCode
        var jsonObject: Dictionary<String, AnyObject>?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(fixedData, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
        }
        catch {  }
        guard let jsonObjectRoot = jsonObject else {
            return nil
        }
        guard let items = jsonObjectRoot["errorMessages"] as? Array<AnyObject> else {
            return nil
        }
        for item in items {
            if let message = item as? String {
                newErrors.append(Error(error_code: response_code ,error_message: message))
            }
        }
        self.init(errors: newErrors)
    }
}

class JIRATransitions {
    var transitionsList: [Transition]
    
    init (transitions: [Transition]) {
        self.transitionsList = transitions
    }
    
    convenience init? (data: NSData) {
        let fixedData = fixJsonData(data)
        var newTransitions = [Transition]()
        var jsonObject: Dictionary<String, AnyObject>?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(fixedData, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
        }
        catch {  }
        guard let jsonObjectRoot = jsonObject else {
            return nil
        }
        guard let items = jsonObjectRoot["transitions"] as? Array<AnyObject> else {
            return nil
        }
        for item in items {
            var the_req_fields = [aReqiredField]()
            
            if let itemDict = item as? Dictionary<String,AnyObject> {
                if let transition_id = itemDict["id"] as? String,
                    let transition_name = itemDict["name"] as? String,
                    let transition_fields = itemDict["fields"] as? Dictionary<String,AnyObject>,
                    let transition_toDict = itemDict["to"] as? Dictionary<String,AnyObject> {

                    if let transition_target = transition_toDict["name"] as? String {
                        for (_, item) in transition_fields {
                            if let required_field = item["required"] as? Bool where required_field == true {
                                if let fieldDict = item as? Dictionary<String,AnyObject> {
                                    if let name = fieldDict["name"] as? String,
                                        let allowedValues = fieldDict["allowedValues"] as? [Dictionary<String, AnyObject>],
                                        let operations = fieldDict["operations"] as? Array<String>,
                                        let schemaDict = fieldDict["schema"] as? Dictionary<String,String>,
                                        let type = schemaDict["type"] {
                                        
                                        the_req_fields.append(aReqiredField(allowedValues: allowedValues, operations: operations, name: name, type: type))
                                    }
                                }
                            }
                        }
                        newTransitions.append(Transition(transition_id: transition_id, transition_name: transition_name, target_status: transition_target, required_fields: the_req_fields))

                    }
                }
            }
        }
        self.init(transitions: newTransitions)
    }
}