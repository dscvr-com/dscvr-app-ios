//
//  OverlayViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 30/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class LoginOverlayViewModel {
    
    let facebookPending = MutableProperty<Bool>(false)
    
    func facebookSignin(userID: String, token: String) -> SignalProducer<Void, ApiError> {
        return SessionService.facebookSignin(userID, token: token)
            .on(
                failed: { [weak self] _ in
                    self?.facebookPending.value = false
                },
                completed: { [weak self] in
                    self?.facebookPending.value = false
                }
            )
    }
    
}