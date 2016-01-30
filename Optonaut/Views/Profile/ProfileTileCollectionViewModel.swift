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
    let imageURL = MutableProperty<String>("")
    
    private var disposable: Disposable?
    
    func bind(optographID: UUID) {
        disposable?.dispose()
        
        self.optographID.value = optographID
        
        let optographBox = Models.optographs[optographID]!
        
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
                self?.imageURL.value = TextureURL(optographID, side: .Left, size: 512, face: 0, x: 0, y: 0, d: 1)
            }
    }
    
}