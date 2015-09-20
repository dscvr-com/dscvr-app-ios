//
//  OnboardingHashtagViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/19/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class OnboardingHashtagViewModel {
    
    let isSelected = MutableProperty<Bool>(false)
    let name = MutableProperty<String>("")
    let imageUrl = MutableProperty<String>("")
    
    func setHashtag(hashtag: Hashtag) {
        imageUrl.value = "\(S3URL)/400x400/\(hashtag.previewAssetId).jpg"
        name.value = hashtag.name
        isSelected.value = hashtag.isSelected
    }
    
}