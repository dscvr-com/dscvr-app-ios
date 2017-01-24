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
        
        let actionAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        actionAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { _ in
            let confirmAlert = UIAlertController(title: "Are you sure?", message: "Do you really want to delete this Optograph? You cannot undo this.", preferredStyle: .Alert)
            confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
            confirmAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { _ in
                PipelineService.stopStitching()
                optographBox.insertOrUpdate { box in
                    print("date today \(NSDate())")
                    print(box.model.ID)
                    return box.model.deletedAt = NSDate()
                }
                deleteCallback?()
            }))
            self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
        }))
        
        actionAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        navigationController?.presentViewController(actionAlert, animated: true, completion: nil)
    }
    
}