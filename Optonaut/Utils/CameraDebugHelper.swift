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
    var path: String
    var queue: dispatch_queue_t!
    
    init() {
        timestamp = NSDate().timeIntervalSince1970
        
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
            self.saveFilesToDiskAndUploadToS3(cgImage, intrinsics: intrinsics, extrinsics: extrinsics, frameCount: frameCount)
//        })
    }
    
    private func saveFilesToDiskAndUploadToS3(cgImage: CGImage, intrinsics: [Double], extrinsics: [Double], frameCount: Int) {
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
        
        uploadToS3(dataFileName)
        
        // image file
        let imageFileName = "\(frameCount).jpg"
        let imageFile = path.stringByAppendingPathComponent(imageFileName)
        
        let url = NSURL(fileURLWithPath: imageFile) as CFURL
        let dest = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, nil)!
        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
        
        uploadToS3(imageFileName)
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