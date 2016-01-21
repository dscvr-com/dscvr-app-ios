//
//  SaveViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Alamofire
import ObjectMapper
import Async
import SwiftyUserDefaults

class SaveViewModel {
    
    let text = MutableProperty<String>("")
    let isPrivate = MutableProperty<Bool>(false)
    let isReadyForSubmit = MutableProperty<Bool>(false)
    let isInitialized = MutableProperty<Bool>(false)
    let stitcherFinished = MutableProperty<Bool>(false)
    let isReadyForStitching = MutableProperty<Bool>(false)
    let locationLoading = MutableProperty<Bool>(false)
    let postFacebook: MutableProperty<Bool>
    let postTwitter: MutableProperty<Bool>
    let postInstagram: MutableProperty<Bool>
    let isOnline: MutableProperty<Bool>
    let isLoggedIn: MutableProperty<Bool>
    let placeID = MutableProperty<String?>(nil)
    
    var optograph: Optograph!
    
    init(placeholderSignal: Signal<UIImage, NoError>) {
        
        postFacebook = MutableProperty(Defaults[.SessionShareToggledFacebook])
        postTwitter = MutableProperty(Defaults[.SessionShareToggledTwitter])
        postInstagram = MutableProperty(Defaults[.SessionShareToggledInstagram])
        
        isOnline = MutableProperty(Reachability.connectedToNetwork())
        isLoggedIn = MutableProperty(SessionService.isLoggedIn)
        
        postFacebook.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledFacebook] = toggled
            self?.optograph.postFacebook = toggled
        }
        
        postTwitter.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledTwitter] = toggled
            self?.optograph.postTwitter = toggled
        }
        
        postInstagram.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledInstagram] = toggled
            self?.optograph.postInstagram = toggled
        }
        
        isPrivate.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] isPrivate in
            self?.optograph.isPrivate = isPrivate
        }
        
        text.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] text in
            self?.optograph.text = text
        }
        
        if isOnline.value && isLoggedIn.value {
            ApiService<Optograph>.post("optographs", parameters: ["stitcher_version": StitcherVersion])
                .map { (var optograph) -> Optograph in
                    optograph.isPublished = false
                    optograph.isStitched = false
                    optograph.isSubmitted = false
                    optograph.person.ID = Defaults[.SessionPersonID] ?? Person.guestID
                    return optograph
                }
                .on(next: { [weak self] optograph in
                    self?.optograph = optograph
                    try! self?.optograph.insertOrUpdate()
                    try! self?.optograph.location?.insertOrUpdate()
                })
                .zipWith(placeholderSignal.mapError({ _ in ApiError.Nil }))
                .flatMap(.Latest) { (optograph, image) in
                    return ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset", multipartFormData: { form in
                        form.appendBodyPart(data: "placeholder".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
                        form.appendBodyPart(data: UIImageJPEGRepresentation(image, 0.7)!, name: "asset", fileName: "placeholder.jpg", mimeType: "image/jpeg")
                    })
                }
                .on(failed: { [weak self] _ in
                    self?.isOnline.value = false
                    self?.isInitialized.value = true
                })
                .startWithCompleted { [weak self] in
                    self?.isInitialized.value = true
                }
        
            placeID.producer
                .delayLatestUntil(isInitialized.producer)
                .on(next: { [weak self] val in
                    if val == nil {
                        self?.optograph.location = nil
                        try! self?.optograph.insertOrUpdate()
                    }
                })
                .ignoreNil()
                .on(next: { [weak self] _ in
                    self?.locationLoading.value = true
                })
                .mapError { _ in ApiError.Nil }
                .flatMap(.Latest) { ApiService<GeocodeDetails>.get("locations/geocode-details/\($0)") }
                .on(
                    next: { [weak self] geocodeDetails in
                        self?.locationLoading.value = false
                        let coords = LocationService.lastLocation()!
                        var location = Location.newInstance()
                        location.latitude = coords.latitude
                        location.longitude = coords.longitude
                        location.text = geocodeDetails.name
                        location.country = geocodeDetails.country
                        location.countryShort = geocodeDetails.countryShort
                        location.place = geocodeDetails.place
                        location.region = geocodeDetails.region
                        self?.optograph.location = location
                        try! self?.optograph.insertOrUpdate()
                        try! self?.optograph.location?.insertOrUpdate()
                    },
                    failed: { [weak self] _ in
                        let coords = LocationService.lastLocation()!
                        var location = Location.newInstance()
                        location.latitude = coords.latitude
                        location.longitude = coords.longitude
                        self?.optograph.location = location
                        try! self?.optograph.insertOrUpdate()
                        try! self?.optograph.location?.insertOrUpdate()
                    }
                )
                .start()
        } else {
            optograph = Optograph.newInstance()
            optograph.person.ID = Defaults[.SessionPersonID] ?? Person.guestID
            try! optograph.insertOrUpdate()
            try! optograph.location?.insertOrUpdate()
            
            isInitialized.value = true
            
            placeID.producer
                .delayLatestUntil(isInitialized.producer)
                .ignoreNil()
                .startWithNext { [weak self] geocodeDetails in
                    let coords = LocationService.lastLocation()!
                    var location = Location.newInstance()
                    location.latitude = coords.latitude
                    location.longitude = coords.longitude
                    self?.optograph.location = location
                    try! self?.optograph.insertOrUpdate()
                    try! self?.optograph.location?.insertOrUpdate()
                }
        }
        
        isReadyForStitching <~ stitcherFinished.producer
            .combineLatestWith(isInitialized.producer).map(and)
            .filter(identity)
            .take(1)
        
        isReadyForSubmit <~ isInitialized.producer
            .combineLatestWith(locationLoading.producer.map(negate)).map(and)
            .combineLatestWith(stitcherFinished.producer).map(and)
    }
    
    func submit(shouldBePublished: Bool) -> SignalProducer<Void, NoError> {
        
        optograph.shouldBePublished = shouldBePublished
        optograph.isSubmitted = true
        
        try! optograph.insertOrUpdate()
        
        if isOnline.value {
            var parameters: [String: AnyObject] = [
                "text": optograph.text,
                "is_private": optograph.isPrivate,
                "post_facebook": optograph.postFacebook,
                "post_twitter": optograph.postTwitter,
                "direction_phi": optograph.directionPhi,
                "direction_theta": optograph.directionTheta,
            ]
            if let location = optograph.location {
                parameters["location"] = location.toJSON()
            }
            
            return ApiService<EmptyResponse>.put("optographs/\(optograph.ID)", parameters: parameters)
                .ignoreError()
                .map { _ in () }
        } else {
            return SignalProducer(value: ())
        }
    }
}

private struct GeocodeDetails: Mappable {
    var name = ""
    var country = ""
    var countryShort = ""
    var place = ""
    var region = ""
    var POI = false
    
    init() {}
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        name            <- map["name"]
        country         <- map["country"]
        countryShort    <- map["country_short"]
        place           <- map["place"]
        region          <- map["region"]
        POI             <- map["poi"]
    }
}