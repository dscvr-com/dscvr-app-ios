//
//  ActionButton.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 9/18/15.
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
    
    fileprivate var loadingTitleCache: String?
    fileprivate var loadingUserInteractionEnabledCache: Bool = true
    
    fileprivate var touched = false

    fileprivate let loadingIndicator = UIActivityIndicatorView()
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            if isLoading && isUserInteractionEnabled {
                isUserInteractionEnabled = false
            } else if !isLoading {
                loadingUserInteractionEnabledCache = isUserInteractionEnabled
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
    
    
    fileprivate func postInit() {
        
        layer.cornerRadius = 17.5
        clipsToBounds = true
        titleLabel?.font = UIFont.displayOfSize(24, withType: .Semibold)
        setTitleColor(.Accent, for: UIControlState())
        
        loadingIndicator.hidesWhenStopped = true
        
        addSubview(loadingIndicator)
        
        updateBackground()
        
        addTarget(self, action: "buttonTouched", for: .touchDown)
        addTarget(self, action: "buttonUntouched", for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        loadingIndicator.anchorInCenter(width: loadingIndicator.frame.width, height: loadingIndicator.frame.height)
    }
    
    fileprivate func updateLoadingIndicator() {
        if isLoading {
            loadingTitleCache = title(for: UIControlState())
            setTitle(nil, for: UIControlState())
            loadingUserInteractionEnabledCache = isUserInteractionEnabled
            isUserInteractionEnabled = false
            loadingIndicator.color = titleColor(for: UIControlState())
            loadingIndicator.startAnimating()
        } else {
            setTitle(loadingTitleCache, for: UIControlState())
            isUserInteractionEnabled = loadingUserInteractionEnabledCache
            loadingIndicator.stopAnimating()
        }
    }
    
    fileprivate func updateBackground() {
        if touched {
            backgroundColor = activeBackgroundColor ?? UIColor.white.alpha(0.5)
        } else if isUserInteractionEnabled {
            backgroundColor = defaultBackgroundColor ?? UIColor.white
        } else {
            backgroundColor = disabledBackgroundColor ?? UIColor.white
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
