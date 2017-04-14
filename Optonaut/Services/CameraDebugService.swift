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
        let appId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? NSString
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/\(appId!)/static/debug"
        try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        return path
        }()
    let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high)
    
    init() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            try! fileManager.removeItem(atPath: path)
        }
        try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }
    
    func push(_ pixelBuffer: CVPixelBuffer, intrinsics: [Double], extrinsics: [Double], frameCount: Int) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let cgImage = context!.makeImage()!
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    
        //let smallWidth = width / 2
        //let smallHeight = height / 2
        //let smallContext = CGBitmapContextCreate(nil, smallWidth, smallHeight, 8, bytesPerRow, colorSpace, bitmapInfo)
        
        //CGContextSetInterpolationQuality(smallContext, .None)
        //CGContextDrawImage(smallContext, CGRect(x: 0, y: 0, width: smallWidth, height: smallHeight), cgImage)
        
        //let smallCGImage = CGBitmapContextCreateImage(smallContext)!
        
        (queue).async {
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
    
    fileprivate func saveFilesToDisk(_ cgImage: CGImage, intrinsics: [Double], extrinsics: [Double], frameCount: Int) {
        // json data file
        let data: [String: Any] = [
            "id": frameCount,
            "intrinsics": intrinsics,
            "extrinsics": extrinsics,
        ]
        let json = try! JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        let dataFileName = "\(frameCount).json"
        let dataFile = path.stringByAppendingPathComponent(dataFileName)
        try? json.write(to: URL(fileURLWithPath: dataFile), options: [])
        
        // image file
        let imageFile = path.stringByAppendingPathComponent("\(frameCount).jpg")
        let url = URL(fileURLWithPath: imageFile) as CFURL
        let dest = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, nil)!
        let imageProperties = [kCGImageDestinationLossyCompressionQuality as String: 0.8] as CFDictionary
        CGImageDestinationAddImage(dest, cgImage, imageProperties)
        CGImageDestinationFinalize(dest)
    }
}
