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
//    static let host = "b7535ff5.ngrok.io"
//    static let port = 80
//    static let host = "192.168.43.232"
    static let host = "localhost"
    static let port = 3000
    
    static func get(endpoint: String, authorized: Bool) -> SignalProducer<JSONResponse, NSError> {
        return request(endpoint, method: .GET, authorized: authorized, parameters: nil)
    }
    
    static func post(endpoint: String, authorized: Bool, parameters: [String: AnyObject]?) -> SignalProducer<JSONResponse, NSError> {
        return request(endpoint, method: .POST, authorized: authorized, parameters: parameters)
    }
    
    static func put(endpoint: String, authorized: Bool, parameters: [String: AnyObject]?) -> SignalProducer<JSONResponse, NSError> {
        return request(endpoint, method: .PUT, authorized: authorized, parameters: parameters)
    }
    
    static func delete(endpoint: String, authorized: Bool) -> SignalProducer<JSONResponse, NSError> {
        return request(endpoint, method: .DELETE, authorized: authorized, parameters: nil)
    }
    
    private static func request(endpoint: String, method: Alamofire.Method, authorized: Bool, parameters: [String: AnyObject]?) -> SignalProducer<JSONResponse, NSError> {
        return SignalProducer { sink, disposable in
            let URL = NSURL(string: "http://\(self.host):\(self.port)/\(endpoint)")!
            let mutableURLRequest = NSMutableURLRequest(URL: URL)
            mutableURLRequest.HTTPMethod = method.rawValue
            
            if let parameters = parameters {
                let json = try! NSJSONSerialization.dataWithJSONObject(parameters, options: [])
                mutableURLRequest.HTTPBody = Optional(json)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            if authorized {
                let token = NSUserDefaults.standardUserDefaults().objectForKey(PersonDefaultsKeys.PersonToken.rawValue) as! String
                mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let request = Alamofire.request(mutableURLRequest)
                .validate()
                .response { (_, response, data, error) in
                    if let error = error {
                        // TODO remove login hack
                        if response?.statusCode == 401 && endpoint.rangeOfString("login") == nil {
                            NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.Logout.rawValue, object: nil)
                        }
                        if let data = data {
                            print(data)
                        }
                        print(error)
                        sendError(sink, error)
                    } else {
                        if let data = data where data.length > 0 {
                            do {
                                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                                sendNext(sink, json)
                            } catch let error {
                                print(error)
                                sendError(sink, error as NSError)
                            }
                        }
                        sendCompleted(sink)
                    }
                }
            
            disposable.addDisposable {
                request.cancel()
            }
        }
        
    }
}