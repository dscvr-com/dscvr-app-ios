//
//  HatchedButton.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class HatchedButton: UIButton {
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        postInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func postInit() {
        setTitleColor(UIColor.Accent, forState: .Normal)
        titleLabel?.font = UIFont.robotoOfSize(16, withType: .Bold)
        backgroundColor = UIColor.LightGrey.hatched1
        layer.cornerRadius = 5
        clipsToBounds = true
        
        addTarget(self, action: "buttonTouched", forControlEvents: .TouchDown)
        addTarget(self, action: "buttonUntouched", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
    }
    
    func buttonTouched() {
        backgroundColor = UIColor.Accent
        setTitleColor(UIColor.whiteColor(), forState: .Normal)
    }
    
    func buttonUntouched() {
        backgroundColor = UIColor.LightGrey.hatched1
        setTitleColor(UIColor.Accent, forState: .Normal)
    }
    
}