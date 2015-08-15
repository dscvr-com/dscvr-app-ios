//
//  NewCommentTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class NewCommentTableViewCell: UITableViewCell {
    
    let viewModel = NewCommentViewModel()
    
    // subviews
    let textInputView = KMPlaceholderTextView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = UIColor.greenColor().alpha(0.5)
        
        textInputView.font = UIFont.robotoOfSize(13, withType: .Light)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.placeholder = "Write a comment"
        contentView.addSubview(textInputView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        textInputView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 16)
        textInputView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        textInputView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        textInputView.autoSetDimension(.Height, toSize: 30)
        
        super.updateConstraints()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}