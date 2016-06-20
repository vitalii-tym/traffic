//
//  SettingsViewController.swift
//  Easy Jira
//
//  Created by Vitaliy Tim on 6/17/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {

    @IBAction func button_ClearCache_pressed(sender: UIButton) {
        let fileManager = NSFileManager.defaultManager()
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        do {
            let filePaths = try fileManager.contentsOfDirectoryAtPath(dirPath)
            for filePath in filePaths {
                try fileManager.removeItemAtPath(dirPath + "/" + filePath)
            }
        } catch {
            print("Could not clear cache: \(error)")
        }
    }
    
    @IBAction func button_Done_pressed(sender: UIButton) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
}