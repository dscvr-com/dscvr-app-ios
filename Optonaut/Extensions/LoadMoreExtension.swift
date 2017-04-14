//
//  LoadMore.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/3/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

protocol LoadMore: UITableViewDelegate {
    
    associatedtype Item
    
    var items: [Item] { get }
    var tableView: UITableView { get }
    
    func checkRow(_ indexPath: IndexPath, success: () -> Void)
    
    func tableView(_ tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath)
    
}

private var lastLoadMoreRowAssociationKey: UInt8 = 0

extension LoadMore where Self: UIViewController {
    
    var lastLoadMoreRow: Int {
        get {
            return objc_getAssociatedObject(self, &lastLoadMoreRowAssociationKey) as? Int ?? 0
        }
        set(newValue) {
            objc_setAssociatedObject(self, &lastLoadMoreRowAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func checkRow(_ indexPath: IndexPath, success: () -> Void) {
        let preloadOffset = 4
        if indexPath.row > lastLoadMoreRow && indexPath.row > items.count - preloadOffset {
            success()
            lastLoadMoreRow = items.count - 1
        }
    }
    
}
