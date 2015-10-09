//
//  StitcherUtils.swift
//  Optonaut
//

import Foundation
import GLKit
import CoreMotion

let StitcherVersion: String = Recorder.GetVersion()

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

func RotateCGImage(image: CGImage, orientation: UIImageOrientation) -> CGImage {
    
    let imageSize = CGSize(width: CGImageGetWidth(image), height: CGImageGetHeight(image))
    var rotatedSize = imageSize
    
    if orientation == UIImageOrientation.Right || orientation == UIImageOrientation.Left {
        rotatedSize = CGSize(width: imageSize.height, height: imageSize.width)
    }
    
    let rotCenterX = rotatedSize.width / 2
    let rotCenterY = rotatedSize.height / 2
    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 1)
    let context = UIGraphicsGetCurrentContext()
    
    CGContextTranslateCTM(context, rotCenterX, rotCenterY)
    switch orientation {
    case .Right:
        CGContextRotateCTM(context, CGFloat(-M_PI_2))
        CGContextTranslateCTM(context, -rotCenterY, -rotCenterX)
    case .Left:
        CGContextRotateCTM(context, CGFloat(M_PI_2))
        CGContextTranslateCTM(context, -rotCenterY, -rotCenterX)
    case .Down, .Up:
        CGContextRotateCTM(context, CGFloat(M_PI))
        CGContextTranslateCTM(context, -rotCenterX, -rotCenterY)
    default: ()
    }
    
    CGContextDrawImage(context, CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height), image)
    
    let res = CGBitmapContextCreateImage(context)!
    UIGraphicsEndImageContext()
    return res
}