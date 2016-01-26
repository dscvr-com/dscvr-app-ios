//
//  UIKitExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

extension UIImage {
    
    enum Dimension { case Width, Height }
    
    func resized(dimension: Dimension, value: CGFloat) -> UIImage {
        let resizeWidth = dimension == .Width
        let oldValue = resizeWidth ? size.width : size.height
        let scale = value / CGFloat(oldValue)
        let otherValue = (resizeWidth ? size.height : size.width) * scale
        let newSize = resizeWidth ? CGSize(width: value, height: otherValue) : CGSize(width: otherValue, height: value)
        let newSizeAsInt = CGSize(width: Int(newSize.width), height: Int(newSize.height))
        
        UIGraphicsBeginImageContextWithOptions(newSizeAsInt, false, 1.0)
        drawInRect(CGRect(origin: CGPointZero, size: newSizeAsInt))
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
    
    
    /// Extracts a texture subface from an UIImage.
    /// - parameter x: Horizontal coordinate of the texture subface, between 0 and 1.
    /// - parameter y: Vertical coordinate of the texture subface, between 0 and 1.
    /// - parameter w: Width of the texture subface, between 0 and 1.
    /// - parameter d: Width of the texture subface, in pixels.
    /// - returns: The generated subface, as UIImage.
    func subface(x: CGFloat, y: CGFloat, w: CGFloat, d: Int) -> UIImage{
        let targetSize = CGSize(width: d, height: d)
        
        let sourceArea = CGRect(x: size.width * x, y: size.height * y, width: size.width * w, height: size.height * w)
        let imagePart = CGImageCreateWithImageInRect(self.CGImage!, sourceArea)!
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        UIImage(CGImage: imagePart).drawInRect(CGRect(origin: CGPointZero, size: targetSize))
        let subface = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        return subface;
    }
    
    func centeredCropWithSize(targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let newSize: CGSize
        
        if widthRatio < heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let origin = CGPoint(x: (targetSize.width - newSize.width) / 2, y: (targetSize.height - newSize.height) / 2)
        let rect = CGRect(origin: origin, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)
        drawInRect(rect)
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
    
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
                self.kf_setImageWithURL(url, placeholderImage: self.placeholderImage)
            } else {
                self.kf_setImageWithURL(url)
            }
        }
    }
}

class UIShortPressGestureRecognizer: UILongPressGestureRecognizer {
    override init(target: AnyObject?, action: Selector) {
        super.init(target: target, action: action)
        
        minimumPressDuration = 0.05
    }
}