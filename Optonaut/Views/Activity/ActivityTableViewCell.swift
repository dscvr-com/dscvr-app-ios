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
    //private let isReadView = UIView()
    private let lineView = UIView()
    private let textView = UILabel()
    let causingImageView = PlaceholderImageView()
    let nameView = UILabel()
    let followBack = UIButton()
    let alreadyFollow = UIButton()
    let dateView = UILabel()
    let eliteImageView = UIImageView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
//        isReadView.backgroundColor = .Accent
//        isReadView.hidden = true
//        isReadView.layer.cornerRadius = 3
//        contentView.addSubview(isReadView)
        
        nameView.numberOfLines = 0
        nameView.font = UIFont (name: "Avenir-Heavy", size: 17)
        nameView.textColor = UIColor(0xffbc00)
        contentView.addSubview(nameView)
        
        textView.numberOfLines = 0
        //textView.font = UIFont.displayOfSize(15, withType: .Regular)
        textView.textColor = .DarkGrey
        textView.font = UIFont (name: "Avenir-Book", size: 15)
        contentView.addSubview(textView)
        
        dateView.numberOfLines = 0
        dateView.font = UIFont.displayOfSize(12, withType: .Regular)
        dateView.textColor = .DarkGrey
        contentView.addSubview(dateView)
        
        causingImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        causingImageView.layer.cornerRadius = 25
        causingImageView.layer.borderColor = UIColor(hex:0xffbc00).CGColor
        causingImageView.clipsToBounds = true
        causingImageView.layer.borderWidth = 2.0
        contentView.addSubview(causingImageView)
        
        eliteImageView.image = UIImage(named: "elite_beta_icn")!
        contentView.addSubview(eliteImageView)
        
        lineView.backgroundColor = UIColor.WhiteGrey
        contentView.addSubview(lineView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
//        isReadView.autoAlignAxisToSuperviewAxis(.Horizontal)
//        isReadView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 8)
//        isReadView.autoSetDimensionsToSize(CGSize(width: 6, height: 6))
        
        causingImageView.autoAlignAxisToSuperviewAxis(.Horizontal)
        causingImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
        causingImageView.autoSetDimensionsToSize(CGSize(width: 50, height: 50))
        
        eliteImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
        eliteImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: causingImageView, withOffset: -8)
        let size = UIImage(named: "elite_beta_icn")!.size
        eliteImageView.autoSetDimensionsToSize(CGSize(width: size.width, height: size.height))
        
        nameView.autoAlignAxisToSuperviewAxis(.Horizontal)
        nameView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 80)
        nameView.autoSetDimensionsToSize(CGSize(width: 60, height: 20))
        
        textView.autoAlignAxisToSuperviewAxis(.Horizontal)
        textView.autoPinEdge(.Left, toEdge: .Right, ofView: nameView, withOffset: 5)
        textView.autoSetDimensionsToSize(CGSize(width: 150, height: 20))
        
        //dateView.autoAlignAxisToSuperviewAxis(.Vertical)
        dateView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 80)
        dateView.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameView, withOffset: 5)
        dateView.autoSetDimensionsToSize(CGSize(width: 30, height: 20))
        
        lineView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateConstraints()
    }
    
    func update(activity: Activity) {
        textView.text = activity.text
        //isReadView.hidden = activity.isRead
        
//        if !activity.isRead {
//            contentView.backgroundColor = UIColor(hex:0x595959).alpha(0.20)
//        }
//        
        dateView.text = activity.createdAt.shortDescription
        
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