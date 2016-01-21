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

func calcTextWidth(text: String, withFont font: UIFont) -> CGFloat {
    let size = (text as NSString).sizeWithAttributes([NSFontAttributeName: font])
    return size.width
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

func extractRotationVector(matrix: GLKMatrix4) -> GLKVector3 {
    let x = atan2(matrix.m21, matrix.m22);
    let y = atan2(-matrix.m20, sqrt(matrix.m21 * matrix.m21 + matrix.m22 * matrix.m22));
    let z = atan2(matrix.m10, matrix.m00);
    
    return GLKVector3Make(x, y, z);
}

func carthesianToSpherical(vec: GLKVector3) -> GLKVector2 {
    let len = GLKVector3Length(vec)
    let theta = acos(vec.z / len);
    let phi = atan2(vec.y, vec.x);
    
    return GLKVector2Make(phi, theta)
}

func getBearing(a: GLKVector2, b: GLKVector2) -> Float {
    let y = sin(a.s - b.s) * cos(b.t);
    let x = cos(a.t) * sin(b.t) -
            sin(a.t) * cos(b.t) * cos(b.s - a.s);
    return atan2(y, x);
}

func getTextureWidth(sceneWidth: CGFloat, hfov: Float) -> CGFloat {
    return CGFloat((sceneWidth * 360) / (CGFloat(hfov) * CGFloat(M_PI)))
}

func toDictionary<E, K, V>(array: [E], transformer: (element: E) -> (key: K, value: V)?) -> Dictionary<K, V> {
    return array.reduce([:]) { (var dict, e) in
        if let (key, value) = transformer(element: e) {
            dict[key] = value
        }
        return dict
    }
}

func safeOptional<T>(val: T!) -> T? {
    if let val = val {
        return val
    } else {
        return nil
    }
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


