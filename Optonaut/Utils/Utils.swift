//
//  Utils.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/20/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift
import Result

func uuid() -> UUID {
    return NSUUID().uuidString.lowercased()
}

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluate(with: email)
}

func isValidPassword(_ password: String) -> Bool {
    return password.characters.count >= 5
}

func isValidUserName(_ userName: String) -> Bool {
    let userNameRegEx = "^[a-zA-Z0-9_]+$"
    let userNameTest = NSPredicate(format:"SELF MATCHES %@", userNameRegEx)
    return userNameTest.evaluate(with: userName)
}

func identity<T>(_ el: T) -> T {
    return el
}

func calcTextHeight(_ text: String, withWidth width: CGFloat, andFont font: UIFont) -> CGFloat {
    if text.isEmpty {
        return 0
    }
    
    let attributes = [NSFontAttributeName: font]
    let textAS = NSAttributedString(string: text, attributes: attributes)
    let tmpSize = CGSize(width: width, height: 100000)
    let textRect = textAS.boundingRect(with: tmpSize, options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil)
    
    return textRect.height
}

func calcTextWidth(_ text: String, withFont font: UIFont) -> CGFloat {
    if text.isEmpty {
        return 0
    }
    
    let size = (text as NSString).size(attributes: [NSFontAttributeName: font])
    return size.width
}

class NotificationSignal<T> {
    
    let (signal, sink) = Signal<T, NoError>.pipe()
    
    func notify(_ value: T) {
        sink.send(value: value)
    }
    
    func dispose() {
        sink.sendInterrupted()
    }
    
}

func isTrue(_ val: Bool) -> Bool {
    return val
}

func isFalse(_ val: Bool) -> Bool {
    return !val
}

func negate(_ val: Bool) -> Bool {
    return !val
}

func isEmpty(_ val: String) -> Bool {
    return val.isEmpty
}

func isNotEmpty(_ val: String) -> Bool {
    return !val.isEmpty
}

func and(_ a: Bool, _ b: Bool) -> Bool {
    return a && b
}

func or(_ a: Bool, _ b: Bool) -> Bool {
    return a || b
}

func toRadians(_ deg: Float) -> Float {
    return deg / Float(180) * Float(M_PI)
}

func toDegrees(_ rad: Float) -> Float {
    return rad * Float(180) / Float(M_PI)
}

func extractRotationVector(_ matrix: GLKMatrix4) -> GLKVector3 {
    let x = atan2(matrix.m21, matrix.m22);
    let y = atan2(-matrix.m20, sqrt(matrix.m21 * matrix.m21 + matrix.m22 * matrix.m22));
    let z = atan2(matrix.m10, matrix.m00);
    
    return GLKVector3Make(x, y, z);
}

func carthesianToSpherical(_ vec: GLKVector3) -> GLKVector2 {
    let len = GLKVector3Length(vec)
    let theta = acos(vec.z / len);
    let phi = atan2(vec.y, vec.x);
    
    return GLKVector2Make(phi, theta)
}

func getBearing(_ a: GLKVector2, b: GLKVector2) -> Float {
    let y = sin(a.s - b.s) * cos(b.t);
    let x = cos(a.t) * sin(b.t) -
            sin(a.t) * cos(b.t) * cos(b.s - a.s);
    return atan2(y, x);
}

func getTextureWidth(_ sceneWidth: CGFloat, hfov: Float) -> CGFloat {
    return CGFloat((sceneWidth * 360) / (CGFloat(hfov) * CGFloat(M_PI)))
}

func toDictionary<E, K, V>(_ array: [E], transformer: (_ element: E) -> (key: K, value: V)?) -> Dictionary<K, V> {
    return array.reduce([:]) { (d, e) in
        var dict = d
        if let (key, value) = transformer(e) {
            dict[key] = value
        }
        return dict
    }
}

func safeOptional<T>(_ val: T!) -> T? {
    if let val = val {
        return val
    } else {
        return nil
    }
}

func phiThetaToRotationMatrix(_ phi: Float, theta: Float) -> GLKMatrix4 {
    return GLKMatrix4Multiply(GLKMatrix4MakeZRotation(-phi), GLKMatrix4MakeXRotation(-theta))
}

func sync(_ obj: AnyObject, fn: () -> ()) {
    objc_sync_enter(obj)
    fn()
    objc_sync_exit(obj)
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


