//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa

class OptographTableViewCellModel {
    
    let previewImageUrl: ConstantProperty<String>
    
    let optograph: Optograph
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
        previewImageUrl = ConstantProperty("\(S3URL)/original/\(optograph.previewAssetId).jpg")
    }
    
}
