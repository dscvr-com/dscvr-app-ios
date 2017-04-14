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
        
        backgroundColor = .clear
        
        iconView.font = UIFont.textOfSize(90, withType: .Regular)
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
        iconView.autoAlignAxis(.horizontal, toSameAxisOf: contentView, withOffset: -50)
        iconView.autoAlignAxis(toSuperviewAxis: .vertical)
        
        textView.autoPinEdge(.top, to: .bottom, of: iconView, withOffset: 40)
        textView.autoAlignAxis(toSuperviewAxis: .vertical)

        super.updateConstraints()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {}
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {}
    
}
