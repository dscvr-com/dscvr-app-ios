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
    let locationSignal = NotificationSignal()
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
    
    var locationPermissionTimer: NSTimer?
    
    var optograph = Optograph.newInstance() 
    
    init() {
        locationEnabled.value = LocationService.enabled
        
        locationLoading <~ locationSignal.signal.map { _ in true }
        
        locationSignal.signal
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil) }
            .map { _ in self.locationEnabled.value }
            .filter(identity)
            .flatMap(.Latest) { _ in
                LocationService.location()
                    .take(1)
                    .on(next: { (lat, lon) in
                        self.optograph.location.latitude = lat
                        self.optograph.location.longitude = lon
                    })
            }
            .mapError { _ in ApiError.Nil }
            .map { (lat, lon) in ["latitude": lat, "longitude": lon] }
            .flatMap(.Latest) { ApiService<LocationMappable>.post("locations/lookup", parameters: $0) }
            .observeNext { location in
                self.locationLoading.value = false
                self.locationFound.value = true
                self.locationText.value = location.text
                self.locationCountry.value = location.country
                self.optograph.location.text = location.text
                self.optograph.location.country = location.country
            }
        
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
        
        previewImageUrl.producer
            .filter(isNotEmpty)
            .take(1)
            .startWithNext { _ in
                self.hashtagStringStatus.value = .Indicated
            }
        
        hashtagStringStatus <~ hashtagStringValid.producer
            .takeWhile { _ in !self.previewImageUrl.value.isEmpty }
            .map { $0 ? .Normal : .Indicated }
        
        textEnabled <~ previewImageUrl.producer.map(isNotEmpty)
            .combineLatestWith(locationFound.producer).map(and)
    
        readyToSubmit <~ previewImageUrl.producer.map(isNotEmpty)
            .combineLatestWith(locationFound.producer).map(and)
            .combineLatestWith(hashtagStringValid.producer).map(and)
    }
    
    func updatePreviewImage() {
        previewImageUrl.value = optograph.previewAssetURL
    }
    
    func post() {
        optograph.person.id = SessionService.sessionData!.id
        
        try! optograph.insertOrUpdate()
        try! optograph.location.insertOrUpdate()
    }
    
    func enableLocation() {
        locationPermissionTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("checkLocationPermission"), userInfo: nil, repeats: true)
        LocationService.askPermission()
    }
    
    @objc func checkLocationPermission() {
        let enabled = LocationService.enabled
        if enabled && locationPermissionTimer != nil {
            self.locationEnabled.value = enabled
            self.locationSignal.notify()
            locationPermissionTimer = nil
        }
    }
}

private struct LocationMappable: Mappable {
    var text = ""
    var country = ""
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        text        <- map["text"]
        country     <- map["country"]
    }
}