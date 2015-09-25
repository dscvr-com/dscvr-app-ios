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
        let imageHeight = view.frame.width * 3 / 4
        let barHeight: CGFloat = 42
        let spacing: CGFloat = 8
        return imageHeight + barHeight + spacing
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