//
//  OptographTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import TTTAttributedLabel
import RealmSwift
import FontAwesome

class OptographTableViewCell: UITableViewCell, TTTAttributedLabelDelegate {
    
    var data: Optograph!
    
    let previewImageView = UIImageView()
    let likeButtonView = UILabel()
    let numberOfLikesView = UILabel()
    let dateView = UILabel()
    let textView = TTTAttributedLabel(forAutoLayout: ())
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showDetails"))
        
        likeButtonView.font = UIFont.fontAwesomeOfSize(20)
        likeButtonView.text = String.fontAwesomeIconWithName(FontAwesome.Heart)
        likeButtonView.userInteractionEnabled = true
        likeButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleLike"))
        
        numberOfLikesView.font = UIFont.boldSystemFontOfSize(16)
        numberOfLikesView.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        
        dateView.font = UIFont.systemFontOfSize(16)
        dateView.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        
        textView.numberOfLines = 0
        
        contentView.addSubview(previewImageView)
        contentView.addSubview(likeButtonView)
        contentView.addSubview(numberOfLikesView)
        contentView.addSubview(dateView)
        contentView.addSubview(textView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView)
        
        likeButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 15)
        likeButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 15)
        
        numberOfLikesView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        numberOfLikesView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 45)
        
        dateView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        dateView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 46)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 15)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15)
        
        super.updateConstraints()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func applyData() {
        previewImageView.image = UIImage(named: "\(data.id)")
        numberOfLikesView.text = String(data.numberOfLikes)
        dateView.text = durationSince(data.createdAt)
        
        likeButtonView.textColor = data.likedByUser ? baseColor() : .grayColor()
        
        let description = "\(data.user!.userName) \(data.text)"
        
        textView.setText(description) { (text: NSMutableAttributedString!) -> NSMutableAttributedString! in
            let range = NSMakeRange(0, count(self.data.user!.userName))
            let boldFont = UIFont.boldSystemFontOfSize(17)
            let font = CTFontCreateWithName(boldFont.fontName, boldFont.pointSize, nil)
            
            text.addAttribute(NSFontAttributeName, value: font, range: range)
            text.addAttribute(kCTForegroundColorAttributeName as String, value: baseColor(), range: range)
            
            return text
        }
        
        
        textView.userInteractionEnabled = true
        textView.delegate = self
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
    }
    
    func showDetails() {
        let tableView = superview?.superview as! UITableView
        let tableViewController = tableView.dataSource as! OptographTableViewController
        let detailsViewController = DetailsViewController(data: data)
        tableViewController.navController?.pushViewController(detailsViewController, animated: true)
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        
    }
    
    func toggleLike() {
        let likedBefore = data.likedByUser
        Realm().write {
            self.data.likedByUser = !likedBefore
            self.data.numberOfLikes += likedBefore ? -1 : 1
            self.applyData()
        }
        
        if likedBefore {
//            Api().delete("optographs/\(data.id)/like", authorized: true,
//                success: { _ in () },
//                fail: { error in
//                    println(error)
//                    Realm().write {
//                        self.data.likedByUser = likedBefore
//                        self.applyData()
//                    }
//                }
//            )
        } else {
//            Api().post("optographs/\(data.id)/like", authorized: true, parameters: nil,
//                success: { _ in () },
//                fail: { error in
//                    println(error)
//                    Realm().write {
//                        self.data.likedByUser = likedBefore
//                        self.applyData()
//                    }
//                }
//            )
        }
    }
    
}