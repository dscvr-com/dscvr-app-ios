//
//  ActivityTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa

class ActivityTableViewCell: UITableViewCell {
    
    weak var navigationController: NavigationController?
    var activity: Activity!
    
    // subviews
    private let isReadView = UIView()
    private let lineView = UIView()
    private let textView = UILabel()
    let causingImageView = PlaceholderImageView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        isReadView.backgroundColor = .Accent
        isReadView.hidden = true
        isReadView.layer.cornerRadius = 3
        contentView.addSubview(isReadView)
        
        textView.numberOfLines = 0
        textView.font = UIFont.displayOfSize(14, withType: .Regular)
        textView.textColor = .DarkGrey
        contentView.addSubview(textView)
        
        causingImageView.layer.cornerRadius = 20
        causingImageView.clipsToBounds = true
        contentView.addSubview(causingImageView)
        
        lineView.backgroundColor = UIColor.WhiteGrey
        contentView.addSubview(lineView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        isReadView.autoAlignAxisToSuperviewAxis(.Horizontal)
        isReadView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 8)
        isReadView.autoSetDimensionsToSize(CGSize(width: 6, height: 6))
        
        causingImageView.autoAlignAxisToSuperviewAxis(.Horizontal)
        causingImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
        causingImageView.autoSetDimensionsToSize(CGSize(width: 40, height: 40))
        
        textView.autoAlignAxisToSuperviewAxis(.Horizontal)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 80)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -72)
        
        lineView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateConstraints()
    }
    
    func update(activity: Activity) {
        textView.text = activity.text
        isReadView.hidden = activity.isRead
        
        self.activity = activity
    }
    
    func read() {
        ApiService<EmptyResponse>.post("activities/\(activity.ID)/read")
            .startWithCompleted { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.activity.isRead = true
                try! strongSelf.activity.insertOrUpdate()
                strongSelf.update(strongSelf.activity)
            }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}