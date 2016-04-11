//
//  File.swift
//  Traffic
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

struct Task {
    let task_name: String
    let task_description: String
}

class Tasks {
    var taskslist: [Task]
    
    init () {
        self.taskslist = []
    }
    
    func addTask (theTask: Task) {
        self.taskslist.append(theTask)
    }
    
    func createDummyTasks () {  //temporary for testing purposes
        self.addTask(Task(task_name: "test1",task_description: "tttt"))
        self.addTask(Task(task_name: "test2",task_description: "ttfdsfsdtt"))
        self.addTask(Task(task_name: "test3",task_description: "ttsdfsdfsdtt"))
    }
}