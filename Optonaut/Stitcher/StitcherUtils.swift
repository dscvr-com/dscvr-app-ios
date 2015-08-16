//
//  StitcherUtils.swift
//  Optonaut
//

import Foundation
import GLKit
import CoreMotion

func CMRotationToGLKMatrix4(r: CMRotationMatrix) -> GLKMatrix4{
    return GLKMatrix4Make(Float(r.m11), Float(r.m12), Float(r.m13), 0,
        Float(r.m21), Float(r.m22), Float(r.m23), 0,
        Float(r.m31), Float(r.m32), Float(r.m33), 0,
        0,     0,     0,     1)
}

func CMRotationToDoubleArray(r: CMRotationMatrix) -> [Double] {
    return [r.m11, r.m12, r.m13, 0,
        r.m21, r.m22, r.m23, 0,
        r.m31, r.m32, r.m33, 0,
        0,     0,     0,     1]
}

func ImageBufferToCGImage(buf: ImageBuffer) -> CGImage {
    let bitmapContext = CGBitmapContextCreate(buf.data, Int(buf.width), Int(buf.height), 8, Int(buf.width) * 4, CGColorSpaceCreateDeviceRGB(), CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue)
    return CGBitmapContextCreateImage(bitmapContext)!
}