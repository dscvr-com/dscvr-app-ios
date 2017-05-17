//
//  SaveViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveSwift
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
    
    
    fileprivate let placeholder = MutableProperty<UIImage?>(nil)
    
    init(placeholderSignal: Signal<UIImage, NoError>, readyNotification: NotificationSignal<Void>) {
        
        placeholder <~ placeholderSignal.map { image -> UIImage? in return image }
        
        var optograph = Optograph.newInstance()
        
        print("personId",SessionService.personID)
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
        
        postFacebook.producer.delayLatestUntil(triggerProducer: isInitialized.producer).startWithValues { [weak self] toggled in
            Defaults[.SessionShareToggledFacebook] = toggled
            self?.optographBox.insertOrUpdate {
                return $0.model.postFacebook = toggled
            }
        }
        
        postTwitter.producer.delayLatestUntil(triggerProducer: isInitialized.producer).startWithValues { [weak self] toggled in
            Defaults[.SessionShareToggledTwitter] = toggled
            self?.optographBox.insertOrUpdate {
                return $0.model.postTwitter = toggled
            }
        }
        
        postInstagram.producer.delayLatestUntil(triggerProducer: isInitialized.producer).startWithValues { [weak self] toggled in
            Defaults[.SessionShareToggledInstagram] = toggled
            self?.optographBox.insertOrUpdate { $0.model.postInstagram = toggled }
        }
        
        isPrivate.producer.delayLatestUntil(triggerProducer: isInitialized.producer).startWithValues { [weak self] isPrivate in
            self?.optographBox.insertOrUpdate { $0.model.isPrivate = isPrivate }
        }
        
        text.producer.delayLatestUntil(triggerProducer: isInitialized.producer).startWithValues { [weak self] text in
            self?.optographBox.insertOrUpdate { $0.model.text = text }
        }
        
        readyNotification.signal.observeValues {
            self.optographBox.insertOrUpdate()
            self.isInitialized.value = true
            
            self.placeID.producer
                .delayLatestUntil(triggerProducer: self.isInitialized.producer)
                .skipNil()
                .startWithValues { [weak self] _ in
                    let coords = LocationService.lastLocation()!
                    var location = Location.newInstance()
                    location.latitude = coords.latitude
                    location.longitude = coords.longitude
                    self?.locationBox?.removeFromCache()
                    self?.locationBox = Models.locations.create(location)
                    self?.optographBox.insertOrUpdate { box in
                        box.model.locationID = location.ID
                    }
            }
        }

        isInitialized.producer.startWithValues{ print("isInitialized \($0)")}
        stitcherFinished.producer.startWithValues{ print("stitcherFinished \($0)")}
        locationLoading.producer.startWithValues{ print("locationLoading \($0)")}
        
        isReadyForStitching <~ stitcherFinished.producer
            .combineLatest(with: isInitialized.producer).map(and)
            .filter(isTrue)
            .take(first: 1)
        
        isReadyForSubmit <~ isInitialized.producer
            .combineLatest(with: locationLoading.producer.map(negate)).map(and)
            .combineLatest(with: stitcherFinished.producer).map(and)
        
    }
    
    func deleteOpto() {
        
        optographBox.insertOrUpdate { box in
            print("deleted on: \(Date())")
            print(box.model.ID)
            return box.model.deletedAt = Date()
        }
    }
    
    func submit(_ shouldBePublished: Bool, directionPhi: Double, directionTheta: Double) -> SignalProducer<Void, NoError> {
        
        optographBox.insertOrUpdate { box in
            box.model.shouldBePublished = shouldBePublished
            box.model.isSubmitted = true
            box.model.directionPhi = directionPhi
            box.model.directionTheta = directionTheta
            if (Defaults[.SessionUploadMode]) != "theta" {
                box.model.ringCount = Defaults[.SessionUseMultiRing] ? "three":"one"
            }
        }
        return SignalProducer(value: ())
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
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        name            <- map["name"]
        country         <- map["country"]
        countryShort    <- map["country_short"]
        place           <- map["place"]
        region          <- map["region"]
        POI             <- map["poi"]
    }
}
