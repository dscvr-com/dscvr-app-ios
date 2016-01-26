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
    
    private var disposable: Disposable?
    
    func bind(optographID: UUID) {
        disposable?.dispose()
        
        let optographBox = Models.optographs[optographID]!
        
        disposable = optographBox.producer.startWithNext { [weak self] optograph in
            self?.isPrivate.value = optograph.isPrivate
            self?.isStitched.value = optograph.isStitched
            self?.uploadStatus.value = optograph.isPublished ? .Uploaded : .Offline
        }
    }
    
}