//
//  UIKitExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

extension UIImage {
    
    enum Dimension { case width, height }
    
    func resized(_ dimension: Dimension, value: CGFloat) -> UIImage {
        let resizeWidth = dimension == .width
        let oldValue = resizeWidth ? size.width : size.height
        let scale = value / CGFloat(oldValue)
        let otherValue = (resizeWidth ? size.height : size.width) * scale
        let newSize = resizeWidth ? CGSize(width: value, height: otherValue) : CGSize(width: otherValue, height: value)
        let newSizeAsInt = CGSize(width: Int(newSize.width), height: Int(newSize.height))
        
        UIGraphicsBeginImageContextWithOptions(newSizeAsInt, false, 1.0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSizeAsInt))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return newImage;
    }
    
    
    /// Extracts a texture subface from an UIImage.
    /// - parameter x: Horizontal coordinate of the texture subface, between 0 and 1.
    /// - parameter y: Vertical coordinate of the texture subface, between 0 and 1.
    /// - parameter w: Width of the texture subface, between 0 and 1.
    /// - parameter d: Width of the texture subface, in pixels.
    /// - returns: The generated subface, as UIImage.
    func subface(_ x: CGFloat, y: CGFloat, w: CGFloat, d: Int) -> UIImage {
        let targetSize = CGSize(width: d, height: d)
        
        let sourceArea = CGRect(x: size.width * x, y: size.height * y, width: size.width * w, height: size.height * w)
        let imagePart = self.cgImage!.cropping(to: sourceArea)!
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        UIImage(cgImage: imagePart).draw(in: CGRect(origin: CGPoint.zero, size: targetSize))
        let subface = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return subface;
    }
    
    func centeredCropWithSize(_ targetSize: CGSize) -> UIImage {
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
        draw(in: rect)
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
    
    func fixedOrientation() -> UIImage {
        
        if imageOrientation == UIImageOrientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImageOrientation.down, UIImageOrientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(M_PI))
            break
        case UIImageOrientation.left, UIImageOrientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
            break
        case UIImageOrientation.right, UIImageOrientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))
            break
        case UIImageOrientation.up, UIImageOrientation.upMirrored:
            break
        }
        
        switch imageOrientation {
        case UIImageOrientation.upMirrored, UIImageOrientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImageOrientation.leftMirrored, UIImageOrientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImageOrientation.up, UIImageOrientation.down, UIImageOrientation.left, UIImageOrientation.right:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            break
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
    
}

extension UIEdgeInsets {
    var inverse: UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
    func apply(_ rect: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(rect, self)
    }
}

extension UITableViewCell {
    var tableView: UITableView? {
        get {
            var view = self.superview
            while(view != nil) {
                if view! is UITableView {
                    return view as? UITableView
                }
                view = view?.superview
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
    
    func setImageWithURLString(_ urlStr: String) {
        if let url = URL(string: urlStr) {
            self.kf_setImage(with: url)
        }
    }
}

class UIShortPressGestureRecognizer: UILongPressGestureRecognizer {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        
        minimumPressDuration = 0.05
    }
}
