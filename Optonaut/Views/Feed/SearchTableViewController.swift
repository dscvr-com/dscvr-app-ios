//
//  SearchTableViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import Alamofire

class SearchTableViewController: OptographTableViewController, RedNavbar {
    
    let searchBar = UISearchBar()
    let viewModel = SearchViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Search"
        
        searchBar.delegate = self
        searchBar.placeholder = "What are you looking for?"
        
        view.addSubview(searchBar)
        
        viewModel.results.producer.start(
            next: { results in
                self.items = results
                self.tableView.reloadData()
            }
        )
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
        searchBar.becomeFirstResponder()
    }
    
    override func updateViewConstraints() {
        searchBar.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        searchBar.autoSetDimension(.Height, toSize: 44)
        
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0))
        
        super.updateViewConstraints()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// MARK: - UISearchBarDelegate
extension SearchTableViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText.value = searchText
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
}