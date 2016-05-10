//
//  File.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import Foundation

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
    var allowedValues: [Dictionary<String, AnyObject>]?
    var operations: [String]
    var name: String // This is a name as shown to user, it can be changed in JIRA settings. To be used only in UI.
    var fieldName: String // This is an internal field name that we use to identify the type of the field. Hope this can't be changed by JIRA admin.
    var type: String
}

struct Transition {
    var transition_id: String
    var transition_name: String
    var target_status: String
    var required_fields: [aReqiredField]? //this one will never be nil, but still can be just an empty array
}

struct IssueType {
    var name: String
    var description: String
    var id: String
    var subtask: Bool
    var requiredfields: [aReqiredField]?
}

struct availableProject {
    var name: String
    var key: String
    var id: String
    var issueTypes: [IssueType]
}

class JIRARequiredFields {
    var requiredFields: [aReqiredField]?
    
    init (fields newRequiredFields: [aReqiredField]?) {
        self.requiredFields = newRequiredFields
    }

    convenience init? (fields: Dictionary<String, AnyObject>) {
        var the_req_fields = [aReqiredField]()
        for (fieldName, item) in fields {
            if let required_field = item["required"] as? Bool where required_field == true {
                if let fieldDict = item as? Dictionary<String,AnyObject> {
                    if let name = fieldDict["name"] as? String,
                        let operations = fieldDict["operations"] as? Array<String>,
                        let schemaDict = fieldDict["schema"] as? Dictionary<String,String>,
                        let type = schemaDict["type"] {
                            let allowedValues = fieldDict["allowedValues"] as? [Dictionary<String, AnyObject>] // For some field types AllowedValues can actually be nil
                            the_req_fields.append(aReqiredField(allowedValues: allowedValues, operations: operations, name: name, fieldName: fieldName, type: type))
                    }
                }
            }
        }
        if !the_req_fields.isEmpty {
            self.init(fields: the_req_fields)
        } else {
            self.init(fields: nil)
        }

    }
}

class JIRAMetadataToCreateIssue {
    var availableProjects: [availableProject]
    
    init (metadata newMetadata: [availableProject]) {
        self.availableProjects = newMetadata
    }
    
    convenience init? (data: NSData) {
        var newAvailableProjects = [availableProject]()
        
    var jsonObject: Dictionary<String, AnyObject>?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(fixJsonData(data), options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
        }
        catch { }

        guard let jsonObjectRoot = jsonObject else {
            return nil
        }
        
        guard let projects = jsonObjectRoot["projects"] as? Array<AnyObject> else {
            return nil
        }
        
        for project in projects {
            if let theProjectDict = project as? Dictionary<String, AnyObject> {
                if let projName = theProjectDict["name"] as? String,
                        projKey = theProjectDict["key"] as? String,
                        projID = theProjectDict["id"] as? String,
                        theIssueTypes = theProjectDict["issuetypes"] as? Array<AnyObject> {
                    
                    var issueTypesList = [IssueType]()
                    for issueType in theIssueTypes {
                        if let issueTypeDict = issueType as? Dictionary<String, AnyObject> {
                            if let issueTypeName = issueTypeDict["name"] as? String,
                                    issueTypeDescription = issueTypeDict["description"] as? String,
                                    issueTypeID = issueTypeDict["id"] as? String,
                                    issueTypeIsSubtask = issueTypeDict["subtask"] as? Bool,
                                    issueTypeFields = issueTypeDict["fields"] as? Dictionary<String,AnyObject> {
                                        let requiredFields = JIRARequiredFields(fields: issueTypeFields)
                                        issueTypesList.append(IssueType(name: issueTypeName, description: issueTypeDescription, id: issueTypeID, subtask: issueTypeIsSubtask, requiredfields: (requiredFields?.requiredFields)))
                            }
                        }
                    }
                    newAvailableProjects.append(availableProject(name: projName, key: projKey, id: projID, issueTypes: issueTypesList))
                }
            }
        }
        self.init(metadata: newAvailableProjects)
    }
}

class JIRATasks {
    var taskslist: [Task]
    
    init (tasks newTasks: [Task]) {
        self.taskslist = newTasks
    }

    convenience init? (data: NSData) {
        var newTasks = [Task]()
        var jsonObject: Dictionary<String, AnyObject>?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(fixJsonData(data), options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
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
                                let issue_description = issue_fields_Dict["description"] as? String // issue_description can acutally be empty
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
        var newErrors = [Error]()
        let response_code = response.statusCode
        var jsonObject: Dictionary<String, AnyObject>?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(fixJsonData(data), options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
        }
        catch {  }
        guard let jsonObjectRoot = jsonObject else {
            return nil
        }
        if let messages = jsonObjectRoot["errorMessages"] as? Array<AnyObject> {
            for message in messages {
                if let theMessage = message as? String {
                    newErrors.append(Error(error_code: response_code ,error_message: theMessage))
                }
            }
        }
        
        if let errors = jsonObjectRoot["errors"] as? Dictionary<String,String> {
            for (target, error) in errors {
                newErrors.append(Error(error_code: response_code, error_message: "Problem with \(target): \(error)"))
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
        var newTransitions = [Transition]()
        var jsonObject: Dictionary<String, AnyObject>?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(fixJsonData(data), options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
        }
        catch {  }
        guard let jsonObjectRoot = jsonObject else {
            return nil
        }
        guard let items = jsonObjectRoot["transitions"] as? Array<AnyObject> else {
            return nil
        }
        for item in items {
            if let itemDict = item as? Dictionary<String,AnyObject> {
                if let transition_id = itemDict["id"] as? String,
                    let transition_name = itemDict["name"] as? String,
                    let transition_fields = itemDict["fields"] as? Dictionary<String,AnyObject>,
                    let transition_toDict = itemDict["to"] as? Dictionary<String,AnyObject> {
                    if let transition_target = transition_toDict["name"] as? String {
                        let requiredFields = JIRARequiredFields(fields: transition_fields)
                        newTransitions.append(Transition(transition_id: transition_id, transition_name: transition_name, target_status: transition_target, required_fields: (requiredFields?.requiredFields)))
                    }
                }
            }
        }
        self.init(transitions: newTransitions)
    }
}

func fixJsonData (data: NSData) -> NSData {
    var dataString = String(data: data, encoding: NSUTF8StringEncoding)!
    dataString = dataString.stringByReplacingOccurrencesOfString("\\'", withString: "'")
    return dataString.dataUsingEncoding(NSUTF8StringEncoding)!
}