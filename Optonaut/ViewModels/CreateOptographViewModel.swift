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
    let publishedLater: MutableProperty<Bool>
    
    private var optograph: Optograph
    
    init() {
        // TODO add person reference
        optograph = Optograph.newInstance() as! Optograph
        
        publishedLater = MutableProperty(!Reachability.connectedToNetwork())
        
        LocationHelper.location()
            .on(next: { (lat, lon) in
                self.optograph.location.latitude = lat
                self.optograph.location.longitude = lon
            })
            .map { (lat, lon) in ["latitude": lat, "longitude": lon] }
            .flatMap(.Latest) { parameters in Api<LocationMappable>.post("locations/lookup", parameters: parameters) }
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
        
        if !publishedLater.value {
            Async.background {
                self.optograph.publish().start()
            }
        }
        
        return SignalProducer(value: optograph)
    }
    
    private func saveToDatabase() {
        let location = optograph.location
        let personId = NSUserDefaults.standardUserDefaults().objectForKey(PersonDefaultsKeys.PersonId.rawValue) as! UUID
        
        try! DatabaseManager.defaultConnection.run(
            LocationTable.insert(or: .Replace,
                LocationSchema.id <-- location.id,
                LocationSchema.text <-- location.text,
                LocationSchema.createdAt <-- location.createdAt,
                LocationSchema.latitude <-- location.latitude,
                LocationSchema.longitude <-- location.longitude
            )
        )
        
        try! DatabaseManager.defaultConnection.run(
            OptographTable.insert(or: .Replace,
                OptographSchema.id <-- optograph.id,
                OptographSchema.text <-- optograph.text,
                OptographSchema.personId <-- personId,
                OptographSchema.createdAt <-- optograph.createdAt,
                OptographSchema.isStarred <-- optograph.isStarred,
                OptographSchema.starsCount <-- optograph.starsCount,
                OptographSchema.commentsCount <-- optograph.commentsCount,
                OptographSchema.viewsCount <-- optograph.viewsCount,
                OptographSchema.locationId <-- location.id,
                OptographSchema.isPublished <-- optograph.isPublished
            )
        )
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