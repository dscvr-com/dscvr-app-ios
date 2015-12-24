//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class HashtagTableViewController: OptographTableViewController, RedNavbar, UniqueView {
    
    private let viewModel = SearchViewModel()
    
    private let hashtagStr: String
    private let isFollowed = MutableProperty<Bool>(false)
    private var hashtag: Hashtag?
    
    let uniqueIdentifier: String
    
    required init(hashtag: String) {
        uniqueIdentifier = "hashtag-\(hashtag)"
        
        hashtagStr = hashtag
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hashtagView = NavHashtagView()
        hashtagView.hashtag = hashtagStr
        hashtagView.userInteractionEnabled = true
        hashtagView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleFollow"))
        
        isFollowed.producer.startWithNext { [weak hashtagView] val in
            hashtagView?.isFollowed = val
        }
        
        navigationItem.titleView = hashtagView
        
        ApiService<Hashtag>.get("hashtags/name/\(hashtagStr)")
            .startWithNext { [weak self] hashtag in
                self?.hashtag = hashtag
                self?.isFollowed.value = hashtag.isFollowed
            }
        
        viewModel.searchText.value = "#\(hashtagStr)"
        
        viewModel.results.producer
            .on(
                next: { results in
                    self.items = results.models
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
            )
            .start()
        
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
    
    func toggleFollow() {
        guard let hashtag = hashtag else {
            return
        }
        
        if !SessionService.isLoggedIn {
            let alert = UIAlertController(title: "Please login first", message: "In order to follow #\(hashtag.name) you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Sign in", style: .Cancel, handler: { [weak self] _ in
                self?.view.window?.rootViewController = LoginViewController()
            }))
            alert.addAction(UIAlertAction(title: "Later", style: .Default, handler: { _ in return }))
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let followedBefore = isFollowed.value
        
        SignalProducer<Bool, ApiError>(value: followedBefore)
            .flatMap(.Latest) { followedBefore in
                followedBefore
                    ? ApiService<EmptyResponse>.delete("hashtags/\(hashtag.ID)/follow")
                    : ApiService<EmptyResponse>.post("hashtags/\(hashtag.ID)/follow", parameters: nil)
            }
            .on(
                started: {
                    self.isFollowed.value = !followedBefore
                },
                failed: { _ in
                    self.isFollowed.value = followedBefore
                }
            )
            .start()
    }
    
}

private class NavHashtagView: UIView {
    
    var isFollowed = false {
        didSet {
            iconView.text = isFollowed ? String.iconWithName(.Check) : String.iconWithName(.Plus)
            backgroundColor = isFollowed ? .whiteColor() : .Accent
            iconView.textColor = isFollowed ? .Accent : .whiteColor()
            titleView.textColor = isFollowed ? .Accent : .whiteColor()
            layer.borderWidth = isFollowed ? 0 : 1
        }
    }
    var hashtag = "" {
        didSet {
            let str = "#\(hashtag)"
            titleView.text = str
            
            let strBoundingBox = (str as NSString).sizeWithAttributes([NSFontAttributeName: UIFont.displayOfSize(15, withType: .Regular)])
            frame = CGRect(x: 0, y: 0, width: strBoundingBox.width + 52, height: 31)
            updateConstraintsIfNeeded()
        }
    }
    
    private let iconView = UILabel()
    private let titleView = UILabel()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        layer.cornerRadius = 14
        layer.borderColor = UIColor.whiteColor().CGColor
        
        iconView.font = UIFont.iconOfSize(12)
        iconView.textColor = .whiteColor()
        addSubview(iconView)
        
        titleView.font = UIFont.displayOfSize(15, withType: .Regular)
        titleView.textColor = .whiteColor()
        addSubview(titleView)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func updateConstraints() {
        iconView.autoAlignAxisToSuperviewAxis(.Horizontal)
        iconView.autoPinEdge(.Left, toEdge: .Left, ofView: self, withOffset: 17)
        
        titleView.autoAlignAxisToSuperviewAxis(.Horizontal)
        titleView.autoPinEdge(.Right, toEdge: .Right, ofView: self, withOffset: -17)
        
        super.updateConstraints()
    }
    
}