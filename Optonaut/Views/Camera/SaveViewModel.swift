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
    
    let optographBox: ModelBox<Optograph>
    var locationBox: ModelBox<Location>?
    
    init(placeholderSignal: Signal<UIImage, NoError>) {
        
        var optograph = Optograph.newInstance()
        
        optograph.personID = Defaults[.SessionPersonID] ?? Person.guestID
        optograph.isPublished = false
        optograph.isStitched = false
        optograph.isSubmitted = false
        optograph.leftCubeTextureStatusUpload = CubeTextureStatus()
        optograph.rightCubeTextureStatusUpload = CubeTextureStatus()
        optograph.leftCubeTextureStatusSave = CubeTextureStatus()
        optograph.rightCubeTextureStatusSave = CubeTextureStatus()
        
        optographBox = Models.optographs.create(optograph)
        
        postFacebook = MutableProperty(Defaults[.SessionShareToggledFacebook])
        postTwitter = MutableProperty(Defaults[.SessionShareToggledTwitter])
        postInstagram = MutableProperty(Defaults[.SessionShareToggledInstagram])
        
        isOnline = MutableProperty(Reachability.connectedToNetwork())
        isLoggedIn = MutableProperty(SessionService.isLoggedIn)
        
        postFacebook.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledFacebook] = toggled
            self?.optographBox.insertOrUpdate { $0.model.postFacebook = toggled }
        }
        
        postTwitter.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledTwitter] = toggled
            self?.optographBox.insertOrUpdate { $0.model.postTwitter = toggled }
        }
        
        postInstagram.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledInstagram] = toggled
            self?.optographBox.insertOrUpdate { $0.model.postInstagram = toggled }
        }
        
        isPrivate.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] isPrivate in
            self?.optographBox.insertOrUpdate { $0.model.isPrivate = isPrivate }
        }
        
        text.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] text in
            self?.optographBox.insertOrUpdate { $0.model.text = text }
        }
        
        if isOnline.value && isLoggedIn.value {
            ApiService<OptographApiModel>.post("optographs", parameters: ["id": optograph.ID, "stitcher_version": StitcherVersion])
                .on(next: { [weak self] optograph in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.shareAlias = optograph.shareAlias
                        box.model.createdAt = optograph.createdAt
                    }
                })
                .zipWith(placeholderSignal.mapError({ _ in ApiError.Nil }))
                .flatMap(.Latest) { (optograph, image) in
                    return ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset", multipartFormData: { form in
                        form.appendBodyPart(data: "placeholder".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
                        form.appendBodyPart(data: UIImageJPEGRepresentation(image, 0.7)!, name: "asset", fileName: "placeholder.jpg", mimeType: "image/jpeg")
                    })
                }
                .on(
                    completed: { [weak self] in
                        self?.isInitialized.value = true
                    },
                    failed: { [weak self] _ in
                        self?.isOnline.value = false
                        self?.isInitialized.value = true
                    }
                )
                .start()
            
            placeID.producer
                .delayLatestUntil(isInitialized.producer)
                .on(next: { [weak self] val in
                    if val == nil {
                        self?.locationBox?.removeFromCache()
                        self?.optographBox.insertOrUpdate { $0.model.locationID = nil }
                    }
                })
                .ignoreNil()
                .on(next: { [weak self] _ in
                    self?.locationLoading.value = true
                })
                .flatMap(.Latest) { placeID -> SignalProducer<Location, NoError> in
                    return ApiService<GeocodeDetails>.get("locations/geocode-details/\(placeID)")
                        .map { geocodeDetails in
                            let coords = LocationService.lastLocation()!
                            var location = Location.newInstance()
                            location.latitude = coords.latitude
                            location.longitude = coords.longitude
                            location.text = geocodeDetails.name
                            location.country = geocodeDetails.country
                            location.countryShort = geocodeDetails.countryShort
                            location.place = geocodeDetails.place
                            location.region = geocodeDetails.region
                            return location
                        }
                        .failedAsNext {
                            let coords = LocationService.lastLocation()!
                            var location = Location.newInstance()
                            location.latitude = coords.latitude
                            location.longitude = coords.longitude
                            return location
                        }
                }
                .startWithNext { [weak self] location in
                    self?.locationLoading.value = false
                    self?.locationBox?.removeFromCache()
                    self?.locationBox = Models.locations.create(location)
                    self?.locationBox!.insertOrUpdate()
                    self?.optographBox.insertOrUpdate { box in
                        box.model.locationID = location.ID
                    }
                }
        } else {
            optographBox.insertOrUpdate()
            
            isInitialized.value = true
            
            placeID.producer
                .delayLatestUntil(isInitialized.producer)
                .ignoreNil()
                .startWithNext { [weak self] _ in
                    let coords = LocationService.lastLocation()!
                    var location = Location.newInstance()
                    location.latitude = coords.latitude
                    location.longitude = coords.longitude
                    self?.locationBox?.removeFromCache()
                    self?.locationBox = Models.locations.create(location)
                    self?.locationBox!.insertOrUpdate()
                    self?.optographBox.insertOrUpdate { box in
                        box.model.locationID = location.ID
                    }
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
    
    func submit(shouldBePublished: Bool, directionPhi: Double, directionTheta: Double) -> SignalProducer<Void, NoError> {
        
        optographBox.insertOrUpdate { box in
            box.model.shouldBePublished = shouldBePublished
            box.model.isSubmitted = true
            box.model.directionPhi = directionPhi
            box.model.directionTheta = directionTheta
        }
        
        if isOnline.value {
            let optograph = optographBox.model
            var parameters: [String: AnyObject] = [
                "text": optograph.text,
                "is_private": optograph.isPrivate,
                "post_facebook": optograph.postFacebook,
                "post_twitter": optograph.postTwitter,
                "direction_phi": optograph.directionPhi,
                "direction_theta": optograph.directionTheta,
            ]
            if let location = locationBox?.model {
                parameters["location"] = [
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "text": location.text,
                    "country": location.country,
                    "country_short": location.countryShort,
                    "place": location.place,
                    "region": location.region,
                    "poi": location.POI,
                ]
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