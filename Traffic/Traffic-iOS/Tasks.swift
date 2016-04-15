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
    var task_name: String
    var task_summary: String
    var task_priority: String
    var task_description: String
    var task_status: String
}

class Tasks {
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
                guard let itemDict = item as? Dictionary<String,AnyObject> else {
                    continue
                }
                guard let issue_key = itemDict["key"] as? String else {
                    continue
                }
                guard let issue_fields_Dict = itemDict["fields"] as? Dictionary<String,AnyObject> else {
                    continue
                }
                guard let issue_description = issue_fields_Dict["description"] as? String else {
                    continue
                }
                guard let issue_priority_Dict = issue_fields_Dict["priority"] as? Dictionary<String,AnyObject> else {
                    continue
                }
                guard let issue_priority = issue_priority_Dict["name"] as? String else {
                    continue
                }
                guard let issue_status_Dict = issue_fields_Dict["status"] as? Dictionary<String,AnyObject> else {
                    continue
                }
                guard let issue_status = issue_status_Dict["name"] as? String else {
                    continue
                }
                guard let issue_summary = issue_fields_Dict["summary"] as? String else {
                    continue
                }
            newTasks.append(Task(task_name: issue_key ?? "(no title)", task_summary: issue_summary, task_priority: issue_priority, task_description: issue_description, task_status: issue_status))
        }
        
        self.init(tasks: newTasks)
    }
    
    func addTask (theTask: Task) {
        self.taskslist.append(theTask)
    }
}