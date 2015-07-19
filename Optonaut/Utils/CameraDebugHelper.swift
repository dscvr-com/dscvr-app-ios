//
//  CameraDebugHelper.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import CoreMedia

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
//        let zipPath = path.stringByAppendingPathComponent("\(timestamp).zip")
//        Main.createZipFileAtPath(zipPath, withContentsOfDirectory: path, keepParentDirectory: true)
        
        dispatch_async(queue) {
//            try! NSFileManager.defaultManager().removeItemAtPath(self.path)
            return
        }
    }
    
    func push(pixelBuffer: CVPixelBufferRef, intrinsics: [Double], extrinsics: [Double]) {
//        var bufferCopy: CMSampleBuffer!
//        var p = UnsafeMutablePointer<CMSampleBuffer>()
        
//        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
//        let width = CVPixelBufferGetWidth(pixelBuffer)
//        let height = CVPixelBufferGetHeight(pixelBuffer)
//        let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
//        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
        
//        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
//        let width = CVPixelBufferGetWidth(pixelBuffer)
//        let height = CVPixelBufferGetHeight(pixelBuffer)
//        let pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer)
//        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        let newBaseAddress = UnsafeMutablePointer<Void>.alloc(height * bytesPerRow)
//        memcpy(newBaseAddress, baseAddress, height * bytesPerRow)
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
//        
//        let newPixelBufferPointer = UnsafeMutablePointer<CVPixelBufferRef?>.alloc(1)
//        let tmp = UnsafeMutablePointer<Void>()
        
//        let keyCallBacks = UnsafeMutablePointer( (Unmanaged.passUnretained(kCFTypeDictionaryKeyCallBacks))
//        var keyCallBacks = kCFTypeDictionaryKeyCallBacks
//        var valueCallBacks = kCFTypeDictionaryValueCallBacks
//        
//        var surfaceKey = kCVPixelBufferIOSurfacePropertiesKey
//        let emptyPointer = UnsafePointer<Void>()
//        var empty = CFDictionaryCreate(kCFAllocatorDefault, nil, nil, 0, &keyCallBacks, &valueCallBacks)
//        let emptyPointer = UnsafeMutablePointer<CFDictionary>.alloc(1)
//        emptyPointer.initializeFrom(empty)
//        let attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &keyCallBacks, &valueCallBacks)
//        CFDictionarySetValue(attrs, &surfaceKey, emptyPointer)
        
//        let empty = [:] as CFDictionary
//        let attributes = [kCVPixelBufferIOSurfacePropertiesKey as String: empty] as CFDictionary
        
//        
//        let y = CVPixelBufferCreateWithBytes(nil, width, height, pixelFormatType, newBaseAddress, bytesPerRow, nil, tmp, attributes, newPixelBufferPointer)
//        print(y)
//
//        let newPixelBuffer = newPixelBufferPointer.move()!
        
//        dispatch_async(queue, {
            self.saveFilesToDisk(pixelBuffer, intrinsics: intrinsics, extrinsics: extrinsics)
            self.count++
//        })
    }
    
    private func saveFilesToDisk(pixelBuffer: CVPixelBufferRef, intrinsics: [Double], extrinsics: [Double]) {
        // json data file
        let data = [
            "intrinsics": intrinsics,
            "extrinsics": extrinsics,
        ]
        let json = try! NSJSONSerialization.dataWithJSONObject(data, options: .PrettyPrinted)
        let dataFileName = "\(count).json"
        let dataFile = path.stringByAppendingPathComponent(dataFileName)
        json.writeToFile(dataFile, atomically: false)
        
        uploadToS3(dataFileName)
        
        // image file
        let ciImage = CIImage(CVPixelBuffer: pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let imageSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(imageSize)
        
        let uiImage = UIImage(CIImage: ciImage)
        let rect = CGRect(origin: CGPointZero, size: imageSize)
        uiImage.drawInRect(rect)
        
        let drawnUiImage = UIGraphicsGetImageFromCurrentImageContext()
        let jpegData = UIImageJPEGRepresentation(drawnUiImage, 1.0)
        
        let imageFileName = "\(count).jpg"
        let imageFile = path.stringByAppendingPathComponent(imageFileName)
        jpegData?.writeToFile(imageFile, atomically: false)
        
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