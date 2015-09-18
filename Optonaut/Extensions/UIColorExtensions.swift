//
//  UIColorExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/6/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

extension UIColor {
    
    var hatched1: UIColor {
        get {
            let pattern = UIImage(named: "hatching-1pt")!
            let rect = CGRect(origin: CGPointZero, size: pattern.size)
            
            UIGraphicsBeginImageContextWithOptions(rect.size, false, pattern.scale)
            let context = UIGraphicsGetCurrentContext()
            
            setFill()
            CGContextTranslateCTM(context, 0, rect.height)
            CGContextScaleCTM(context, 1.0, -1.0)
            CGContextClipToMask(context, rect, pattern.CGImage)
            CGContextFillRect(context, rect)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return UIColor(patternImage: image)
        }
    }
    
    var hatched2: UIColor {
        get {
            let pattern = UIImage(named: "hatching-2pt")!
            let rect = CGRect(origin: CGPointZero, size: pattern.size)
            
            UIGraphicsBeginImageContextWithOptions(rect.size, false, pattern.scale)
            let context = UIGraphicsGetCurrentContext()
            
            setFill()
            CGContextTranslateCTM(context, 0, rect.height)
            CGContextScaleCTM(context, 1.0, -1.0)
            CGContextClipToMask(context, rect, pattern.CGImage)
            CGContextFillRect(context, rect)
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return UIColor(patternImage: image)
        }
    }
    
}