//
//  Extensions.swift
//  Traffic
//
//  Created by Vitaliy Tim on 5/20/16.
//  Copyright © 2016 Vitaliy Timoshenko. All rights reserved.
//

import UIKit

extension UIViewController {
    var activityIndicatorTag: Int { return 999999 }
}

extension UIViewController {
    func startActivityIndicator(style: UIActivityIndicatorViewStyle = .WhiteLarge, location: CGPoint? = nil, activityText: String = "") {
        let loc = location ?? self.view.center
        dispatch_async(dispatch_get_main_queue(), {
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: style)
            activityIndicator.tag = self.activityIndicatorTag
            activityIndicator.center = loc
            activityIndicator.frame = UIScreen.mainScreen().bounds
            activityIndicator.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.5)
            activityIndicator.clipsToBounds = true
            activityIndicator.hidesWhenStopped = true
            let loadingLabel: UILabel = UILabel.init(frame: CGRectMake(UIScreen.mainScreen().bounds.minX,
                                                                        UIScreen.mainScreen().bounds.minY,
                                                                        UIScreen.mainScreen().bounds.width - 20,
                                                                        UIScreen.mainScreen().bounds.height))
            loadingLabel.text = activityText
            activityIndicator.addSubview(loadingLabel)
            loadingLabel.backgroundColor = UIColor.clearColor()
            loadingLabel.textColor = UIColor.whiteColor()
            loadingLabel.adjustsFontSizeToFitWidth = true
            loadingLabel.textAlignment = NSTextAlignment.Center
            loadingLabel.numberOfLines = 0
            loadingLabel.lineBreakMode = .ByWordWrapping
            loadingLabel.sizeToFit()
            loadingLabel.center = CGPoint(x: loc.x, y: loc.y + 50)
            
            activityIndicator.startAnimating()
            self.view.addSubview(activityIndicator)
        })
    }
}

extension UIViewController {
    func stopActivityIndicator() {
        dispatch_async(dispatch_get_main_queue(), {
            if let activityIndicator = self.view.subviews.filter({
                $0.tag == self.activityIndicatorTag}).first as? UIActivityIndicatorView {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
            }
        })
    }
}