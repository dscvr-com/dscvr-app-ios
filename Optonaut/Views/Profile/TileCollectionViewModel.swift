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

class TileCollectionViewModel {
    
    enum UploadStatus { case Offline, Uploading, Uploaded }
    
    let isPrivate = MutableProperty<Bool>(false)
    let isStitched = MutableProperty<Bool>(false)
    let uploadStatus = MutableProperty<UploadStatus>(.Uploaded)
    let optographID = MutableProperty<UUID>("")
    
    let imageURL = MutableProperty<String>("")
    
    private var disposable: Disposable?
    
    private var optographBox: ModelBox<Optograph>!
    
    func bind(optographID: UUID) {
        disposable?.dispose()
        
        self.optographID.value = optographID
        
        optographBox = Models.optographs[optographID]!
        
        disposable = optographBox.producer
            .observeOnMain() // needed because of changes from PipelineService
            .skipRepeats()
            .startWithNext { [weak self] optograph in
                self?.isPrivate.value = optograph.isPrivate
                self?.isStitched.value = optograph.isStitched
                self?.uploadStatus.value = optograph.isPublished ? .Uploaded : .Offline
                self?.imageURL.value = TextureURL(optographID, side: .Left, size: 512, face: 0, x: 0, y: 0, d: 1)
            }
    }
    
    func upload() {
        if !optographBox.model.isOnServer {
            let optograph = optographBox.model
            
            let postParameters = [
                "id": optograph.ID,
                "stitcher_version": StitcherVersion,
                "created_at": optograph.createdAt.toRFC3339String(),
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
            
            ApiService<OptographApiModel>.post("optographs", parameters: postParameters)
                .on(next: { [weak self] optograph in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.shareAlias = optograph.shareAlias
                    }
                })
                .flatMap(.Latest) { _ in ApiService<EmptyResponse>.put("optographs/\(optograph.ID)", parameters: putParameters) }
                .on(next: { [weak self] optograph in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isOnServer = true
                    }
                })
                .start()
            
            
        } else {
            optographBox.insertOrUpdate { box in
                box.model.shouldBePublished = true
            }
            
            PipelineService.checkUploading()
            
            uploadStatus.value = .Uploading
        }
        
    }
    
}