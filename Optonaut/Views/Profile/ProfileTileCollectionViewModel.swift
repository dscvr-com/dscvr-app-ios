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

class ProfileTileCollectionViewModel {
    
    enum UploadStatus { case Offline, Uploading, Uploaded }
    let uploadStatus = MutableProperty<UploadStatus>(.Uploaded)
    
    let isPrivate = MutableProperty<Bool>(false)
    let isStitched = MutableProperty<Bool>(false)
    let optographID = MutableProperty<UUID>("")
    
    private var disposable: Disposable?
    var optographBox: ModelBox<Optograph>!
    
    
    func bind(optographID: UUID) {
        disposable?.dispose()
        
        self.optographID.value = optographID
        
        optographBox = Models.optographs[optographID]!
        
        disposable = optographBox.producer
            .skipRepeats()
            .startWithNext { [weak self] optograph in
                self?.isPrivate.value = optograph.isPrivate
                self?.isStitched.value = optograph.isStitched
                if optograph.isPublished {
                    self?.uploadStatus.value = .Uploaded
                } else if optograph.isUploading {
                    self?.uploadStatus.value = .Uploading
                } else {
                    self?.uploadStatus.value = .Offline
                }
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
            let optograph = optographBox.model
            
            optographBox.update { box in
                box.model.isUploading = true
            }
            optographBox.insertOrUpdate { box in
                box.model.shouldBePublished = true
            }
            
            let postParameters = [
                "id": optograph.ID,
                "stitcher_version": StitcherVersion,
                "created_at": optograph.createdAt.toRFC3339String(),
                "optograph_type":"optograph"
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
                            print(failedString)
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
            optographBox.insertOrUpdate { box in
                box.model.shouldBePublished = true
                box.model.isUploading = true
            }
            
            PipelineService.checkUploading()
        }
        
    }
    
}