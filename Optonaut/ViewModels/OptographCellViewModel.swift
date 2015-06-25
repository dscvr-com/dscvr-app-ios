//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa

//class OptographCellViewModel {
//    
//    let numberOfLikes = MutableProperty<Int>(0)
//    let liked = MutableProperty<Bool>(false)
//    let timeSinceCreated = MutableProperty<String>("")
//    
//    init(optograph: Optograph) {
//        numberOfLikes.put(opto
//        
//        loginEmail.producer
//            |> start(next: { str in
//                self.loginEmailValid.put(isValidEmail(str))
//            })
//        
//        inviteEmail.producer
//            |> start(next: { str in
//                self.inviteEmailValid.put(isValidEmail(str))
//            })
//        
//        loginPassword.producer
//            |> start(next: { str in
//                self.loginPasswordValid.put(count(str) > 4)
//            })
//        
//        combineLatest([loginEmailValid.producer, loginPasswordValid.producer])
//            |> start(next: { bools in
//                self.loginAllowed.put(bools.reduce(true) { $0 && $1 })
//            })
//    }
//    
//}
