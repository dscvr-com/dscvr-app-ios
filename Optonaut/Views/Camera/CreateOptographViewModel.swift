//
//  CreateOptographViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper
import Async
import WebImage

class CreateOptographViewModel {
    
    let previewImageUrl = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let hashtagString = MutableProperty<String>("")
    let hashtagStringValid = MutableProperty<Bool>(true)
    let pending = MutableProperty<Bool>(true)
    let publishLater: MutableProperty<Bool>
    let cameraPreviewEnabled = MutableProperty<Bool>(true)
    
    private var optograph = Optograph.newInstance() 
    
    init() {
        publishLater = MutableProperty(!Reachability.connectedToNetwork())
        
        LocationService.location()
            .on(next: { (lat, lon) in
                self.optograph.location.latitude = lat
                self.optograph.location.longitude = lon
            })
            .mapError { _ in ApiError.Nil }
            .map { (lat, lon) in ["latitude": lat, "longitude": lon] }
            .flatMap(.Latest) { ApiService<LocationMappable>.post("locations/lookup", parameters: $0) }
            .startWithNext { self.location.value = $0.text }
        
        text.producer.startWithNext { self.optograph.text = $0 }
        location.producer.startWithNext { self.optograph.location.text = $0 }
        
        let hashtagRegex = try! NSRegularExpression(pattern: "(#[\\\\u4e00-\\\\u9fa5a-zA-Z0-9]+)\\w*", options: [.CaseInsensitive])
        
        hashtagStringValid <~ hashtagString.producer
            .map { str in
                return !hashtagRegex.matchesInString(str, options: [], range: NSRange(location: 0, length: str.characters.count)).isEmpty
            }
        
        hashtagStringValid.producer
            .filter(identity)
            .startWithNext { _ in
                let str = self.hashtagString.value
                let nsStr = str as NSString
                self.optograph.hashtagString = hashtagRegex
                    .matchesInString(str, options: [], range: NSRange(location: 0, length: str.characters.count))
                    .map { nsStr.substringWithRange($0.range) }
                    .map { $0.lowercaseString }
                    .map { $0.substringFromIndex($0.startIndex.advancedBy(1)) }
                    .joinWithSeparator(",")
            }
    }
    
    func saveAsset(asset: OptographAsset) {
        switch asset {
        case .LeftImage(let data):
            data.writeToFile("\(StaticPath)/\(optograph.leftTextureAssetId).jpg", atomically: true)
        case .RightImage(let data):
            data.writeToFile("\(StaticPath)/\(optograph.rightTextureAssetId).jpg", atomically: true)
        case .PreviewImage(let data):
            data.writeToFile("\(StaticPath)/\(optograph.previewAssetId).jpg", atomically: true)
            SDImageCache.sharedImageCache().storeImage(UIImage(data: data)!, forKey: "\(S3URL)/original/\(optograph.previewAssetId).jpg", toDisk: true)
            previewImageUrl.value = "\(S3URL)/original/\(optograph.previewAssetId).jpg"
        }
    }
    
    func post() -> SignalProducer<Optograph, NSError> {
        pending.value = true
        saveToDatabase()
        
        if !publishLater.value {
            Async.background {
                self.optograph.publish().start()
            }
        }
        
        return SignalProducer(value: optograph)
    }
    
    private func saveToDatabase() {
        optograph.person.id = SessionService.sessionData!.id
        
        try! optograph.insertOrReplace()
        try! optograph.location.insertOrReplace()
    }
}

private struct LocationMappable: Mappable {
    var text = ""
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        text   <- map["text"]
    }
}