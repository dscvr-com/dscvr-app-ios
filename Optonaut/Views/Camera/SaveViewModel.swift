//
//  SaveViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/12/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Alamofire
import ObjectMapper
import Async
import SwiftyUserDefaults

class SaveViewModel {
    
    let previewImageUrl = MutableProperty<String>("http://test")
    let text = MutableProperty<String>("")
    let isPrivate = MutableProperty<Bool>(false)
    let isReady = MutableProperty<Bool>(false)
    
    var optograph = Optograph.newInstance()
    
    init(placeholderSignal: Signal<UIImage, NoError>) {
        
        isPrivate.producer.startWithNext { self.optograph.isPrivate = $0 }
        
        text.producer.startWithNext { self.optograph.text = $0 }
        
        isReady <~ ApiService<Optograph>.post("optographs", parameters: ["stitcher_version": StitcherVersion])
            .map { (var optograph) in
                optograph.placeholderTextureAssetID = uuid()
                return optograph
            }
            .on(next: { [weak self] optograph in
                self?.optograph = optograph
            })
            .zipWith(placeholderSignal.mapError({ _ in ApiError.Nil }))
            .flatMap(.Latest) { (optograph, image) in
                return ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset", multipartFormData: { form in
                    form.appendBodyPart(data: "placeholder".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
                    form.appendBodyPart(data: optograph.placeholderTextureAssetID.dataUsingEncoding(NSUTF8StringEncoding)!, name: "asset_id")
                    form.appendBodyPart(data: UIImageJPEGRepresentation(image, 0.7)!, name: "asset", fileName: "placeholder.jpg", mimeType: "image/jpeg")
                })
            }
            .on(failed: { error in
                print(error)
            })
            .transformToBool()
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