//
//  CameraDebugHelper.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import CoreMedia
import ImageIO
import MobileCoreServices

class CameraDebugHelper {
    
    var timestamp: NSTimeInterval
    var count: Int
    var path: String
    var queue: dispatch_queue_t!
    
    init() {
        timestamp = NSDate().timeIntervalSince1970
        count = 0
        
        let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, .AllDomainsMask, true)[0]
        path = dir.stringByAppendingPathComponent("\(timestamp)/")
        
        queue = dispatch_queue_create("cameraDebugHelperQueue", DISPATCH_QUEUE_CONCURRENT)
        
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
    
    func push(pixelBuffer: CVPixelBufferRef, intrinsics: [Double], extrinsics: [Double]) {
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
        
        let bitmapContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, CGColorSpaceCreateDeviceRGB(), CGImageAlphaInfo.NoneSkipLast.rawValue)
        let cgImage = CGBitmapContextCreateImage(bitmapContext)!
        
        dispatch_async(queue, {
            self.saveFilesToDisk(cgImage, intrinsics: intrinsics, extrinsics: extrinsics)
            self.count++
        })
    }
    
    private func saveFilesToDisk(cgImage: CGImage, intrinsics: [Double], extrinsics: [Double]) {
        // json data file
        let data = [
            "intrinsics": intrinsics,
            "extrinsics": extrinsics,
        ]
        let json = try! NSJSONSerialization.dataWithJSONObject(data, options: .PrettyPrinted)
        let dataFileName = "\(count).json"
        let dataFile = path.stringByAppendingPathComponent(dataFileName)
        json.writeToFile(dataFile, atomically: false)
        
        self.uploadToS3(dataFileName)
        
        // image file
        let imageFileName = "\(self.count).jpg"
        let imageFile = self.path.stringByAppendingPathComponent(imageFileName)
        
        let url = NSURL(fileURLWithPath: imageFile) as CFURL
        let dest = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, nil)!
        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
        
        self.uploadToS3(imageFileName)
    }
    
    private func uploadToS3(fileName: String) {
        let request = AWSS3TransferManagerUploadRequest()
        request.bucket = "optonaut-ios-beta"
        request.key = "\(timestamp)/\(fileName)"
        request.body = NSURL(fileURLWithPath: path.stringByAppendingPathComponent(fileName))

        let s3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
        s3TransferManager.upload(request).continueWithBlock { task in
            if task.faulted {
                print(task.error)
            }
            return nil
        }
    }
    
}