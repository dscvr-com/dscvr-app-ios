//
//  ActivitiesService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 02/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class ActivitiesService {
    
    static let unreadCount: MutableProperty<Int> = {
        return MutableProperty(UIApplication.sharedApplication().applicationIconBadgeNumber)
    }()
    
}