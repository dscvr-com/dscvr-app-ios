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
        hashtagString.producer.startWithNext { self.optograph.hashtagString = $0 }
        location.producer.startWithNext { self.optograph.location.text = $0 }
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