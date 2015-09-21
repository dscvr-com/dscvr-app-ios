//
//  OnboardingHashtagViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/19/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class OnboardingHashtagsViewModel {
    
    let results = MutableProperty<[Hashtag]>([])
    let nextHidden = MutableProperty<Bool>(false)
    
    init() {
        ApiService<Hashtag>.get("hashtags/popular")
            .startWithNext { hashtag in
                self.results.value.append(hashtag)
            }
        
        nextHidden <~ results.producer
            .map { $0.reduce(0) { $0 + ($1.isFollowed ? 1 : 0) } }
            .map { $0 < 3 }
    }
    
}