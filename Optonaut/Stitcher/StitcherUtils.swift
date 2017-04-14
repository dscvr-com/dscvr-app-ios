//
//  StitcherUtils.swift
//  Optonaut
//

import Foundation
import GLKit
import CoreMotion

let StitcherVersion: String = Recorder.getVersion()

func CMRotationToGLKMatrix4(_ r: CMRotationMatrix) -> GLKMatrix4{
    return GLKMatrix4Make(Float(r.m11), Float(r.m12), Float(r.m13), 0,
        Float(r.m21), Float(r.m22), Float(r.m23), 0,
        Float(r.m31), Float(r.m32), Float(r.m33), 0,
        0,     0,     0,     1)
}

func CMRotationToDoubleArray(_ r: CMRotationMatrix) -> [Double] {
    return [r.m11, r.m12, r.m13, 0,
        r.m21, r.m22, r.m23, 0,
        r.m31, r.m32, r.m33, 0,
        0,     0,     0,     1]
}

func ImageBufferToCGImage(_ buf: ImageBuffer) -> CGImage {
    let bitmapContext = CGContext(
        data: buf.data, width: Int(buf.width), height: Int(buf.height), bitsPerComponent: 8, bytesPerRow: Int(buf.width) * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue,
        releaseCallback: nil, releaseInfo: nil)
    return bitmapContext!.makeImage()!
}

func ImageBufferToCompressedUIImage(_ input: ImageBuffer) -> UIImage {
    let cgImage = ImageBufferToCGImage(input)
    return UIImage(cgImage: cgImage)
}

func ImageBufferToCompressedJPG(_ input: ImageBuffer, ratio: CGFloat) -> Data? {
    return UIImageJPEGRepresentation(ImageBufferToCompressedUIImage(input), ratio)
}

func RotateCGImage(_ image: CGImage, orientation: UIImageOrientation) -> CGImage {
    
    let imageSize = CGSize(width: image.width, height: image.height)
    var rotatedSize = imageSize
    
    if orientation == UIImageOrientation.right || orientation == UIImageOrientation.left {
        rotatedSize = CGSize(width: imageSize.height, height: imageSize.width)
    }
    
    let rotCenterX = rotatedSize.width / 2
    let rotCenterY = rotatedSize.height / 2
    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 1)
    let context = UIGraphicsGetCurrentContext()!
    
    context.translateBy(x: rotCenterX, y: rotCenterY)
    switch orientation {
    case .right:
        context.rotate(by: CGFloat(-M_PI_2))
        context.translateBy(x: -rotCenterY, y: -rotCenterX)
    case .left:
        context.rotate(by: CGFloat(M_PI_2))
        context.translateBy(x: -rotCenterY, y: -rotCenterX)
    case .down, .up:
        context.rotate(by: CGFloat(M_PI))
        context.translateBy(x: -rotCenterX, y: -rotCenterY)
    default: ()
    }
    
    context.draw(image, in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
    
    let res = context.makeImage()!
    UIGraphicsEndImageContext()
    return res
}
