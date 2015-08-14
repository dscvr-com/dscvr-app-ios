//
//  CommentTableViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import PureLayout_iOS

class CommentTableViewController: UIViewController, TransparentNavbar {
    
    let viewModel: CommentsViewModel
    
    var items = [Comment]()
    
    let tableView = UITableView()
    let blankHeaderView = UIView()
    
    required init(optographId: Int) {
        viewModel = CommentsViewModel(optographId: optographId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(CommentTableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        
        blankHeaderView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 280)
        tableView.tableHeaderView = blankHeaderView
        
        viewModel.results.producer.start(next: { _ in
            self.tableView.reloadData()
        })
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        tableView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        tableView.autoMatchDimension(.Height, toDimension: .Height, ofView: view)
        
        super.updateViewConstraints()
    }
    
}

// MARK: - UITableViewDelegate
extension CommentTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        let attributes = [NSFontAttributeName: UIFont.robotoOfSize(13, withType: .Light)]
//        let textAS = NSAttributedString(string: items[indexPath.row].description_, attributes: attributes)
//        let tmpSize = CGSize(width: view.frame.width - 38, height: 100000)
//        let textRect = textAS.boundingRectWithSize(tmpSize, options: [.UsesFontLeading, .UsesLineFragmentOrigin], context: nil)
//        let imageHeight = view.frame.width * 0.45
//        let restHeight = CGFloat(100) // includes avatar, name, bottom line and spacing
//        return imageHeight + restHeight + textRect.height
        return 50
    }
    
}

// MARK: - UITableViewDataSource
extension CommentTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! CommentTableViewCell
        cell.navigationController = navigationController
        cell.bindViewModel(viewModel.results.value[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.results.value.count
    }
    
}