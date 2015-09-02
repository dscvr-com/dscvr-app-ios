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
    init?(_ map: Map) {}
    mutating func mapping(map: Map) {}
}

struct ApiError: ErrorType {
    
    static let Nil = ApiError(endpoint: "", timeout: false, status: nil, message: "", error: nil)
    
    let endpoint: String
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
        case .Staging: return "beta.api-0-2.optonaut.co"
        case .Production: return "api-0-2.optonaut.co"
        }
    }
    
    private static var port: Int {
        switch Env {
        case .Development: return 80
        case .Staging: return 80
        case .Production: return 80
        }
    }
    
    static func checkVersion() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.get("info")
    }
    
    static func get(endpoint: String, queries: [String: String]? = nil) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .GET, queries: queries, parameters: nil)
    }
    
    static func post(endpoint: String, queries: [String: String]? = nil, parameters: [String: AnyObject]? = nil) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .POST, queries: queries, parameters: parameters)
    }
    
    static func put(endpoint: String, queries: [String: String]? = nil, parameters: [String: AnyObject]? = nil) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .PUT, queries: queries, parameters: parameters)
    }
    
    static func delete(endpoint: String, queries: [String: String]? = nil) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .DELETE, queries: queries, parameters: nil)
    }
    
    static func upload(endpoint: String, uploadData: [String: String]) -> SignalProducer<Float, NSError> {
        return SignalProducer<Float, NSError> { sink, disposable in
            let mutableURLRequest = buildURLRequest(endpoint, method: .POST, queries: nil)
            let multipartFormData = { (data: MultipartFormData) in
                for (path, name) in uploadData {
                    data.appendBodyPart(fileURL: NSURL(fileURLWithPath: path), name: name)
                }
            }
            
            var request: Alamofire.Request?
    
            Alamofire.upload(mutableURLRequest, multipartFormData: multipartFormData) { result in
                switch result {
                case .Success(let upload, _, _):
                    request = upload
                        .validate(statusCode: 200..<300)
                        .response { _, _, _, error in
                            if let error = error {
                                sendError(sink, error)
                            } else {
                                sendCompleted(sink)
                            }
                    }
                case .Failure(let error):
                    sendError(sink, error)
                }
            }
            
            disposable.addDisposable {
                request?.cancel()
            }
        }
    }
    
    private static func buildURLRequest(endpoint: String, method: Alamofire.Method, queries: [String: String]?) -> NSMutableURLRequest {
        var queryStr = ""
        if let queries = queries {
            for (index, (key, value)) in queries.enumerate() {
                queryStr += index == 0 ? "?" : "&"
                queryStr += "\(key)=\(value.escaped)"
            }
        }
        
        let URL = NSURL(string: "http://\(host):\(port)/\(endpoint)\(queryStr)")!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let token = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.PersonToken.rawValue) as? String {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return mutableURLRequest
    }
    
    private static func request(endpoint: String, method: Alamofire.Method, queries: [String: String]? = nil, parameters: [String: AnyObject]?) -> SignalProducer<T, ApiError> {
        return SignalProducer { sink, disposable in
            let mutableURLRequest = buildURLRequest(endpoint, method: method, queries: queries)
            
            if let parameters = parameters {
                let json = try! NSJSONSerialization.dataWithJSONObject(parameters, options: [])
                mutableURLRequest.HTTPBody = Optional(json)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            let request = Alamofire.request(mutableURLRequest)
                .validate()
                .response { (_, response, data, error) in
                    if let error = error {
                        if response?.statusCode == 401 && endpoint.rangeOfString("login") == nil {
                            NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.Logout.rawValue, object: nil)
                        }
                        
                        do {
                            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                            print(json)
                        } catch {}
                        
                        let apiError = ApiError(endpoint: endpoint, timeout: error.code == NSURLErrorTimedOut, status: response?.statusCode, message: error.description, error: error)
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
                                    let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "JSON couldn't be mapped to type T", error: nil)
                                    sendError(sink, apiError)
                                }
                            } catch let error {
                                let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "JSON invalid", error: error as NSError)
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