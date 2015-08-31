//
//  CameraDebugService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import CoreMedia
import ImageIO
import MobileCoreServices

class CameraDebugService {
    
    var timestamp: NSTimeInterval
    var path: String
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    
    init() {
        timestamp = NSDate().timeIntervalSince1970
        
        let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, .AllDomainsMask, true)[0]
        path = dir.stringByAppendingPathComponent("\(timestamp)/")
        
        dispatch_async(queue) {
            try! NSFileManager.defaultManager().createDirectoryAtPath(self.path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func cleanup() {
        dispatch_async(queue) {
//            try! NSFileManager.defaultManager().removeItemAtPath(self.path)
            return
        }
    }
    
    func push(pixelBuffer: CVPixelBufferRef, intrinsics: [Double], extrinsics: [Double], frameCount: Int) {
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue
        let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
        let cgImage = CGBitmapContextCreateImage(context)!
    
        let ratio = Float(width) / Float(height)
        let smallWidth = 640
        let smallHeight = Int(Float(smallWidth) / ratio)
        let smallContext = CGBitmapContextCreate(nil, smallWidth, smallHeight, 8, bytesPerRow, colorSpace, bitmapInfo)
        
        CGContextSetInterpolationQuality(smallContext, .None)
        CGContextDrawImage(smallContext, CGRect(x: 0, y: 0, width: smallWidth, height: smallHeight), cgImage)
        
        let smallCGImage = CGBitmapContextCreateImage(smallContext)!
        
        dispatch_async(queue, {
            self.saveFilesToDisk(smallCGImage, intrinsics: intrinsics, extrinsics: extrinsics, frameCount: frameCount)
        })
    }
    
    private func saveFilesToDisk(cgImage: CGImage, intrinsics: [Double], extrinsics: [Double], frameCount: Int) {
        // json data file
        let data = [
            "id": frameCount,
            "intrinsics": intrinsics,
            "extrinsics": extrinsics,
        ]
        let json = try! NSJSONSerialization.dataWithJSONObject(data, options: .PrettyPrinted)
        let dataFileName = "\(frameCount).json"
        let dataFile = path.stringByAppendingPathComponent(dataFileName)
        json.writeToFile(dataFile, atomically: false)
        
        // image file
        let imageFile = path.stringByAppendingPathComponent("\(frameCount).jpg")
        let url = NSURL(fileURLWithPath: imageFile) as CFURL
        let dest = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, nil)!
        let imageProperties = [kCGImageDestinationLossyCompressionQuality as String: 0.8]
        CGImageDestinationAddImage(dest, cgImage, imageProperties)
        CGImageDestinationFinalize(dest)
    }
}