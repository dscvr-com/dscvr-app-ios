//
//  OnboardingHashtagViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/19/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

struct Hashtag {
    let name: String
    let previewAssetId: UUID
    var isSelected = false
}

class OnboardingHashtagsViewModel {
    
    let results = MutableProperty<[Hashtag]>([])
    let nextHidden = MutableProperty<Bool>(false)
    
    init() {
        results.value = [
            Hashtag(name: "mountains", previewAssetId: "0cbc3cf1-86d9-4041-bffe-5cd9e263648b", isSelected: false),
            Hashtag(name: "architecture", previewAssetId: "0d3c6e5b-03a2-462d-add7-985d5fc9aa63", isSelected: true),
            Hashtag(name: "landscape", previewAssetId: "0cbc3cf1-86d9-4041-bffe-5cd9e263648b", isSelected: false),
            Hashtag(name: "nature", previewAssetId: "0d3c6e5b-03a2-462d-add7-985d5fc9aa63", isSelected: false),
            Hashtag(name: "city", previewAssetId: "122137339/m%3D2048/df4386b18e06fa9c75a5e374ab2bd2f9", isSelected: false),
            Hashtag(name: "sunset", previewAssetId: "0d3c6e5b-03a2-462d-add7-985d5fc9aa63", isSelected: false),
            Hashtag(name: "water", previewAssetId: "0d3c6e5b-03a2-462d-add7-985d5fc9aa63", isSelected: false),
        ]
        
        nextHidden <~ results.producer
            .map { $0.reduce(0) { $0 + ($1.isSelected ? 1 : 0) } }
            .map { $0 < 3 }
    }
    
}