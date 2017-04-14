//
//  Reachability.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/19/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SystemConfiguration

open class Reachability {
    
    class func connectedToNetwork() -> Bool {
        return false
        /* TODO
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, $0)
        }) else {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
         */
    }
    
}
