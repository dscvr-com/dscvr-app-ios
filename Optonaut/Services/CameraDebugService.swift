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
import ReactiveCocoa


class CameraDebugService {
    

    let path: String = {
        let appId = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? NSString
        let path = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first! + "/\(appId!)/static/debug"
        try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        return path
        }()
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    
    init() {
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(path) {
            try! fileManager.removeItemAtPath(path)
        }
        try! fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
    }
    
    func push(pixelBuffer: CVPixelBufferRef, intrinsics: [Double], extrinsics: [Double], frameCount: Int) {
        CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.NoneSkipFirst.rawValue
        let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
        let cgImage = CGBitmapContextCreateImage(context)!
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
    
        //let smallWidth = width / 2
        //let smallHeight = height / 2
        //let smallContext = CGBitmapContextCreate(nil, smallWidth, smallHeight, 8, bytesPerRow, colorSpace, bitmapInfo)
        
        //CGContextSetInterpolationQuality(smallContext, .None)
        //CGContextDrawImage(smallContext, CGRect(x: 0, y: 0, width: smallWidth, height: smallHeight), cgImage)
        
        //let smallCGImage = CGBitmapContextCreateImage(smallContext)!
        
        dispatch_async(queue) {
            self.saveFilesToDisk(cgImage, intrinsics: intrinsics, extrinsics: extrinsics, frameCount: frameCount)
        }
    }
    
    //func upload() -> SignalProducer<Float, NSError> {
    //    if !Reachability.connectedToNetwork() {
    //        return SignalProducer<Float, NSError>(value: 0)
    //    }
    //
    //    var uploadData: [String: String] = [:]
    //    let enumerator = NSFileManager.defaultManager().enumeratorAtPath(path)
    //    while let element = enumerator?.nextObject() as? String {
    //        uploadData["\(path)/\(element)"] = element
    //    }
    //
    //    return ApiService<EmptyResponse>.upload("optographs/tmp-\(NSDate().timeIntervalSince1970)/upload-debug", uploadData: uploadData)
    //}
    
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