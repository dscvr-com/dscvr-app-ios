//
//  ImageStore.swift
//  DSCVR
//
//  Created by Emanuel Jöbstl on 13/06/2017.
//  Copyright © 2017 Optonaut. All rights reserved.
//

import Foundation
import CoreMedia
import ImageIO
import MobileCoreServices

class ImageStore {
    
    static let directoryPath: String = {
        let appId = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? NSString
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/\(appId!)/optographs/"
        try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        return path
    }()
    
    static func pathForOptographFace(optographId: UUID, side: String, face: Int) -> String {
        
        let optographsPath = URL(fileURLWithPath: directoryPath)
        let filePath = optographsPath.appendingPathComponent("\(optographId)_\(side)_\(face).jpg")

        return filePath.path
    }
    
    static func saveFace(image: UIImage, optographId: UUID, side: String, face: Int) {
        let path = pathForOptographFace(optographId: optographId, side: side, face: face)
        print("Saving to: \(path)")
        saveFilesToDisk(image, path: path);
    }
    
    
    static func getFace(optographId: UUID, side: String, face: Int) -> UIImage {
        let path = pathForOptographFace(optographId: optographId, side: side, face: face)
        let uiImage = UIImage(contentsOfFile: path)
        return uiImage!
    }

    
    static fileprivate func saveFilesToDisk(_ image: UIImage, path: String) {
        if let data = UIImageJPEGRepresentation(image, 0.9) {
            try! data.write(to: URL(fileURLWithPath: path))
        }
    }
}
