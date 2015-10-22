//
//  SearchHashtagTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class SearchHeadTableViewCell: UITableViewCell {
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        textLabel?.font = UIFont.displayOfSize(16, withType: .Thin)
        textLabel?.textColor = .DarkGrey
        textLabel?.textAlignment = .Center
        textLabel?.text = "Trending hashtags"
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
}

class SearchHashtagTableViewCell: UITableViewCell {
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        textLabel?.font = UIFont.displayOfSize(14, withType: .Semibold)
        textLabel?.textColor = .Accent
        textLabel?.textAlignment = .Center
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
}