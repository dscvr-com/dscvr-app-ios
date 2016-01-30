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
    func showOptions(optographID: UUID, deleteCallback: (() -> ())?)
}

extension OptographOptions {
    
    func showOptions(optographID: UUID, deleteCallback: (() -> ())? = nil) {
        
        let optographBox = Models.optographs[optographID]!
        let optograph = optographBox.model
        let person = Models.persons[optograph.personID]!.model
        
        let actionAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        if person.ID == SessionService.personID {
            actionAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { _ in
                let confirmAlert = UIAlertController(title: "Are you sure?", message: "Do you really want to delete this Optograph? You cannot undo this.", preferredStyle: .Alert)
                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                confirmAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { _ in
                    PipelineService.stopStitching()
                    optographBox.insertOrUpdate { box in
                        box.model.deletedAt = NSDate()
                    }
                    deleteCallback?()
                }))
                self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
            }))
        } else if SessionService.isLoggedIn {
            actionAlert.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { _ in
                let confirmAlert = UIAlertController(title: "Are you sure?", message: "This action will message one of the moderators.", preferredStyle: .Alert)
                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                confirmAlert.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { _ in
                    optograph.report().start()
                }))
                self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
            }))
        }
        
        if optograph.isPublished {
            actionAlert.addAction(UIAlertAction(title: "Share", style: .Default, handler: { _ in
                if let url = NSURL(string: "http://opto.space/\(optograph.shareAlias)") {
                    let textToShare = "Check out this awesome Optograph of \(person.displayName) on \(url)"
                    let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                    activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                    
                    self.navigationController?.presentViewController(activityVC, animated: true, completion: nil)
                }
            }))
        
            actionAlert.addAction(UIAlertAction(title: "Copy sharing URL", style: .Default, handler: { _ in
                UIPasteboard.generalPasteboard().string = "http://opto.space/\(optograph.shareAlias)"
            }))
        }
        
        actionAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        navigationController?.presentViewController(actionAlert, animated: true, completion: nil)
    }
    
}