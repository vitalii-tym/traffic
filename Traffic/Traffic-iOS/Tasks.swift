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
    let task_name: String
    let task_summary: String
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
        catch {
        
        }
        
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
            
                guard let issue_summary = issue_fields_Dict["summary"] as? String else {
                    continue
                }
            
                newTasks.append(Task(task_name: issue_key ?? "(no title)", task_summary: issue_summary))
        }
                
        self.init(tasks: newTasks)
    }
    
    func addTask (theTask: Task) {
        self.taskslist.append(theTask)
    }
    
    func createDummyTasks () {  //temporary for testing purposes
        self.addTask(Task(task_name: "test1",task_summary: "tttt"))
        self.addTask(Task(task_name: "test2",task_summary: "ttfdsfsdtt"))
        self.addTask(Task(task_name: "test3",task_summary: "ttsdfsdfsdtt"))
    }
}