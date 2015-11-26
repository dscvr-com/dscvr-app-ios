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
import SwiftyUserDefaults

class CreateOptographViewModel {
    
    let previewImageUrl = MutableProperty<String>("")
    let locationSignal = NotificationSignal<Void>()
    let locationText = MutableProperty<String>("")
    let locationCountry = MutableProperty<String>("")
    let locationFound = MutableProperty<Bool>(false)
    let locationEnabled = MutableProperty<Bool>(false)
    let locationLoading = MutableProperty<Bool>(true)
    let text = MutableProperty<String>("")
    let textEnabled = MutableProperty<Bool>(false)
    let hashtagString = MutableProperty<String>("")
    let hashtagStringValid = MutableProperty<Bool>(false)
    let hashtagStringStatus = MutableProperty<LineTextField.Status>(.Disabled)
    let cameraPreviewEnabled = MutableProperty<Bool>(true)
    let readyToSubmit = MutableProperty<Bool>(false)
    let recorderCleanedUp = MutableProperty<Bool>(false)
    let isPrivate = MutableProperty<Bool>(false)
    
    var locationPermissionTimer: NSTimer?
    
    var optograph = Optograph.newInstance() 
    
    init() {
        locationEnabled.value = LocationService.enabled
        
        locationLoading <~ locationSignal.signal.map { _ in true }
        
        locationSignal.signal
            .map { _ in self.locationEnabled.value }
            .filter(identity)
            .flatMap(.Latest) { _ in
                LocationService.location()
                    .take(1)
                    .on(next: { (lat, lon) in
                        var location = Location.newInstance()
                        location.latitude = lat
                        location.longitude = lon
                        self.optograph.location = location
                    })
                    .ignoreError()
            }
            .flatMap(.Latest) { (lat, lon) -> SignalProducer<LocationMappable, NoError> in
                if Reachability.connectedToNetwork() {
                    return ApiService.post("locations/lookup", parameters: ["latitude": lat, "longitude": lon])
                        .on(error: { _ in
                            self.locationLoading.value = false
                        })
                        .ignoreError()
                } else {
                    return SignalProducer(value: LocationMappable(text: "\(lat.roundToPlaces(1)), \(lon.roundToPlaces(1))", country: ""))
                }
            }
            .observeNext { location in
                self.locationLoading.value = false
                self.locationFound.value = true
                self.locationText.value = location.text
                self.locationCountry.value = location.country
                self.optograph.location!.text = location.text
                self.optograph.location!.country = location.country
            }
        
        isPrivate.producer.startWithNext { self.optograph.isPrivate = $0 }
        
        text.producer.startWithNext { self.optograph.text = $0 }
        
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
        
        hashtagStringStatus <~ previewImageUrl.producer.map(isNotEmpty)
            .combineLatestWith(hashtagStringValid.producer)
            .map { (requirements, validHashtag) in
                if !requirements {
                    return .Disabled
                } else {
                    return validHashtag ? .Normal : .Indicated
                }
            }
        
        textEnabled <~ previewImageUrl.producer.map(isNotEmpty)
    
        readyToSubmit <~ previewImageUrl.producer.map(isNotEmpty)
            .combineLatestWith(hashtagStringValid.producer).map(and)
            .combineLatestWith(recorderCleanedUp.producer).map(and)
    }
    
    func updatePreviewImage() {
        previewImageUrl.value = ImageURL(optograph.previewAssetID)
    }
    
    func post() {
        optograph.person.ID = Defaults[.SessionPersonID] ?? Person.guestID
        
        try! optograph.insertOrUpdate()
        try! optograph.location?.insertOrUpdate()
    }
    
    func enableLocation() {
        locationPermissionTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("checkLocationPermission"), userInfo: nil, repeats: true)
        LocationService.askPermission()
    }
    
    @objc func checkLocationPermission() {
        let enabled = LocationService.enabled
        if enabled && locationPermissionTimer != nil {
            self.locationEnabled.value = enabled
            self.locationSignal.notify(())
            locationPermissionTimer = nil
        }
    }
}

private struct LocationMappable {
    var text = ""
    var country = ""
}


extension LocationMappable: Mappable {
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        text        <- map["text"]
        country     <- map["country"]
    }
}