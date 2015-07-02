//
//  UIKitExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

struct AssociationKey {
    static var hidden: UInt8 = 1
    static var alpha: UInt8 = 2
    static var text: UInt8 = 3
    static var enabled: UInt8 = 4
    static var textColor: UInt8 = 5
    static var userInteractionEnabled: UInt8 = 6
    static var image: UInt8 = 7
    static var title: UInt8 = 8
}

// lazily creates a gettable associated property via the given factory
func lazyAssociatedProperty<T: AnyObject>(host: AnyObject, key: UnsafePointer<Void>, factory: ()->T) -> T {
    return objc_getAssociatedObject(host, key) as? T ?? {
        let associatedProperty = factory()
        objc_setAssociatedObject(host, key, associatedProperty, UInt(OBJC_ASSOCIATION_RETAIN))
        return associatedProperty
        }()
}

func lazyMutableProperty<T>(host: AnyObject, key: UnsafePointer<Void>, setter: T -> (), getter: () -> T) -> MutableProperty<T> {
    return lazyAssociatedProperty(host, key) {
        var property = MutableProperty<T>(getter())
        property.producer
            .start(next: {
                newValue in
                setter(newValue)
            })
        return property
    }
}

extension UIImageView {
    public var rac_image: MutableProperty<UIImage?> {
        return lazyMutableProperty(self, &AssociationKey.image, { self.image = $0 }, { self.image })
    }
}

extension UIButton {
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.enabled, { self.enabled = $0 }, { self.enabled })
    }
    
    public var rac_userInteractionEnabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.userInteractionEnabled, { self.userInteractionEnabled = $0 }, { self.userInteractionEnabled })
    }
}

extension UIView {
    public var rac_alpha: MutableProperty<CGFloat> {
        return lazyMutableProperty(self, &AssociationKey.alpha, { self.alpha = $0 }, { self.alpha })
    }
    
    public var rac_hidden: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.hidden, { self.hidden = $0 }, { self.hidden })
    }
}

extension UINavigationItem {
    public var rac_title: MutableProperty<String> {
        return lazyMutableProperty(self, &AssociationKey.title, { self.title = $0 }, { self.title ?? "" })
    }
}

extension UILabel {
    public var rac_text: MutableProperty<String> {
        return lazyMutableProperty(self, &AssociationKey.text, { self.text = $0 }, { self.text ?? "" })
    }
    
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.enabled, { self.enabled = $0 }, { self.enabled })
    }
    
    public var rac_userInteractionEnabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.userInteractionEnabled, { self.userInteractionEnabled = $0 }, { self.userInteractionEnabled })
    }
    
    public var rac_textColor: MutableProperty<UIColor> {
        return lazyMutableProperty(self, &AssociationKey.textColor, { self.textColor = $0 }, { self.textColor })
    }
}

extension UITextField {
    public var rac_text: MutableProperty<String> {
        return lazyAssociatedProperty(self, &AssociationKey.text) {
            
            self.addTarget(self, action: "changed", forControlEvents: UIControlEvents.EditingChanged)
            
            var property = MutableProperty<String>(self.text ?? "")
            property.producer
                .start(next: {
                    newValue in
                    self.text = newValue
                })
            return property
        }
    }
    
    public var rac_textColor: MutableProperty<UIColor> {
        return lazyMutableProperty(self, &AssociationKey.textColor, { self.textColor = $0 }, { self.textColor })
    }
    
    func changed() {
        rac_text.value = self.text
    }
}

extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat, flip: Bool) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(M_PI))
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        CGContextScaleCTM(bitmap, yFlip, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}