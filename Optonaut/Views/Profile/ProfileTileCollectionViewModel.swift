//
//  TileCollectionViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite
import SwiftyUserDefaults

class ProfileTileCollectionViewModel {
    
    enum UploadStatus { case Offline, Uploading, Uploaded }
    let uploadStatus = MutableProperty<UploadStatus>(.Uploaded)
    
    let isPrivate = MutableProperty<Bool>(false)
    let isStitched = MutableProperty<Bool>(false)
    let optographID = MutableProperty<UUID>("")
    
    private var disposable: Disposable?
    var optographBox: ModelBox<Optograph>!
    var userId = MutableProperty<Bool>(false)
    var uploadPercentStatus = MutableProperty<Float>(0.0)
    
    var leftCount = 0
    var rightCount = 0
    
    func bind(optographID: UUID) {
        disposable?.dispose()
        
        self.optographID.value = optographID
        
        optographBox = Models.optographs[optographID]!
        
        disposable = optographBox.producer
            .skipRepeats()
            .startWithNext { [weak self] optograph in
                self?.isPrivate.value = optograph.isPrivate
                self?.isStitched.value = optograph.isStitched
                if optograph.personID == SessionService.personID {
                    self?.userId.value = true
                }
                
                if optograph.isPublished {
                    self?.uploadStatus.value = .Uploaded
                } else if optograph.isUploading {
                    self?.uploadStatus.value = .Uploading
                    self?.getUploadStatus(optograph.rightCubeTextureStatusUpload?.status, lindex: optograph.leftCubeTextureStatusUpload?.status)
                } else {
                    self?.uploadStatus.value = .Offline
                }
            }
    }
    
    func getUploadStatus(rindex:[Bool]?,lindex:[Bool]?) {
        
        var val = 1
        
        print("rindex>>",rindex)
        print("lindex>>",lindex)
        
        if lindex != nil {
            val = 0
            for l in lindex! {
                if l {
                    val += 1
                    leftCount = val
                }
            }
        }
        
        if rindex != nil {
            val = 0
            for r in rindex! {
                if r {
                    val += 1
                    rightCount = val
                }
            }
        }
        
        val = leftCount + rightCount
        
        print(Float(val) * 0.08333333)
        
        self.uploadPercentStatus.value = Float(val) * 0.08333333
    }
    
    func deleteOpto() {
        
        
        SignalProducer<Bool, ApiError>(value: true)
            .flatMap(.Latest) { followedBefore in
                ApiService<EmptyResponse>.delete("optographs/\(self.optographBox.model.ID)")
            }
            .start()
        
        PipelineService.stopStitching()
        optographBox.insertOrUpdate { box in
            print("date today \(NSDate())")
            print(box.model.ID)
            return box.model.deletedAt = NSDate()
        }
        
    }
    
    func goUpload() {
        if Reachability.connectedToNetwork() {
            self.upload()
        } else {
            print("offline")
        }
    }
    
    func upload() {
        
        if !optographBox.model.isOnServer {
            print("pumasok sa if upload")
            let optograph = optographBox.model
            
            optographBox.update { box in
                box.model.isUploading = true
            }
            optographBox.insertOrUpdate { box in
                box.model.shouldBePublished = true
            }
            let tempString = optograph.ringCount == "one" ? "optograph_1":"optograph_3"
            
            let postParameters = [
                "id": optograph.ID,
                "stitcher_version": StitcherVersion,
                "created_at": optograph.createdAt.toRFC3339String(),
                "optograph_type":tempString,
                "optograph_platform": "iOS \(Defaults[.SessionPhoneOS]!)",
                "optograph_model":"\(Defaults[.SessionPhoneModel]!)",
                "optograph_make":"Apple"
                ]
            
            var putParameters: [String: AnyObject] = [
                "text": optograph.text,
                "is_private": optograph.isPrivate,
                "post_facebook": optograph.postFacebook,
                "post_twitter": optograph.postTwitter,
                "direction_phi": optograph.directionPhi,
                "direction_theta": optograph.directionTheta,
                ]
            if let locationID = optograph.locationID, location = Models.locations[locationID]?.model {
                putParameters["location"] = [
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
            
            print(postParameters)
            
            SignalProducer<Bool, ApiError>(value: !optographBox.model.shareAlias.isEmpty)
                .flatMap(.Latest) { alreadyPosted -> SignalProducer<Void, ApiError> in
                    print(alreadyPosted)
                    if alreadyPosted {
                        return SignalProducer(value: ())
                    } else {
                        return ApiService<OptographApiModel>.post("optographs", parameters: postParameters)
                            .on(next: { [weak self] optograph in
                                self?.optographBox.insertOrUpdate { box in
                                    box.model.shareAlias = optograph.shareAlias
                                }
                                })
                            .map { _ in () }
                    }
                }
                .flatMap(.Latest) {
                    ApiService<EmptyResponse>.put("optographs/\(optograph.ID)", parameters: putParameters)
                        .on(failed: { [weak self] failedString in
                            print("FAiled",failedString)
                            self?.optographBox.update { box in
                                box.model.isUploading = false
                            }
                            })
                }
                .on(next: { [weak self] optograph in
                    print("success \(optograph)")
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isOnServer = true
                    }
                    })
                .startWithCompleted {
                    PipelineService.checkUploading()
            }
            
            
        } else {
            print("pumasok sa else upload")
            optographBox.insertOrUpdate { box in
                box.model.shouldBePublished = true
                box.model.isUploading = true
            }
            
            PipelineService.checkUploading()
        }
        
    }
    
}