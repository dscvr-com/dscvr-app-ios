//
//  PlaceholderTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 12/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class PlaceholderTableViewCell: UITableViewCell {
    
    // subviews
    let iconView = UILabel()
    let textView = UILabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        iconView.font = UIFont.iconOfSize(90)
        iconView.textColor = .DarkGrey
        contentView.addSubview(iconView)
        
        textView.font = UIFont (name: "Avenir-Book", size: 17)
        textView.textColor = .LightGrey
        contentView.addSubview(textView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        iconView.autoAlignAxis(.Horizontal, toSameAxisOfView: contentView, withOffset: -50)
        iconView.autoAlignAxisToSuperviewAxis(.Vertical)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: iconView, withOffset: 40)
        textView.autoAlignAxisToSuperviewAxis(.Vertical)

        super.updateConstraints()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}