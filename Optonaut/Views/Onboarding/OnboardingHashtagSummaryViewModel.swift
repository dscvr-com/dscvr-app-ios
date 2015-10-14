//
//  OnboardingHashtagSummaryViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class OnboardingHashtagSummaryViewModel {
    
    let loading = MutableProperty<Bool>(false)
    
    func updateData() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.put("persons/me", parameters: ["onboarding_version": OnboardingVersion])
            .on(
                started: {
                    self.loading.value = true
                },
                completed: {
                    self.loading.value = false
                    SessionService.sessionData?.onboardingVersion = OnboardingVersion
                }
            )
    }
    
}