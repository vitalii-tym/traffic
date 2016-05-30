//
//  File.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.

import Foundation

struct Project {
    var id: String
    var key: String
    var projectTypeKey: String
    var name: String
    var versions: [Version]
    var boards: [Board]
}

struct Version {
    var id: String
    var description: String?
    var name: String
    var archived: Bool
    var released: Bool
    var overdue: Bool?
    var projectID: Int
}

struct Task {
    var task_key: String
    var task_type: String
    var task_summary: String
    var task_priority: String
    var task_description: String? //optional, because some tasks might have no description (JIRA returns "null")
    var task_status: String
    var task_assignee: String? // The issue might be Unassigned
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

struct Board {
    var id: Int
    var name: String
    var type: String
}

struct MetadataProject {
    var name: String
    var key: String
    var id: String
    var issueTypes: [IssueType]
}

class JIRAcurrentUser {
    var name: String = ""
    init? (data: NSData) {
        var jsonObject: Dictionary<String, AnyObject>?
        do {
        jsonObject = try NSJSONSerialization.JSONObjectWithData(fixJsonData(data), options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
        }
        catch { }
        guard let jsonObjectRoot = jsonObject else {
            return nil
        }
        guard let userName = jsonObjectRoot["name"] as? String else {
            return nil
        }
        self.name = userName
    }
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
                        let schemaDict = fieldDict["schema"] as? Dictionary<String,AnyObject>,
                        let type = schemaDict["type"] as? String {
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

class JIRAProjects {
    var projectsList: [Project]
    
    init (projects newProjectsList: [Project]){
        self.projectsList = newProjectsList
    }
    
    convenience init? (data: NSData) {
        var formedProjectsList = [Project]()
        var jsonObject: Array<AnyObject>?
        
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(fixJsonData(data), options: NSJSONReadingOptions(rawValue: 0)) as? Array<AnyObject>
        }
        catch { }
        
        guard let jsonObjectRoot = jsonObject else {
            return nil
        }
        
        for proj in jsonObjectRoot {
            if let theProjectDict = proj as? Dictionary<String, AnyObject> {
                if let projectID = theProjectDict["id"] as? String,
                    let projectKey = theProjectDict["key"] as? String,
                    let projectTypeKey = theProjectDict["projectTypeKey"] as? String,
                    let projectName = theProjectDict["name"] as? String {
                    formedProjectsList.append(Project(id: projectID, key: projectKey, projectTypeKey: projectTypeKey, name: projectName, versions: [], boards: []))
                }
            }
        }
        self.init(projects: formedProjectsList)
    }
    
    func setVersionsForProject(data: NSData, projectID: String) {
        var versionsToSet = [Version]()
        var jsonObject: Array<AnyObject>?
        
        do { jsonObject = try NSJSONSerialization.JSONObjectWithData(fixJsonData(data), options: NSJSONReadingOptions(rawValue: 0)) as? Array<AnyObject>  }
        catch { }
        
        guard let jsonObjectRoot = jsonObject else { return }
        
        for version in jsonObjectRoot {
            if let theVersionDict = version as? Dictionary<String, AnyObject> {
                if let versionID = theVersionDict["id"] as? String,
                    let versionName = theVersionDict["name"] as? String,
                    let versionArchived = theVersionDict["archived"] as? Bool,
                    let versionReleased = theVersionDict["released"] as? Bool,
                    let versionProjID = theVersionDict["projectId"] as? Int {
                        let versionDescription = theVersionDict["description"] as? String
                        let versionOverdue = theVersionDict["overdue"] as? Bool
                        versionsToSet.append(Version(id: versionID, description: versionDescription, name: versionName, archived: versionArchived, released: versionReleased, overdue: versionOverdue, projectID: versionProjID))
                }
            }
        
        for (index, project) in self.projectsList.enumerate() {
            if project.id == projectID {
                self.projectsList[index].versions = versionsToSet
                break //We expect that there can't be more than one project with the same ID, so no need to continue once we found that one
            }
            }
        }
    }

    func getVersionsForProject(projectID: String) -> [Version] {
        var versionsToGet = [Version]()
        for project in self.projectsList {
            if project.id == projectID {
                versionsToGet = project.versions
                break
            }
        }
        return versionsToGet
    }
    
    func setBoardsForProject(data: NSData, projectID: String) {
        var boardsToSet = [Board]()
        var jsonObject: Dictionary<String, AnyObject>?
        
        do { jsonObject = try NSJSONSerialization.JSONObjectWithData(fixJsonData(data), options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject> }
        catch { }
        
        guard let jsonObjectRoot = jsonObject else { return }
        
        if let boardsArray = jsonObjectRoot["values"] as? Array<AnyObject> {
            for board in boardsArray {
                if let boardID = board["id"] as? Int,
                    let boardName = board["name"] as? String,
                    let boardType = board["type"] as? String {
                        boardsToSet.append(Board(id: boardID, name: boardName, type: boardType))
                }
            }
        }
        
        for (index, project) in self.projectsList.enumerate() {
            if project.id == projectID {
                self.projectsList[index].boards = boardsToSet
                break //We expect that there can't be more than one project with the same ID, so no need to continue once we found that one
            }
        }
    }
    
    func getBoardsForProject(projectID: String) -> [Board] {
        var boardsToGet = [Board]()
        for project in self.projectsList {
            if project.id == projectID {
                boardsToGet = project.boards
                break
            }
        }
        return boardsToGet
    }
}

class JIRAMetadataToCreateIssue {
    var availableProjects: [MetadataProject]
    
    init (metadata newMetadata: [MetadataProject]) {
        self.availableProjects = newMetadata
    }
    
    convenience init? (data: NSData) {
        var newAvailableProjects = [MetadataProject]()
        
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
                        theIssueTypes = theProjectDict["issuetypes" ?? "issueTypes"] as? Array<AnyObject> {
                    
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
                    newAvailableProjects.append(MetadataProject(name: projName, key: projKey, id: projID, issueTypes: issueTypesList))
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
                           issue_summary = issue_fields_Dict["summary"] as? String,
                            issue_typeDict = issue_fields_Dict["issuetype"] as? Dictionary<String,AnyObject> {
                                let issue_assigneeDict = issue_fields_Dict["assignee"] as? Dictionary<String,AnyObject> // Assignee will be absent if the issue is Unsassigned
                                let issue_description = issue_fields_Dict["description"] as? String // issue_description can acutally be empty
                                if let issue_priority = issue_priority_Dict["name"] as? String,
                                    issue_type = issue_typeDict["name"] as? String,
                                    issue_status = issue_status_Dict["name"] as? String {
                                        let issue_assignee = issue_assigneeDict?["displayName"] as? String
                                        newTasks.append(Task(task_key: issue_key ?? "(no title)",
                                            task_type: issue_type,
                                            task_summary: issue_summary,
                                            task_priority: issue_priority,
                                            task_description: issue_description,
                                            task_status: issue_status,
                                            task_assignee: issue_assignee))
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

func generateJSONString(prefix: String, inputDataForGeneration: Dictionary<String, [AnyObject]>) -> String {
    if !inputDataForGeneration.isEmpty {
        var generatedString = prefix
        if prefix == "" {
            generatedString += "{ \"fields\": {"
        } else {
            generatedString = String(generatedString.characters.dropLast()) + ", \"fields\": {"
        }
        for field in inputDataForGeneration {
            generatedString += "\"\(field.0)\": "
            switch field.0 { // TODO: We are tied to actual field names here. Need to think about changing to field types - this would be much more universal approach.
            case "reporter", "resolution":
                generatedString += " { \"name\" : \"\(field.1[0]["name"] as! String)\" },"
            case "issuetype", "project":
                generatedString += " { \"id\" : \(field.1[0]["id"] as! String) },"
            case "summary", "customfield_10006":
                generatedString += "\"\(field.1[0] as! String)\","
            default:
                generatedString += "<unknown field>"
            }
        }
        generatedString = String(generatedString.characters.dropLast()) + "}}"
        return generatedString
    } else {
        return prefix
    }
}

func fixJsonData (data: NSData) -> NSData {
    var dataString = String(data: data, encoding: NSUTF8StringEncoding)!
    dataString = dataString.stringByReplacingOccurrencesOfString("\\'", withString: "'")
    return dataString.dataUsingEncoding(NSUTF8StringEncoding)!
}