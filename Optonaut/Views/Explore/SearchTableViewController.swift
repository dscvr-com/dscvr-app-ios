//
//  SearchTableViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import Alamofire
import Mixpanel

class SearchTableViewController: OptographTableViewController, RedNavbar {
    
    private let searchBar = UISearchBar()
    
    private let viewModel = SearchViewModel()
    private var hashtags: [Hashtag] = []
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Search"
        
        tableView.registerClass(SearchHashtagTableViewCell.self, forCellReuseIdentifier: "search-hashtag-cell")
        tableView.registerClass(SearchHeadTableViewCell.self, forCellReuseIdentifier: "search-head-cell")
        
        searchBar.delegate = self
        searchBar.placeholder = "What are you looking for?"
        
        view.addSubview(searchBar)
        
        viewModel.results.producer
            .on(
                next: { results in
                    let itemsWasEmpty = self.items.isEmpty
                    self.items = results.optographs
                    
                    if itemsWasEmpty || self.items.isEmpty {
                        self.tableView.reloadData()
                    } else {
                        self.tableView.beginUpdates()
                        if !results.delete.isEmpty {
                            self.tableView.deleteRowsAtIndexPaths(results.delete.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                        }
                        if !results.update.isEmpty {
                            self.tableView.reloadRowsAtIndexPaths(results.update.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                        }
                        if !results.insert.isEmpty {
                            self.tableView.insertRowsAtIndexPaths(results.insert.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                        }
                        self.tableView.endUpdates()
                    }
                }
            )
            .start()
        
        viewModel.hashtags.producer.startWithNext { [weak self] hashtags in
            self?.hashtags = hashtags
            self?.tableView.reloadData()
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Search")
        
        updateNavbarAppear()
//        searchBar.becomeFirstResponder()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Search")
    }
    
    override func updateViewConstraints() {
        searchBar.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        searchBar.autoSetDimension(.Height, toSize: 44)
        
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0))
        
        super.updateViewConstraints()
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if searchBar.text!.isEmpty {
            return indexPath.row == 0 ? 70 : 35
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if searchBar.text!.isEmpty {
            if indexPath.row == 0 {
                let cell = self.tableView.dequeueReusableCellWithIdentifier("search-head-cell") as! SearchHeadTableViewCell
                return cell
            } else {
                let cell = self.tableView.dequeueReusableCellWithIdentifier("search-hashtag-cell") as! SearchHashtagTableViewCell
                cell.textLabel?.text = "#" + hashtags[indexPath.row - 1].name
                return cell
            }
        } else {
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text!.isEmpty {
            return viewModel.hashtags.value.count + 1
        } else {
            return items.count
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searchBar.text!.isEmpty {
            let hashtag = "#" + hashtags[indexPath.row - 1].name
            searchBar.text = hashtag
            viewModel.searchText.value = hashtag
            tableView.reloadData()
        }
    }
    
}

// MARK: - UISearchBarDelegate
extension SearchTableViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if viewModel.searchText.value.isEmpty {
            tableView.reloadData()
        }
        viewModel.searchText.value = searchText
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
}