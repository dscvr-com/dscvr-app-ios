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

class ProfileTableViewController: OptographTableViewController {
    
    var viewModel: OptographsViewModel
    
    required init(userId: Int) {
        viewModel = OptographsViewModel(source: "users/\(userId)/optographs")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        viewModel = OptographsViewModel(source: "")
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.results.producer.start(next: { results in
            self.items = results
            self.tableView.reloadData()
        })
        
        viewModel.resultsLoading.put(true)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
}
