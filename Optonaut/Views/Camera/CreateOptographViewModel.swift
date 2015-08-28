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
    
    let previewUrl = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let pending = MutableProperty<Bool>(true)
    let publishLater: MutableProperty<Bool>
    
    private var optograph: Optograph
    
    init() {
        // TODO add person reference
        optograph = Optograph.newInstance() as! Optograph
        
        publishLater = MutableProperty(!Reachability.connectedToNetwork())
        
        LocationService.location()
            .on(next: { (lat, lon) in
                self.optograph.location.latitude = lat
                self.optograph.location.longitude = lon
            })
            .mapError { _ in ApiError.Nil }
            .map { (lat, lon) in ["latitude": lat, "longitude": lon] }
            .flatMap(.Latest) { parameters in ApiService<LocationMappable>.post("locations/lookup", parameters: parameters) }
            .start(next: { locationData in
                self.location.value = locationData.text
            })
        
        text.producer.start(next: { self.optograph.text = $0 })
        location.producer.start(next: { self.optograph.location.text = $0 })
    }
    
    func saveImages(images: ImagePair) {
        try! optograph.saveImages(images)
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
        optograph.person.id = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.PersonId.rawValue) as! UUID
        
        try! optograph.save()
        try! optograph.location.save()
    }
}

private struct LocationMappable: Mappable {
    var text = ""
    
    private static func newInstance() -> Mappable {
        return LocationMappable()
    }
    
    mutating func mapping(map: Map) {
        text   <- map["text"]
    }
}