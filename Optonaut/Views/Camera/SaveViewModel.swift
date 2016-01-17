//
//  SaveViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper
import Async
import SwiftyUserDefaults

class SaveViewModel {
    
    let previewImageUrl = MutableProperty<String>("http://test")
    let text = MutableProperty<String>("")
    let textEnabled = MutableProperty<Bool>(true)
    let hashtagString = MutableProperty<String>("")
    let hashtagStringValid = MutableProperty<Bool>(false)
    let hashtagStringStatus = MutableProperty<LineTextField.Status>(.Disabled)
    let cameraPreviewEnabled = MutableProperty<Bool>(false)
    let readyToSubmit = MutableProperty<Bool>(false)
    let recorderCleanedUp = MutableProperty<Bool>(false)
    let isPrivate = MutableProperty<Bool>(false)
    
    var optograph = Optograph.newInstance() 
    
    init() {
        isPrivate.producer.startWithNext { self.optograph.isPrivate = $0 }
        
        text.producer.startWithNext { self.optograph.text = $0 }
        
        let hashtagRegex = try! NSRegularExpression(pattern: "(#[\\\\u4e00-\\\\u9fa5a-zA-Z0-9]+)\\w*", options: [.CaseInsensitive])
        
        hashtagStringValid <~ hashtagString.producer
            .map { str in
                return !hashtagRegex.matchesInString(str, options: [], range: NSRange(location: 0, length: str.characters.count)).isEmpty
            }
        
        hashtagStringValid.producer
            .filter(identity)
            .startWithNext { _ in
                let str = self.hashtagString.value
                let nsStr = str as NSString
                self.optograph.hashtagString = hashtagRegex
                    .matchesInString(str, options: [], range: NSRange(location: 0, length: str.characters.count))
                    .map { nsStr.substringWithRange($0.range) }
                    .map { $0.lowercaseString }
                    .map { $0.substringFromIndex($0.startIndex.advancedBy(1)) }
                    .joinWithSeparator(",")
            }
        
        hashtagStringStatus <~ hashtagStringValid.producer
            .map { validHashtag in
                return validHashtag ? .Normal : .Indicated
            }
    
        readyToSubmit <~ hashtagStringValid.producer
            .combineLatestWith(recorderCleanedUp.producer).map(and)
    }
    
    func updatePreviewImage() {
        previewImageUrl.value = ImageURL(optograph.previewAssetID)
    }
    
    func post() {
        optograph.person.ID = Defaults[.SessionPersonID] ?? Person.guestID
        
        try! optograph.insertOrUpdate()
        try! optograph.location?.insertOrUpdate()
    }
}

private struct LocationMappable {
    var text = ""
    var country = ""
}


extension LocationMappable: Mappable {
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        text        <- map["text"]
        country     <- map["country"]
    }
}