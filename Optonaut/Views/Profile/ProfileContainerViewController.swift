//
//  ProfileContainerViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class ProfileContainerViewController: UIViewController {
    
    let tableViewController: ProfileTableViewController
    let tableView: UIView
    let headerViewController: ProfileHeaderViewController
    let headerView: UIView
    
    required init(personId: Int) {
        tableViewController = ProfileTableViewController(personId: personId)
        tableView = tableViewController.view
        
        headerViewController = ProfileHeaderViewController(personId: personId)
        headerView = headerViewController.view
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(tableViewController)
        addChildViewController(headerViewController)
        
        tableViewController.scrollCallback = { offsetY in
            var rect = self.headerView.frame
            let limit: CGFloat = 280 - 60
            if offsetY < 0 {
                rect.origin.y = 0
            } else if offsetY > limit {
                rect.origin.y = -limit
            } else {
                rect.origin.y = -offsetY
            }
            self.headerView.frame = rect
        }
        
        view.addSubview(tableView)
        view.addSubview(headerView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        headerView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        headerView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        headerView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        headerView.autoSetDimension(.Height, toSize: 280)
        
//        let height = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        
        super.updateViewConstraints()
    }
    
}