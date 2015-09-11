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

class CreateOptographViewModel {
    
    let previewImage = MutableProperty<UIImage>(UIImage(named: "optograph-details-placeholder")!)
    let location = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let pending = MutableProperty<Bool>(true)
    let publishLater: MutableProperty<Bool>
    
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
            .flatMap(.Latest) { parameters in ApiService<LocationMappable>.post("locations/lookup", parameters: parameters) }
            .startWithNext { locationData in self.location.value = locationData.text }
        
        text.producer.startWithNext { self.optograph.text = $0 }
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
            previewImage.value = UIImage(data: data)!
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