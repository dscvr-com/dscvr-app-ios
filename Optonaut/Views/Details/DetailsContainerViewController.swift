//
//  DetailsContainerView.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class DetailsContainerViewController: UIViewController {
    
    let tableViewController: CommentTableViewController
    let tableView: UIView
    let headerViewController: DetailsHeaderViewController
    let headerView: UIView
    
    required init(optographId: Int) {
        tableViewController = CommentTableViewController(optographId: optographId)
        tableView = tableViewController.view
        
        headerViewController = DetailsHeaderViewController(optographId: optographId)
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
        
        view.addSubview(tableView)
        view.addSubview(headerView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        headerView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        headerView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        headerView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        headerView.autoSetDimension(.Height, toSize: 280)
        
        super.updateViewConstraints()
    }
    
}