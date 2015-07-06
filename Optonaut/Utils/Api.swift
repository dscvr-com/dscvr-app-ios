//
//  Api.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/23/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ReactiveCocoa

class Api {
//    static let host = "beta.api.optonaut.com"
//    static let port = 80
    static let host = "192.168.2.105"
    static let port = 3000
    
    static func get(endpoint: String, authorized: Bool) -> SignalProducer<JSON, NSError> {
        return request(endpoint, method: "GET", authorized: authorized, parameters: nil)
    }
    
    static func post(endpoint: String, authorized: Bool, parameters: [String: AnyObject]?) -> SignalProducer<JSON, NSError> {
        return request(endpoint, method: "POST", authorized: authorized, parameters: parameters)
    }
    
    static func delete(endpoint: String, authorized: Bool) -> SignalProducer<JSON, NSError> {
        return request(endpoint, method: "DELETE", authorized: authorized, parameters: nil)
    }
    
    private static func request(endpoint: String, method: String, authorized: Bool, parameters: [String: AnyObject]?) -> SignalProducer<JSON, NSError> {
        return SignalProducer { sink, disposable in
            let URL = NSURL(string: "http://\(self.host):\(self.port)/\(endpoint)")!
            let mutableURLRequest = NSMutableURLRequest(URL: URL)
            mutableURLRequest.HTTPMethod = method
            
            if parameters != nil {
                var JSONSerializationError: NSError? = nil
                mutableURLRequest.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters!, options: nil, error: &JSONSerializationError)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if JSONSerializationError != nil {
                    sendError(sink, JSONSerializationError!)
                }
            }
            
            if authorized {
                let token = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.UserToken.rawValue) as! String
                mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let request = Alamofire.request(mutableURLRequest)
                .validate()
                .responseJSON { (_, response, data, error) in
                    if let error = error {
                        // TODO remove login hack
                        if response?.statusCode == 401 && endpoint.rangeOfString("login") == nil {
                            NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.Logout.rawValue, object: nil)
                        }
                        println(error)
                        sendError(sink, error)
                    } else {
                        if data != nil {
                            sendNext(sink, JSON(data!))
                        }
                        sendCompleted(sink)
                    }
            }
            
            disposable.addDisposable {}
        }
        
    }
}