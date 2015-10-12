//
//  ProgressView.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class ProgressView: UIView {
    
    var progress: Float = 0 {
        didSet {
            hidden = progress == 1
            redLayer.frame = CGRect(x: 0, y: 0, width: frame.width * CGFloat(progress), height: frame.height)
        }
    }
    
    private let redLayer = CALayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .DarkGrey
        
        redLayer.backgroundColor = UIColor.Accent.CGColor
        layer.addSublayer(redLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}