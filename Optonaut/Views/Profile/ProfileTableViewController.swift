//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import Refresher

class ProfileTableViewController: OptographTableViewController, TransparentNavbar {
    
    let viewModel: OptographsViewModel
    
    let headerView: UIView
    
    var didSetConstraints = false
    
    required init(personId: Int) {
        let profileheaderViewController = ProfileHeaderViewController(personId: personId)
        headerView = profileheaderViewController.view
        
        viewModel = OptographsViewModel(source: "persons/\(personId)/optographs")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.results.producer.start(next: { results in
            self.items = results
            self.tableView.reloadData()
        })
        
        viewModel.resultsLoading.value = true
        
        headerView.autoresizingMask = .None
        headerView.frame = CGRect(x: 0, y: -64, width: view.frame.width, height: 280 - 64)
        tableView.tableHeaderView = headerView
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func updateViewConstraints() {
        if !didSetConstraints {
            tableView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
            tableView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
            tableView.autoMatchDimension(.Height, toDimension: .Height, ofView: view)
            
            headerView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
            headerView.autoSetDimension(.Height, toSize: 280)
            
            didSetConstraints = true
        }
        
        super.updateViewConstraints()
    }
    
//    func scrollViewDidScroll(scrollView: UIScrollView) {
//        var rect = headerView.frame
//        print(rect)
//        rect.origin.y = tableView.contentOffset.y
//        print(rect)
//        headerView.frame = rect
//    }
    
}
