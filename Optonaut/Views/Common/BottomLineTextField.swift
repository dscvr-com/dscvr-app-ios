//
//  BottomLineTextField.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class BottomLineTextField: UITextField {
    
    fileprivate let lineView = UIView()
    
    var offset: CGFloat = 7
    var lineColor = UIColor(0xe5e5e5)
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        postInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func postInit() {
        delegate = self
        
        borderStyle = .none
        backgroundColor = .clear
        clipsToBounds = false
        
        lineView.backgroundColor = lineColor
        addSubview(lineView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = frame.width
        let height = 1
        lineView.frame = CGRect(x: 0, y: frame.height + CGFloat(offset), width: CGFloat(width), height: CGFloat(height))
    }
    
}

// MARK: - UITextFieldDelegate
extension BottomLineTextField: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        lineView.backgroundColor = textColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        lineView.backgroundColor = lineColor
    }
    
}
