//
//  ActionButton.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class ActionButton: UIButton {
    
    var defaultBackgroundColor: UIColor? {
        didSet {
            updateBackground()
        }
    }
    var activeBackgroundColor: UIColor?
    
    var disabledBackgroundColor: UIColor?
    
    private var touched = false
    
    override var userInteractionEnabled: Bool {
        didSet {
            updateBackground()
        }
    }
    
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
        
        updateBackground()
        
        addTarget(self, action: "buttonTouched", forControlEvents: .TouchDown)
        addTarget(self, action: "buttonUntouched", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
    }
    
    private func updateBackground() {
        if touched {
            backgroundColor = activeBackgroundColor ?? UIColor.whiteColor().alpha(0.5)
        } else if userInteractionEnabled {
            backgroundColor = defaultBackgroundColor ?? UIColor.whiteColor()
        } else {
            backgroundColor = disabledBackgroundColor ?? UIColor.whiteColor()
        }
    }
    
    func buttonTouched() {
        touched = true
        updateBackground()
    }
    
    func buttonUntouched() {
        touched = false
        updateBackground()
    }
    
}