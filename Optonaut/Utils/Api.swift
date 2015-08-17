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
import ObjectMapper

let host = "beta.api.optonaut.com"
//let host = "0e69aa37.ngrok.io"
let port = 80
//let host = "192.168.2.102"
//let host = "localhost"
//let port = 3000

struct EmptyResponse: Mappable {
    static func newInstance() -> Mappable {
        return EmptyResponse()
    }
    
    mutating func mapping(map: Map) {}
}

class Api<T: Mappable> {
    
    static func get(endpoint: String) -> SignalProducer<T, NSError> {
        return request(endpoint, method: .GET, parameters: nil)
    }
    
    static func post(endpoint: String, parameters: [String: AnyObject]?) -> SignalProducer<T, NSError> {
        return request(endpoint, method: .POST, parameters: parameters)
    }
    
    static func put(endpoint: String, parameters: [String: AnyObject]?) -> SignalProducer<T, NSError> {
        return request(endpoint, method: .PUT, parameters: parameters)
    }
    
    static func delete(endpoint: String) -> SignalProducer<T, NSError> {
        return request(endpoint, method: .DELETE, parameters: nil)
    }
    
    private static func request(endpoint: String, method: Alamofire.Method, parameters: [String: AnyObject]?) -> SignalProducer<T, NSError> {
        return SignalProducer { sink, disposable in
            let URL = NSURL(string: "http://\(host):\(port)/\(endpoint)")!
            let mutableURLRequest = NSMutableURLRequest(URL: URL)
            mutableURLRequest.HTTPMethod = method.rawValue
            
            if let parameters = parameters {
                let json = try! NSJSONSerialization.dataWithJSONObject(parameters, options: [])
                mutableURLRequest.HTTPBody = Optional(json)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            if let token = NSUserDefaults.standardUserDefaults().objectForKey(PersonDefaultsKeys.PersonToken.rawValue) as? String {
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
                                if let object = Mapper<T>().map(json) {
                                    sendNext(sink, object)
                                } else if let array = Mapper<T>().mapArray(json) {
                                    for object in array {
                                        sendNext(sink, object)
                                    }
                                } else {
                                    let error = NSError(domain: "JSON couldn't be mapped to type T", code: 0, userInfo: nil)
                                    print(error)
                                    sendError(sink, error)
                                }
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