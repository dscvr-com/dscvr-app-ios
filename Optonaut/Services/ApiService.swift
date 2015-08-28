//
//  ApiService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/23/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import Alamofire
import ReactiveCocoa
import ObjectMapper
import Crashlytics

struct EmptyResponse: Mappable {
    static func newInstance() -> Mappable {
        return EmptyResponse()
    }
    
    mutating func mapping(map: Map) {}
}

struct ApiError: ErrorType {
    
    static let Nil = ApiError(timeout: false, status: nil, message: "", error: nil)
    
    let timeout: Bool
    let status: Int?
    let message: String
    let error: NSError?
    
    var suspicious: Bool {
        return status == 500 || status == -1
    }
}

class ApiService<T: Mappable> {
    
    private static var host: String {
        switch Env {
        case .Development: return "optonaut.ngrok.io"
        case .Staging: return "beta.api.optonaut.co"
        case .Production: return "api.optonaut.co"
        }
    }
    
    private static var port: Int {
        switch Env {
        case .Development: return 80
        case .Staging: return 80
        case .Production: return 80
        }
    }
    
    static func get(endpoint: String) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .GET, parameters: nil)
    }
    
    static func post(endpoint: String, parameters: [String: AnyObject]?) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .POST, parameters: parameters)
    }
    
    static func put(endpoint: String, parameters: [String: AnyObject]?) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .PUT, parameters: parameters)
    }
    
    static func delete(endpoint: String) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .DELETE, parameters: nil)
    }
    
    private static func request(endpoint: String, method: Alamofire.Method, parameters: [String: AnyObject]?) -> SignalProducer<T, ApiError> {
        return SignalProducer { sink, disposable in
            let URL = NSURL(string: "http://\(host):\(port)/\(endpoint)")!
            let mutableURLRequest = NSMutableURLRequest(URL: URL)
            mutableURLRequest.HTTPMethod = method.rawValue
            
            if let parameters = parameters {
                let json = try! NSJSONSerialization.dataWithJSONObject(parameters, options: [])
                mutableURLRequest.HTTPBody = Optional(json)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            if let token = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.PersonToken.rawValue) as? String {
                mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let request = Alamofire.request(mutableURLRequest)
                .validate()
                .response { (_, response, data, error) in
                    if let error = error {
                        if response?.statusCode == 401 && endpoint.rangeOfString("login") == nil {
                            NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.Logout.rawValue, object: nil)
                        }
                        // TODO https://github.com/Alamofire/Alamofire/issues/233
                        
                        let apiError = ApiError(timeout: error.code == NSURLErrorTimedOut, status: response?.statusCode, message: error.description, error: error)
                        sendError(sink, apiError)
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
                                    let apiError = ApiError(timeout: false, status: -1, message: "JSON couldn't be mapped to type T", error: nil)
                                    sendError(sink, apiError)
                                }
                            } catch let error {
                                let apiError = ApiError(timeout: false, status: -1, message: "JSON invalid", error: error as NSError)
                                sendError(sink, apiError)
                            }
                        }
                        sendCompleted(sink)
                    }
                }
            
            disposable.addDisposable {
                request.cancel()
            }
        }
            .on(error: { error in
                print(error)
                if error.suspicious {
                    NotificationService.push("Uh oh. Something went wrong. We're on it!", level: .Error)
                    Answers.logCustomEventWithName("Error", customAttributes: ["type": "api", "error": error.message])
                }
            })
    }
}