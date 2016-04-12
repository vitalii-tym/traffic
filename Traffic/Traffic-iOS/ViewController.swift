//
//  ViewController.swift
//  Traffic-iOS
//
//  Created by Vitaliy Tim on 4/11/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    let tasks: Tasks = Tasks.init()
    var urlSession: NSURLSession!
    var request_data: NSData!
    var request_response: NSURLResponse!
    var request_error: NSError!
    
    @IBOutlet weak var view_collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tasks.createDummyTasks() //temporary creating some dummy data before we can get real data
        
        login()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.urlSession = NSURLSession(configuration: configuration)
        
        let request = NSURLRequest(URL: NSURL(string: "https://jira.atlassian.com/projects/DEMO")!)
        let dataTask: NSURLSessionDataTask = self.urlSession.dataTaskWithRequest(request) { (data, response, error) -> Void in
                self.request_data = data
                self.request_response = response
                self.request_error = error
                if error == nil && data != nil {
                    self.tasks.addTask(Task(task_name: response!.description, task_description: response!.debugDescription))
                    }
                self.view_collectionView.reloadData() //WARNING: this line supposedly results in auto-layout engine crashes. To be investigated.
            }
        dataTask.resume()
        
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.urlSession.invalidateAndCancel()
        self.urlSession = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tasks.taskslist.count
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TaskCell", forIndexPath: indexPath) as! aTask
        
        cell.label_name.text = tasks.taskslist[indexPath.row].task_name
        cell.label_description.text = tasks.taskslist[indexPath.row].task_description
        
        return cell
    }
    
}

