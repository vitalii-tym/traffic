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
    func isActivityIndicatorActive() -> Bool {
        if self.view.viewWithTag(self.activityIndicatorTag) != nil {
            return true
        } else {
            return false
        }
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

extension UIViewController {
    func showMessage(text: String, mood: String) {
        let messengerView = UIView.init(frame: CGRect(x: 20, y: -25, width: 280, height: 25))
        messengerView.layer.cornerRadius = 5
        messengerView.alpha = 0.9
        let label: UILabel = UILabel()
        let effect = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        effect.frame = messengerView.bounds
        messengerView.backgroundColor = UIColor.clearColor()
        messengerView.addSubview(effect)
        label.frame = CGRectMake(0, 0, 280, 25)
        label.textAlignment = NSTextAlignment.Center
        label.text = text
        label.textAlignment = .Center
        label.font = UIFont.systemFontOfSize(12.0)
        switch mood {
        case "Good":
            label.textColor = UIColor(colorLiteralRed: 0, green: 0.4, blue: 0, alpha: 1)
        case "Bad":
            label.textColor = UIColor(colorLiteralRed: 0.4, green: 0, blue: 0, alpha: 1)
        default:
            label.textColor = UIColor(colorLiteralRed: 0, green: 0.4, blue: 0, alpha: 1)
        }
        label.adjustsFontSizeToFitWidth = true
        label.hidden = false
        messengerView.addSubview(label)
        self.view.addSubview(messengerView)
        UIView.animateWithDuration(1.0,
                                   delay: 0,
                                   usingSpringWithDamping: 0.5,
                                   initialSpringVelocity: 10.0,
                                   options: UIViewAnimationOptions.CurveLinear,
                                   animations: { messengerView.frame = CGRect(x: 20, y: 60, width: 280, height: 25) },
                                   completion: nil)
        UIView.animateWithDuration(0.5,
                                   delay: 3.0,
                                   options: [],
                                   animations: { messengerView.frame = CGRect(x: 20, y: -25, width: 280, height: 25) },
                                   completion: { finished in messengerView.removeFromSuperview()})
    }
}

extension String {
    func stripSpecialCharacters() -> String {
        let okayChars : Set<Character> = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-*=(),.:!_".characters)
        return String(self.characters.filter {okayChars.contains($0) })
    }
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
    var result = [Element]()
    
    for value in self {
        if result.contains(value) == false {
            result.append(value)
            }
        }
        return result
    }
}