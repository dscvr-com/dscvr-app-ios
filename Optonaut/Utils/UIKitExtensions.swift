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

extension UIButton {
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.enabled, { self.enabled = $0 }, { self.enabled  })
    }
    
    public var rac_userInteractionEnabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.userInteractionEnabled, { self.userInteractionEnabled = $0 }, { self.userInteractionEnabled })
    }
}

extension UIView {
    public var rac_alpha: MutableProperty<CGFloat> {
        return lazyMutableProperty(self, &AssociationKey.alpha, { self.alpha = $0 }, { self.alpha  })
    }
    
    public var rac_hidden: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.hidden, { self.hidden = $0 }, { self.hidden  })
    }
}

extension UILabel {
    public var rac_text: MutableProperty<String> {
        return lazyMutableProperty(self, &AssociationKey.text, { self.text = $0 }, { self.text ?? "" })
    }
    
    public var rac_enabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.enabled, { self.enabled = $0 }, { self.enabled  })
    }
    
    public var rac_userInteractionEnabled: MutableProperty<Bool> {
        return lazyMutableProperty(self, &AssociationKey.userInteractionEnabled, { self.userInteractionEnabled = $0 }, { self.userInteractionEnabled })
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
        return lazyMutableProperty(self, &AssociationKey.textColor, { self.textColor = $0 }, { self.textColor  })
    }
    
    func changed() {
        rac_text.value = self.text
    }
}