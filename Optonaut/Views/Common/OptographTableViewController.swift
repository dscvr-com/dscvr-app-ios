//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import Alamofire

class OptographTableViewController: UIViewController {
    
    var items = [Optograph]()
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(OptographTableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
    }
    
}

// MARK: - UITableViewDelegate
extension OptographTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return view.frame.width * 5 / 4 + 79
    }
    
}

// MARK: - UITableViewDataSource
extension OptographTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! OptographTableViewCell
        cell.navigationController = navigationController as? NavigationController
        cell.bindViewModel(items[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
}