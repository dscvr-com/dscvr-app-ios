//
//  CommentTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import HexColor

class CommentTableViewCell: UITableViewCell {
    
    var navigationController: UINavigationController?
    var viewModel: CommentViewModel!
    
    // subviews
    let textView = KILabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = UIColor.greenColor().alpha(0.5)
        
        textView.numberOfLines = 0
        textView.tintColor = BaseColor
        textView.userInteractionEnabled = true
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = UIColor(0x4d4d4d)
        contentView.addSubview(textView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        textView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 16)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        super.updateConstraints()
    }
    
    func bindViewModel(comment: Comment) {
        viewModel = CommentViewModel(comment: comment)
        
        textView.rac_text <~ viewModel.text
    }
    
    func pushProfile() {
//        let profileViewController = ProfileViewController(personId: viewModel.personId.value)
//        navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}