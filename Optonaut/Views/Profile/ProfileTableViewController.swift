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
    
    private let viewModel: OptographsViewModel
    
    // subviews
    private let blankHeaderView = UIView()
    
    var scrollCallback: ((CGFloat) -> ())?
    
    required init(personId: Int) {
        viewModel = OptographsViewModel(personId: personId)
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
        
        blankHeaderView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 280)
        tableView.tableHeaderView = blankHeaderView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentInset = UIEdgeInsetsZero
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollCallback?(tableView.contentOffset.y)
    }
    
}
