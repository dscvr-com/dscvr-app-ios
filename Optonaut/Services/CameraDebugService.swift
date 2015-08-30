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
    var queue: dispatch_queue_t!
    
    init() {
        timestamp = NSDate().timeIntervalSince1970
        
        let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, .AllDomainsMask, true)[0]
        path = dir.stringByAppendingPathComponent("\(timestamp)/")
        
        queue = dispatch_queue_create("CameraDebugServiceQueue", DISPATCH_QUEUE_CONCURRENT)
        
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
        
        let bitmapContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, CGColorSpaceCreateDeviceRGB(), CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue)
        let cgImage = CGBitmapContextCreateImage(bitmapContext)!
        
//        dispatch_async(queue, {
            self.saveFilesToDisk(cgImage, intrinsics: intrinsics, extrinsics: extrinsics, frameCount: frameCount)
//        })
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
        let imageFileName = "\(frameCount).jpg"
        saveFileToDisk(cgImage, name: imageFileName)
    }
    
    func saveFileToDisk(cgImage: CGImage, name: String) {
        let imageFile = path.stringByAppendingPathComponent(name)
        
        let url = NSURL(fileURLWithPath: imageFile) as CFURL
        let dest = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, nil)!
        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
    }
}