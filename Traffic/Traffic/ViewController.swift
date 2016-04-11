//
//  ViewController.swift
//  Traffic
//
//  Created by Vitaliy Timoshenko on 2/26/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBOutlet weak var view_collectionView: UICollectionView!
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

