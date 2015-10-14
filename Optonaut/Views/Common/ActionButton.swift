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
    
    var isLoading: Bool = false {
        didSet {
            if isLoading != oldValue {
                updateLoadingIndicator()
            }
        }
    }
    
    private var loadingTitleCache: String?
    private var loadingUserInteractionEnabledCache: Bool = true
    
    private var touched = false

    private let loadingIndicator = UIActivityIndicatorView()
    
    override var userInteractionEnabled: Bool {
        didSet {
            if isLoading && userInteractionEnabled {
                userInteractionEnabled = false
            } else if !isLoading {
                loadingUserInteractionEnabledCache = userInteractionEnabled
            }
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
        
        addSubview(loadingIndicator)
        
        updateBackground()
        
        addTarget(self, action: "buttonTouched", forControlEvents: .TouchDown)
        addTarget(self, action: "buttonUntouched", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        loadingIndicator.autoAlignAxisToSuperviewAxis(.Vertical)
        loadingIndicator.autoAlignAxisToSuperviewAxis(.Horizontal)
    }
    
    private func updateLoadingIndicator() {
        if isLoading {
            loadingTitleCache = titleForState(.Normal)
            setTitle(nil, forState: .Normal)
            loadingUserInteractionEnabledCache = userInteractionEnabled
            userInteractionEnabled = false
            loadingIndicator.color = titleColorForState(.Normal)
            loadingIndicator.startAnimating()
        } else {
            setTitle(loadingTitleCache, forState: .Normal)
            userInteractionEnabled = loadingUserInteractionEnabledCache
            loadingIndicator.stopAnimating()
        }
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