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
        
        disposable = optographBox.producer.startWithNext { [weak self] optograph in
            self?.isPrivate.value = optograph.isPrivate
            self?.isStitched.value = optograph.isStitched
            self?.uploadStatus.value = optograph.isPublished ? .Uploaded : .Offline
            self?.imageURL.value = TextureURL(optographID, side: .Left, size: 512, face: 0, x: 0, y: 0, d: 1)
        }
    }
    
    func upload() {
        optographBox.insertOrUpdate { box in
            box.model.shouldBePublished = true
        }
        
        PipelineService.checkUploading()
        
        uploadStatus.value = .Uploading
    }
    
}