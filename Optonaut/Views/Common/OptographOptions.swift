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
    func showOptions(_ optographID: UUID, deleteCallback: (() -> ())?)
}

extension OptographOptions {
    
    func showOptions(_ optographID: UUID, deleteCallback: (() -> ())? = nil) {
        
        let optographBox = Models.optographs[optographID]!
        
        let actionAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            let confirmAlert = UIAlertController(title: "Are you sure?", message: "Do you really want to delete this Optograph? You cannot undo this.", preferredStyle: .alert)
            confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in return }))
            confirmAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                PipelineService.stopStitching()
                //optographBox.insertOrUpdate { box in
                //    print("date today \(Date())")
                //    print(box.model.ID)
                let optographIDDict:[String: String] = ["id": optographID]
                let name = Notification.Name(rawValue: deletedOptographNotificationKey)
                NotificationCenter.default.post(name: name, object: self, userInfo: optographIDDict)
                //    return box.model.deletedAt = Date()
                //}
                deleteCallback?()
            }))
            self.navigationController?.present(confirmAlert, animated: true, completion: nil)
        }))
        
        actionAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in return }))
        
        navigationController?.present(actionAlert, animated: true, completion: nil)
    }
    
}
