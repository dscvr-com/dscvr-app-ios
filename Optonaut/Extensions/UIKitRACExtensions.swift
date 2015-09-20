//
//  UIKitRACExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import WebImage

struct AssociationKey {
    static var hidden: UInt8 = 1
    static var alpha: UInt8 = 2
    static var text: UInt8 = 3
    static var enabled: UInt8 = 4
    static var textColor: UInt8 = 5
    static var userInteractionEnabled: UInt8 = 6
    static var image: UInt8 = 7
    static var title: UInt8 = 8
    static var placeholder: UInt8 = 9
    static var animating: UInt8 = 10
    static var backgroundColor: UInt8 = 11
    static var buttonTitle: UInt8 = 12
    static var buttonTitleColor: UInt8 = 13
    static var imageUrl: UInt8 = 14
}

enum objc_AssociationPolicy : UInt {
    case OBJC_ASSOCIATION_ASSIGN
    case OBJC_ASSOCIATION_RETAIN_NONATOMIC
    case OBJC_ASSOCIATION_COPY_NONATOMIC
    case OBJC_ASSOCIATION_RETAIN
    case OBJC_ASSOCIATION_COPY
}

// lazily creates a gettable associated property via the given factory
func lazyAssociatedProperty<T: AnyObject>(host: AnyObject, key: UnsafePointer<Void>, factory: ()->T) -> T {
    return objc_getAssociatedObject(host, key) as? T ?? {
        let associatedProperty = factory()
        objc_setAssociatedObject(host, key, associatedProperty, .OBJC_ASSOCIATION_RETAIN)
        return associatedProperty
        }()
}

func lazyMutableProperty<T>(host: AnyObject, key: UnsafePointer<Void>, setter: T -> (), getter: () -> T) -> MutableProperty<T> {
    return lazyAssociatedProperty(host, key: key) {
        let property = MutableProperty<T>(getter())
        property.producer.startWithNext { setter($0) }
        return property
    }
}

extension PlaceholderImageView {

    var rac_url: MutableProperty<String> {
        return lazyAssociatedProperty(self, key: &AssociationKey.imageUrl) {
            let property = MutableProperty<String>("")
            property.producer.startWithNext { urlStr in
                if let url = NSURL(string: urlStr) {
                    self.sd_setImageWithURL(url, placeholderImage: self.placeholderImage)
                }
            }
            return property
        }
    }
}

extension UIButton {
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, key: &AssociationKey.enabled, setter: { self.enabled = $0 }, getter: { self.enabled })
    }
    
    public var rac_backgroundColor: MutableProperty<UIColor?> {
        return lazyMutableProperty(self, key: &AssociationKey.backgroundColor, setter: { self.backgroundColor = $0 }, getter: { self.backgroundColor })
    }
    
    public var rac_titleColor: MutableProperty<UIColor?> {
        return lazyAssociatedProperty(self, key: &AssociationKey.buttonTitleColor) {
            let property = MutableProperty<UIColor?>(nil)
            property.producer.startWithNext { self.setTitleColor($0, forState: .Normal) }
            return property
        }
    }
    
    public var rac_title: MutableProperty<String> {
        return lazyAssociatedProperty(self, key: &AssociationKey.buttonTitle) {
            let property = MutableProperty<String>("")
            property.producer.startWithNext { self.setTitle($0, forState: .Normal) }
            return property
        }
    }
}

extension UIView {
    public var rac_alpha: MutableProperty<CGFloat> {
        return lazyMutableProperty(self, key: &AssociationKey.alpha, setter: { self.alpha = $0 }, getter: { self.alpha })
    }
    
    public var rac_hidden: MutableProperty<Bool> {
        return lazyMutableProperty(self, key: &AssociationKey.hidden, setter: { self.hidden = $0 }, getter: { self.hidden })
    }
    
    public var rac_userInteractionEnabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, key: &AssociationKey.userInteractionEnabled, setter: { self.userInteractionEnabled = $0 }, getter: { self.userInteractionEnabled })
    }
}

extension UINavigationItem {
    public var rac_title: MutableProperty<String> {
        return lazyMutableProperty(self, key: &AssociationKey.title, setter: { self.title = $0 }, getter: { self.title ?? "" })
    }
}

extension UILabel {
    public var rac_text: MutableProperty<String> {
        return lazyMutableProperty(self, key: &AssociationKey.text, setter: { self.text = $0 }, getter: { self.text ?? "" })
    }
    
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, key: &AssociationKey.enabled, setter: { self.enabled = $0 }, getter: { self.enabled })
    }
    
    public var rac_textColor: MutableProperty<UIColor> {
        return lazyMutableProperty(self, key: &AssociationKey.textColor, setter: { self.textColor = $0 }, getter: { self.textColor })
    }
}

extension UITextField {
    public var rac_text: MutableProperty<String> {
        return lazyAssociatedProperty(self, key: &AssociationKey.text) {
            self.addTarget(self, action: "changed", forControlEvents: UIControlEvents.EditingChanged)
            
            let property = MutableProperty<String>(self.text ?? "")
            property.producer.startWithNext { self.text = $0 }
            return property
        }
    }
    
    func changed() {
        rac_text.value = self.text ?? ""
    }
    
    public var rac_textColor: MutableProperty<UIColor?> {
        return lazyMutableProperty(self, key: &AssociationKey.textColor, setter: { self.textColor = $0 }, getter: { self.textColor })
    }
    
    public var rac_placeholder: MutableProperty<String?> {
        return lazyMutableProperty(self, key: &AssociationKey.placeholder, setter: { self.placeholder = $0 }, getter: { self.placeholder })
    }
}

extension UITextView {
    public var rac_text: MutableProperty<String> {
        return lazyMutableProperty(self, key: &AssociationKey.text, setter: { self.text = $0 }, getter: { self.text })
    }
}

extension UIActivityIndicatorView {
    public var rac_animating: MutableProperty<Bool> {
        return lazyAssociatedProperty(self, key: &AssociationKey.animating) {
            let property = MutableProperty<Bool>(false)
            property.producer.startWithNext { $0 ? self.startAnimating() : self.stopAnimating() }
            return property
        }
    }
}