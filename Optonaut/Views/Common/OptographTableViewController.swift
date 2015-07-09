//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import Alamofire
import Refresher

class OptographTableViewController: UIViewController {
    
    var items = [Optograph]()
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
        
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
        let attributes = [NSFontAttributeName: UIFont.robotoOfSize(13, withType: .Light)]
        let textAS = NSAttributedString(string: items[indexPath.row].text, attributes: attributes)
        let tmpSize = CGSize(width: view.frame.width - 38, height: 100000)
        let textRect = textAS.boundingRectWithSize(tmpSize, options: [.UsesFontLeading, .UsesLineFragmentOrigin], context: nil)
        let imageHeight = view.frame.width * 0.45
        let restHeight = CGFloat(100) // includes avatar, name, bottom line and spacing
        return imageHeight + restHeight + textRect.height
    }
    
}

// MARK: - UITableViewDataSource
extension OptographTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! OptographTableViewCell
        cell.navigationController = navigationController
        cell.bindViewModel(items[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
}