//
//  PlaceholderTextView.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class PlaceholderTextView: UITextView {
    
    var placeholderText = "" {
        didSet { text = placeholderText }
    }
    var placeholderAlpha: CGFloat = 0.4 {
        didSet { alpha = placeholderAlpha }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        postInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        postInit()
    }
    
    private func postInit() {
        text = placeholderText
        alpha = placeholderAlpha
//        delegate = self
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
//        if text == placeholderText {
//            text = ""
//            alpha = 1
//        }
//        becomeFirstResponder()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if text == "" {
            text = placeholderText
            alpha = placeholderAlpha
        }
        resignFirstResponder()
    }
}