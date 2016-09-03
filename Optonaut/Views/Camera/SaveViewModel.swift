//
//  SaveViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result
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
    let isLoggedIn = MutableProperty<Bool>(false)
    let placeID = MutableProperty<String?>(nil)
    let isOptoInServer = MutableProperty<Bool>(false)
    
    let optographBox: ModelBox<Optograph>
    var locationBox: ModelBox<Location>?
    
    
    private let placeholder = MutableProperty<UIImage?>(nil)
    
    init(placeholderSignal: Signal<UIImage, NoError>, readyNotification: NotificationSignal<Void>) {
        
        placeholder <~ placeholderSignal.map { image -> UIImage? in return image }
        
        var optograph = Optograph.newInstance()
        
        optograph.personID = SessionService.personID
        optograph.isPublished = false
        optograph.isStitched = false
        optograph.isSubmitted = false
        optograph.isOnServer = false
        optograph.leftCubeTextureStatusUpload = CubeTextureStatus()
        optograph.rightCubeTextureStatusUpload = CubeTextureStatus()
        optograph.leftCubeTextureStatusSave = CubeTextureStatus()
        optograph.rightCubeTextureStatusSave = CubeTextureStatus()
        
        optographBox = Models.optographs.create(optograph)
        
        postFacebook = MutableProperty(Defaults[.SessionShareToggledFacebook])
        postTwitter = MutableProperty(Defaults[.SessionShareToggledTwitter])
        postInstagram = MutableProperty(Defaults[.SessionShareToggledInstagram])
        
        isOnline = MutableProperty(Reachability.connectedToNetwork())
        
        postFacebook.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledFacebook] = toggled
            self?.optographBox.insertOrUpdate {
                return $0.model.postFacebook = toggled
            }
        }
        
        postTwitter.producer.delayLatestUntil(isInitialized.producer).startWithNext { [weak self] toggled in
            Defaults[.SessionShareToggledTwitter] = toggled
            self?.optographBox.insertOrUpdate {
                return $0.model.postTwitter = toggled
            }
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
        
        readyNotification.signal.observeNext {
            
            self.isLoggedIn.value = SessionService.isLoggedIn
            
            if self.isOnline.value && self.isLoggedIn.value {
                
                var postParameters = [String:String]()
                
                var uploadModeStr = ""
                if Defaults[.SessionUploadMode] == "theta" {
                    uploadModeStr = "-theta"
                    postParameters = [
                        "id": optograph.ID,
                        "stitcher_version": StitcherVersion,
                        "created_at": optograph.createdAt.toRFC3339String(),
                        "optograph_type":"theta",
                        "optograph_platform": "iOS \(Defaults[.SessionPhoneOS]!)",
                        "optograph_model":"\(Defaults[.SessionPhoneModel]!)",
                        "optograph_make":"Apple"
                    ]
                } else {
                    uploadModeStr = ""
                    postParameters = [
                        "id": optograph.ID,
                        "stitcher_version": StitcherVersion,
                        "created_at": optograph.createdAt.toRFC3339String(),
                        "optograph_type":Defaults[.SessionUseMultiRing] ? "optograph_3":"optograph_1",
                        "optograph_platform": "iOS \(Defaults[.SessionPhoneOS]!)",
                        "optograph_model":"\(Defaults[.SessionPhoneModel]!)",
                        "optograph_make":"Apple"
                    ]
                }
                print(postParameters)
                
                ApiService<OptographApiModel>.post("optographs", parameters: postParameters)
                    .on(next: { [weak self] optograph in
                        self?.optographBox.insertOrUpdate { box in
                            box.model.shareAlias = optograph.shareAlias
                            box.model.isOnServer = true
                            box.model.personID = SessionService.personID
                        }
                    })
                    .zipWith(self.placeholder.producer.ignoreNil().take(1).mapError({ _ in ApiError.Nil }))
                    .flatMap(.Latest) { (optograph, image) in
                        
                        return ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset\(uploadModeStr)", multipartFormData: { form in
                            form.appendBodyPart(data: "placeholder".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
                            form.appendBodyPart(data: UIImageJPEGRepresentation(image, 1)!, name: "asset", fileName: "placeholder.jpg", mimeType: "image/jpeg")
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
                
                self.placeID.producer
                    .delayLatestUntil(self.isInitialized.producer)
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
                self.optographBox.insertOrUpdate()
                print("pumasok dito sa else ng readynotification")
                self.isInitialized.value = true
                self.placeID.producer
                    .delayLatestUntil(self.isInitialized.producer)
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
        }
        
        isInitialized.producer.startWithNext{ print("isInitialized \($0)")}
        stitcherFinished.producer.startWithNext{ print("stitcherFinished \($0)")}
        locationLoading.producer.startWithNext{ print("locationLoading \($0)")}
        
        isReadyForStitching <~ stitcherFinished.producer
            .combineLatestWith(isInitialized.producer).map(and)
            .filter(isTrue)
            .take(1)
        
        isReadyForSubmit <~ isInitialized.producer
            .combineLatestWith(locationLoading.producer.map(negate)).map(and)
            .combineLatestWith(stitcherFinished.producer).map(and)
        
    }
    
    func deleteOpto() {
        
        
        SignalProducer<Bool, ApiError>(value: true)
            .flatMap(.Latest) { followedBefore in
                ApiService<EmptyResponse>.delete("optographs/\(self.optographBox.model.ID)")
            }
            .start()
        
        optographBox.insertOrUpdate { box in
            print("deleted on: \(NSDate())")
            print(box.model.ID)
            return box.model.deletedAt = NSDate()
        }
    }
    
    func uploadForThetaOk() {
        
        let optograph = optographBox.model
        
        optographBox.insertOrUpdate { box in
            
            box.model.isStitched = true
            box.model.stitcherVersion = StitcherVersion
            box.model.isInFeed = true
            
            box.model.leftCubeTextureStatusUpload?.status[0] = true
            box.model.leftCubeTextureStatusUpload?.status[1] = true
            box.model.leftCubeTextureStatusUpload?.status[2] = true
            box.model.leftCubeTextureStatusUpload?.status[3] = true
            box.model.leftCubeTextureStatusUpload?.status[4] = true
            box.model.leftCubeTextureStatusUpload?.status[5] = true
            
            box.model.rightCubeTextureStatusUpload?.status[0] = true
            box.model.rightCubeTextureStatusUpload?.status[1] = true
            box.model.rightCubeTextureStatusUpload?.status[2] = true
            box.model.rightCubeTextureStatusUpload?.status[3] = true
            box.model.rightCubeTextureStatusUpload?.status[4] = true
            box.model.rightCubeTextureStatusUpload?.status[5] = true
            
            box.model.rightCubeTextureStatusSave = nil
            box.model.leftCubeTextureStatusSave = nil
            
            box.model.rightCubeTextureStatusUpload = nil
            box.model.rightCubeTextureStatusUpload = nil
            
            box.model.isPublished = true
            box.model.isUploading = false
            
            PipelineService.stitchingStatus.value = .Stitching(1)
            PipelineService.stitchingStatus.value = .StitchingFinished(optograph.ID)
            
        }
    }
    
    func submit(shouldBePublished: Bool, directionPhi: Double, directionTheta: Double) -> SignalProducer<Void, NoError> {
        
        optographBox.insertOrUpdate { box in
            box.model.shouldBePublished = shouldBePublished
            box.model.isSubmitted = true
            box.model.directionPhi = directionPhi
            box.model.directionTheta = directionTheta
            if (Defaults[.SessionUploadMode]) != "theta" {
                box.model.ringCount = Defaults[.SessionUseMultiRing] ? "three":"one"
                print("uploading not theta")
            }
        }
        if isOnline.value && isLoggedIn.value {
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
            
            print("this is my parameters \(parameters) this is my id \(optograph.ID)")
            
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