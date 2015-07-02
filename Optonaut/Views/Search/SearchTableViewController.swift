//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import RealmSwift
import Alamofire
import SwiftyJSON

class SearchTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var items = [Optograph]()
    let tableView = UITableView()
    let searchBar = UISearchBar()
    var navController: UINavigationController?
    
    let viewModel = SearchViewModel()
    
    required init(initialKeyword: String, navController: UINavigationController?) {
        super.init(nibName: nil, bundle: nil)
        self.navController = navController
        searchBar.text = initialKeyword
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Search"
        
        searchBar.delegate = self
        searchBar.placeholder = "What are you looking for?"
        
        view.addSubview(searchBar)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(OptographTableViewCell.self, forCellReuseIdentifier: "cell")
        
        viewModel.results.producer.start(
            next: { results in
                self.items = results
                self.tableView.reloadData()
            }
        )
        
        viewModel.searchText.put(searchBar.text)
        
        view.addSubview(tableView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // TODO: focus doesn't work on first load
        searchBar.becomeFirstResponder()
    }
    
    override func updateViewConstraints() {
        searchBar.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        searchBar.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        searchBar.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        searchBar.autoSetDimension(.Height, toSize: 44)
        
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0))
        
        super.updateViewConstraints()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let textString = (items[indexPath.row].text + items[indexPath.row].user!.userName) as NSString
        let textBounds = textString.sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(17)])
        let numberOfLines = ceil(textBounds.width / (view.frame.width - 30))
        return view.frame.width + 70 + numberOfLines * 28
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! OptographTableViewCell
        cell.navController = navController
        cell.bindViewModel(items[indexPath.row])
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText.put(searchText)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
}



