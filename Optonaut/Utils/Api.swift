//
//  Api.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/23/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import Alamofire
import ReactiveCocoa

typealias JSONResponse = AnyObject

class Api {
//    static let host = "beta.api.optonaut.com"
//    static let port = 80
    static let host = "192.168.1.41"
    static let port = 3000
    
    static func get(endpoint: String, authorized: Bool) -> SignalProducer<JSONResponse, NSError> {
        return request(endpoint, method: "GET", authorized: authorized, parameters: nil)
    }
    
    static func post(endpoint: String, authorized: Bool, parameters: [String: AnyObject]?) -> SignalProducer<JSONResponse, NSError> {
        return request(endpoint, method: "POST", authorized: authorized, parameters: parameters)
    }
    
    static func delete(endpoint: String, authorized: Bool) -> SignalProducer<JSONResponse, NSError> {
        return request(endpoint, method: "DELETE", authorized: authorized, parameters: nil)
    }
    
    private static func request(endpoint: String, method: String, authorized: Bool, parameters: [String: AnyObject]?) -> SignalProducer<JSONResponse, NSError> {
        return SignalProducer { sink, disposable in
            let URL = NSURL(string: "http://\(self.host):\(self.port)/\(endpoint)")!
            let mutableURLRequest = NSMutableURLRequest(URL: URL)
            mutableURLRequest.HTTPMethod = method
            
            if parameters != nil {
                let json = try! NSJSONSerialization.dataWithJSONObject(parameters!, options: [])
                mutableURLRequest.HTTPBody = Optional(json)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            if authorized {
                let token = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.UserToken.rawValue) as! String
                mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            Alamofire.request(mutableURLRequest)
                .validate()
                .responseJSON { (_, response, data, error) in
                    if let error = error {
                        // TODO remove login hack
                        if response?.statusCode == 401 && endpoint.rangeOfString("login") == nil {
                            NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.Logout.rawValue, object: nil)
                        }
                        print(error)
                        sendError(sink, error)
                    } else {
                        if let data = data {
                            sendNext(sink, data)
                        }
                        sendCompleted(sink)
                    }
            }
            
            disposable.addDisposable {}
        }
        
    }
}