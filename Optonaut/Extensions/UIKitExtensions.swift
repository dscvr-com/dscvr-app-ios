//
//  UIKitExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

extension UIImage {
    
    func fixedOrientation() -> UIImage {
        
        if imageOrientation == UIImageOrientation.Up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransformIdentity
        
        switch imageOrientation {
        case UIImageOrientation.Down, UIImageOrientation.DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
            break
        case UIImageOrientation.Left, UIImageOrientation.LeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
            break
        case UIImageOrientation.Right, UIImageOrientation.RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
            break
        case UIImageOrientation.Up, UIImageOrientation.UpMirrored:
            break
        }
        
        switch imageOrientation {
        case UIImageOrientation.UpMirrored, UIImageOrientation.DownMirrored:
            CGAffineTransformTranslate(transform, size.width, 0)
            CGAffineTransformScale(transform, -1, 1)
            break
        case UIImageOrientation.LeftMirrored, UIImageOrientation.RightMirrored:
            CGAffineTransformTranslate(transform, size.height, 0)
            CGAffineTransformScale(transform, -1, 1)
        case UIImageOrientation.Up, UIImageOrientation.Down, UIImageOrientation.Left, UIImageOrientation.Right:
            break
        }
        
        let ctx: CGContextRef = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), CGImageGetBitsPerComponent(CGImage), 0, CGImageGetColorSpace(CGImage), CGImageAlphaInfo.PremultipliedLast.rawValue)!
        
        CGContextConcatCTM(ctx, transform)
        
        switch imageOrientation {
        case UIImageOrientation.Left, UIImageOrientation.LeftMirrored, UIImageOrientation.Right, UIImageOrientation.RightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, size.height, size.width), CGImage)
            break
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, size.width, size.height), CGImage)
            break
        }
        
        let cgImage: CGImageRef = CGBitmapContextCreateImage(ctx)!
        
        return UIImage(CGImage: cgImage)
    }
    
}

extension UIEdgeInsets {
    var inverse: UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
    func apply(rect: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(rect, self)
    }
}

extension UITableViewCell {
    var tableView: UITableView? {
        get {
            for var view = self.superview; view != nil; view = view!.superview {
                if view! is UITableView {
                    return view as? UITableView
                }
            }
            return nil
        }
    }
}

class PlaceholderImageView: UIImageView {
    var placeholderImage: UIImage? {
        didSet {
            if image == nil && placeholderImage != nil {
                image = placeholderImage
            }
        }
    }
    
    func setImageWithURLString(urlStr: String) {
        if let url = NSURL(string: urlStr) {
            if self.placeholderImage != nil {
                self.sd_setImageWithURL(url, placeholderImage: self.placeholderImage)
            } else {
                self.sd_setImageWithURL(url)
            }
        }
    }
}