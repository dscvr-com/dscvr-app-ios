//
//  OptographOptions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/8/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

protocol OptographOptions: class {
    var navigationController: NavigationController? { get }
    func didTapOptions()
    func showOptions(optograph: Optograph)
}

extension OptographOptions {
    
    func showOptions(var optograph: Optograph) {
        let actionAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        if SessionService.sessionData?.id == optograph.person.id {
            actionAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { _ in
                let confirmAlert = UIAlertController(title: "Are you sure?", message: "Do you really want to delete this Optograph? You cannot undo this.", preferredStyle: .Alert)
                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                confirmAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { _ in
                    optograph.delete().startWithCompleted {
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }))
                self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
            }))
        }
        
        if !optograph.isPublished {
            actionAlert.addAction(UIAlertAction(title: "Publish", style: .Default, handler: { _ in
                optograph.publish().start()
            }))
        }
        
        actionAlert.addAction(UIAlertAction(title: "Share", style: .Default, handler: { _ in
            if let url = NSURL(string: "http://opto.space/\(optograph.id)") {
                let textToShare = "Check out awesome this Optograph of \(optograph.person.displayName) on \(url)"
                let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                
                self.navigationController?.presentViewController(activityVC, animated: true, completion: nil)
            }
        }))
        
        actionAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        navigationController?.presentViewController(actionAlert, animated: true, completion: nil)
    }
    
}