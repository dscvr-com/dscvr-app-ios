//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class HashtagTableViewController: OptographTableViewController, RedNavbar, UniqueView {
    
    private let viewModel = SearchViewModel()
    
    private let hashtag: String
    
    let uniqueIdentifier: String
    
    required init(hashtag: String) {
        uniqueIdentifier = "hashtag-\(hashtag)"
        
        self.hashtag = hashtag
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "#\(hashtag)"
        
        viewModel.searchText.value = hashtag
        
        viewModel.results.producer.startWithNext { results in
            self.items = results
            self.tableView.reloadData()
        }
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
}