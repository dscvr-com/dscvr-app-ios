//
//  StitcherUtils.swift
//  Optonaut
//

import Foundation
import GLKit
import CoreMotion

let StitcherVersion: String = Recorder.getVersion()

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
    let bitmapContext = CGBitmapContextCreateWithData(
        buf.data, Int(buf.width), Int(buf.height), 8, Int(buf.width) * 4,
        CGColorSpaceCreateDeviceRGB(),
        CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue,
        nil, nil)
    return CGBitmapContextCreateImage(bitmapContext)!
}

func ImageBufferToCompressedUIImage(input: ImageBuffer) -> UIImage {
    let cgImage = ImageBufferToCGImage(input)
    return UIImage(CGImage: cgImage)
}


/*func getDocumentsDirectory() -> NSString {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    let documentsDirectory = paths[0]
    return documentsDirectory
}*/



func ImageBufferToCompressedJPG(input: ImageBuffer, ratio: CGFloat) -> NSData? {
    
    /*if let data = UIImageJPEGRepresentation(ImageBufferToCompressedUIImage(input), ratio){
        let filename = getDocumentsDirectory().stringByAppendingPathComponent("TEST.jpg")
        data.writeToFile(filename, atomically: true)
    }*/
    
    return UIImageJPEGRepresentation(ImageBufferToCompressedUIImage(input), ratio)
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