//
//  Utils.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/20/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa

func uuid() -> UUID {
    return NSUUID().UUIDString.lowercaseString
}

func isValidEmail(email: String) -> Bool {
    let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(email)
}

func isValidPassword(password: String) -> Bool {
    return password.characters.count >= 5
}

func isValidUserName(userName: String) -> Bool {
    let userNameRegEx = "^[a-zA-Z0-9_]+$"
    let userNameTest = NSPredicate(format:"SELF MATCHES %@", userNameRegEx)
    return userNameTest.evaluateWithObject(userName)
}

func identity<T>(el: T) -> T {
    return el
}

func calcTextHeight(text: String, withWidth width: CGFloat, andFont font: UIFont) -> CGFloat {
    let attributes = [NSFontAttributeName: font]
    let textAS = NSAttributedString(string: text, attributes: attributes)
    let tmpSize = CGSize(width: width, height: 100000)
    let textRect = textAS.boundingRectWithSize(tmpSize, options: [.UsesFontLeading, .UsesLineFragmentOrigin], context: nil)
    
    return textRect.height
}

class NotificationSignal<T> {
    
    let (signal, sink) = Signal<T, NoError>.pipe()
    
    func notify(value: T) {
        sink.sendNext(value)
    }
    
    func dispose() {
        sink.sendInterrupted()
    }
    
}


func negate(val: Bool) -> Bool {
    return !val
}

func isEmpty(val: String) -> Bool {
    return val.isEmpty
}

func isNotEmpty(val: String) -> Bool {
    return !val.isEmpty
}

func and(a: Bool, _ b: Bool) -> Bool {
    return a && b
}

func or(a: Bool, _ b: Bool) -> Bool {
    return a || b
}

func toRadians(deg: Float) -> Float {
    return deg / Float(180) * Float(M_PI)
}

func toDegrees(rad: Float) -> Float {
    return rad * Float(180) / Float(M_PI)
}

//class NotificationSignal {
//    
//    let (signal, sink) =  Signal<Void, NoError>.pipe()
//    
//    func notify() {
//        sink.sendNext(())
//    }
//    
//}


