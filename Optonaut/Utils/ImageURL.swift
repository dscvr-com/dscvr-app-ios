//
//  ImageURL.swift
//  Optonaut
//
//  Created by Johannes Schickling on 03/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
//import CommonCrypto

func ImageURL(_ path: String, width: Int = 0, height: Int = 0) -> String {
    return buildURL(path, width: width, height: height, filter: nil)
}

enum ImageURLDimension { case width, height }

func ImageURL(_ path: String, fullDimension: ImageURLDimension) -> String {
    switch fullDimension {
    case .width: return ImageURL(path, width: Int(UIScreen.main.bounds.width), height: 0)
    case .height: return ImageURL(path, width: 0, height: Int(UIScreen.main.bounds.height))
    }
}

func ImageURL(_ uuid: String, size: Int, face: Int, x: Float, y: Float, d: Float) -> String {
    return buildURL(uuid, width: 0, height: 0, filter: "cube(\(face),\(x),\(y),\(d),\(size))")
}

enum TextureSide { case left, right }

func TextureURL(_ optographID: String, side: TextureSide, size: CGFloat, face: Int, x: Float, y: Float, d: Float) -> String {
    let sideLetter = side == .left ? "l" : "r"
    let scaledSize = min(Int(size * UIScreen.main.scale), 900)
    return buildURL("textures/\(optographID)/\(sideLetter)\(face).jpg", width: 0, height: 0, filter: "subface(\(x),\(y),\(d),\(scaledSize))")
}
func TextureURL2(_ optographID: String, side: TextureSide, size: CGFloat, face: Int, x: Float, y: Float, d: Float) -> String {
    let scaledSize = min(Int(size * UIScreen.main.scale), 900)
    return buildURL("textures/\(optographID)/placeholder.jpg", width: 0, height: 0, filter: "subface(\(x),\(y),\(d),\(scaledSize))")
}

private func buildURL(_ path: String, width: Int, height: Int, filter: String?) -> String {
    let s3Host: String
    
    switch Env {
    case .production,.localStaging, .staging, .development: s3Host = "resources.staging-iam360.io.s3.amazonaws.com"
    }
    
    let scale = UIScreen.main.scale
    let scaledWidth = Int(CGFloat(width) * scale)
    let scaledHeight = Int(CGFloat(height) * scale)
    //let securityKey = "lBgF7SQaW3TDZ75ZiCuPXIDyWoADA6zY3KUkro5i"
    let securityKey = "lBgF7SQaW3TDZ75ZiCuPXIDyWoADA6zY3KUkro5i"
    
    let filterStr = filter != nil ? "filters:\(filter!)/" : ""
    let urlPartToSign = "\(scaledWidth)x\(scaledHeight)/\(filterStr)\(s3Host)/\(path)"
    //let hmacUrlPart = urlPartToSign.hmac(securityKey)
    let hmacUrlPart = "unsafe"
    
    //return "http://images.iam360.io/\(hmacUrlPart)/\(urlPartToSign)"
    return "http://images.dscvr.com/\(hmacUrlPart)/\(urlPartToSign)"
}

private extension String {
    func hmac(_ key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData = Data(bytes: UnsafePointer<UInt8>(result), count: Int(CC_SHA1_DIGEST_LENGTH))
        let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters)
        return hmacBase64
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }
}
