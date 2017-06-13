//
//  SaveViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import Alamofire
import ObjectMapper
import Async
import SwiftyUserDefaults

class SaveViewModel {
    
    let isReadyForSubmit = MutableProperty<Bool>(false)
    let isInitialized = MutableProperty<Bool>(false)
    let stitcherFinished = MutableProperty<Bool>(false)
    let isReadyForStitching = MutableProperty<Bool>(false)
    
    var optograph: Optograph
    
    
    fileprivate let placeholder = MutableProperty<UIImage?>(nil)
    
    init(placeholderSignal: Signal<UIImage, NoError>, readyNotification: NotificationSignal<Void>) {
        
        placeholder <~ placeholderSignal.map { image -> UIImage? in return image }
        
        optograph = Optograph.newInstance()
        
        optograph.isStitched = false
        
        isInitialized.producer.startWithValues{ print("isInitialized \($0)")}
        stitcherFinished.producer.startWithValues{ print("stitcherFinished \($0)")}
        
        isReadyForStitching <~ stitcherFinished.producer
            .combineLatest(with: isInitialized.producer).map(and)
            .filter(isTrue)
            .take(first: 1)
        
        isReadyForSubmit <~ isInitialized.producer
            .combineLatest(with: stitcherFinished.producer).map(and)
        
        readyNotification.signal.observe { _ in
            self.isInitialized.value = true
        }
        
    }
    
    func deleteOpto() {
        // TODO: Delete, if exists
    }
    
     
    
    func submit(_ shouldBePublished: Bool, directionPhi: Double, directionTheta: Double) -> SignalProducer<Void, NoError> {
        // TODO: Save.
        DataBase.sharedInstance.addOptograph(optograph: optograph)
        return SignalProducer(value: ())
    }
}

