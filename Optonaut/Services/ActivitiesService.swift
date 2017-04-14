//
//  ActivitiesService.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 02/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveSwift

class ActivitiesService {
    
    static let unreadCount: MutableProperty<Int> = {
        return MutableProperty(UIApplication.shared.applicationIconBadgeNumber)
    }()
    
}
