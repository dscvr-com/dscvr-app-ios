//
//  HatchedButton.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class HatchedButton: UIButton {
    
    var defaultBackgroundColor: UIColor? {
        didSet {
            backgroundColor = defaultBackgroundColor ?? UIColor.whiteColor()
        }
    }
    var activeBackgroundColor: UIColor?
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        postInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func postInit() {
        
        layer.cornerRadius = 17.5
        clipsToBounds = true
        titleLabel?.font = UIFont.displayOfSize(24, withType: .Semibold)
        setTitleColor(.Accent, forState: .Normal)
        
        backgroundColor = defaultBackgroundColor ?? UIColor.whiteColor()
        
        addTarget(self, action: "buttonTouched", forControlEvents: .TouchDown)
        addTarget(self, action: "buttonUntouched", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
    }
    
    func buttonTouched() {
        backgroundColor = activeBackgroundColor ?? UIColor.whiteColor().alpha(0.5)
    }
    
    func buttonUntouched() {
        backgroundColor = defaultBackgroundColor ?? UIColor.whiteColor()
    }
    
}