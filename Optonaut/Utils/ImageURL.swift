//
//  ImageURL.swift
//  Optonaut
//
//  Created by Johannes Schickling on 03/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
//import CommonCrypto

func ImageURL(uuid: String, width: Int = 0, height: Int = 0) -> String {
    return buildURL(uuid, width: width, height: height, filter: nil)
}

enum ImageURLDimension { case Width, Height }

func ImageURL(uuid: String, fullDimension: ImageURLDimension) -> String {
    switch fullDimension {
    case .Width: return ImageURL(uuid, width: Int(UIScreen.mainScreen().bounds.width), height: 0)
    case .Height: return ImageURL(uuid, width: 0, height: Int(UIScreen.mainScreen().bounds.height))
    }
}

func ImageURL(uuid: String, size: Int, face: Int, x: Float, y: Float, d: Float) -> String {
    return buildURL(uuid, width: 0, height: 0, filter: "cube(\(face),\(x),\(y),\(d),\(size))")
}

enum TextureSide { case Left, Right }

func TextureURL(optographID: String, side: TextureSide, size: Int, face: Int, x: Float, y: Float, d: Float) -> String {
    let sideLetter = side == .Left ? "l" : "r"
    return buildURL("textures/\(optographID)/\(sideLetter)\(face).jpg", width: 0, height: 0, filter: "subface(\(x),\(y),\(d),\(size))")
}

private func buildURL(path: String, width: Int, height: Int, filter: String?) -> String {
    let s3Host: String
    
    switch Env {
//    case .Development: s3Host = "optonaut-ios-beta-dev.s3.amazonaws.com"
    case .Staging: s3Host = "optonaut-ios-beta-staging.s3.amazonaws.com"
    case .Production, .Development: s3Host = "resources.optonaut.co.s3.amazonaws.com"
    }
    
    let scale = Int(UIScreen.mainScreen().scale)
    let securityKey = "lBgF7SQaW3TDZ75ZiCuPXIDyWoADA6zY3KUkro5i"
    
    let filterStr = filter != nil ? "filters:\(filter!)/" : ""
    let urlPartToSign = "\(width * scale)x\(height * scale)/\(filterStr)\(s3Host)/\(path)"
    let hmacUrlPart = urlPartToSign.hmac(securityKey)
    
    return "http://images.optonaut.co/\(hmacUrlPart)/\(urlPartToSign)"
}

private extension String {
    func hmac(key: String) -> String {
        let cKey = key.cStringUsingEncoding(NSUTF8StringEncoding)
        let cData = self.cStringUsingEncoding(NSUTF8StringEncoding)
        var result = [CUnsignedChar](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData = NSData(bytes: result, length: Int(CC_SHA1_DIGEST_LENGTH))
        let hmacBase64 = hmacData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding76CharacterLineLength)
        return hmacBase64
            .stringByReplacingOccurrencesOfString("/", withString: "_")
            .stringByReplacingOccurrencesOfString("+", withString: "-")
    }
}