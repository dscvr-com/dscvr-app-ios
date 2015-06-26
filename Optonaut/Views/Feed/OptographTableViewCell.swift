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
import ReactiveCocoa

class OptographTableViewCell: UITableViewCell, TTTAttributedLabelDelegate {
    
    var viewModel: OptographViewModel!
    
    // subviews
    let previewImageView = UIImageView()
    let likeButtonView = UIButton()
    let numberOfLikesView = UILabel()
    let dateView = UILabel()
    let textView = TTTAttributedLabel(forAutoLayout: ())
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showDetails"))
        contentView.addSubview(previewImageView)
        
        likeButtonView.titleLabel?.font = UIFont.fontAwesomeOfSize(20)
        likeButtonView.setTitle(String.fontAwesomeIconWithName(FontAwesome.Heart), forState: .Normal)
        contentView.addSubview(likeButtonView)
        
        numberOfLikesView.font = UIFont.boldSystemFontOfSize(16)
        numberOfLikesView.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        contentView.addSubview(numberOfLikesView)
        
        dateView.font = UIFont.systemFontOfSize(16)
        dateView.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        contentView.addSubview(dateView)
        
        textView.numberOfLines = 0
        contentView.addSubview(textView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView)
        
        likeButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 10)
        likeButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 15)
        
        numberOfLikesView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        numberOfLikesView.autoPinEdge(.Left, toEdge: .Right, ofView: likeButtonView, withOffset: 5)
        
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
    
    func bindViewModel(optograph: Optograph) {
        viewModel = OptographViewModel(optograph: optograph)
        
        previewImageView.rac_image <~ viewModel.imageUrl.producer |> map { name in UIImage(named: name) }
        numberOfLikesView.rac_text <~ viewModel.numberOfLikes.producer |> map { num in "\(num)" }
        dateView.rac_text <~ viewModel.timeSinceCreated
        
        likeButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleLike()
            return RACSignal.empty()
        })
        
        viewModel.liked.producer
            |> map { $0 ? baseColor() : .grayColor() }
            |> start(next: { self.likeButtonView.setTitleColor($0, forState: .Normal)})
        
        let description = "\(optograph.user!.userName) \(optograph.text)"
        textView.setText(description) { (text: NSMutableAttributedString!) -> NSMutableAttributedString! in
            let range = NSMakeRange(0, count(optograph.user!.userName))
            let boldFont = UIFont.boldSystemFontOfSize(17)
            let font = CTFontCreateWithName(boldFont.fontName, boldFont.pointSize, nil)
            
            text.addAttribute(NSFontAttributeName, value: font, range: range)
            text.addAttribute(kCTForegroundColorAttributeName as String, value: baseColor(), range: range)
            
            return text
        }
    }
    
    func showDetails() {
        let tableView = superview?.superview as! UITableView
        let tableViewController = tableView.dataSource as! OptographTableViewController
        let detailsViewController = DetailsViewController(viewModel: viewModel)
        tableViewController.navController?.pushViewController(detailsViewController, animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}