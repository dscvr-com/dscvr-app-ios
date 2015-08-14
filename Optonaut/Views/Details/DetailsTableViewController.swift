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
import Refresher

class DetailsTableViewController: UIViewController, TransparentNavbar {
    
    let viewModel: CommentsViewModel
    
    var comments = [Comment]()
    
    // subviews
    let tableView = UITableView()
    let headerView: UIView
    
    required init(optographId: Int) {
        let detailsheaderViewController = DetailsHeaderViewController(optographId: optographId)
        headerView = detailsheaderViewController.view
        
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
        
        headerView.frame = CGRect(x: 0, y: -64, width: view.frame.width, height: 580 - 64)
        tableView.tableHeaderView = headerView
        
        viewModel.results.producer.start(next: { comments in
            self.comments = comments
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
        
        headerView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        headerView.autoSetDimension(.Height, toSize: 580)
        
        super.updateViewConstraints()
    }
    
}

// MARK: - UITableViewDelegate
extension DetailsTableViewController: UITableViewDelegate {
    
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
extension DetailsTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! CommentTableViewCell
        cell.navigationController = navigationController
        cell.bindViewModel(comments[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
}