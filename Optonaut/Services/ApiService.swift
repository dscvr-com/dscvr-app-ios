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
import SwiftyUserDefaults

struct EmptyResponse: Mappable {
    init() {}
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
        case .Staging: return "api-staging.optonaut.co"
        case .Production: return "api-v7-production.optonaut.co"
        }
    }
    
    static func checkVersion() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.get("public/info")
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
                                sink.sendError(error)
                            } else {
                                sink.sendCompleted()
                            }
                    }
                case .Failure(let error):
                    sink.sendError(error as NSError)
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
        
        let URL = NSURL(string: "https://\(host)/\(endpoint)\(queryStr)")!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let token = Defaults[.SessionToken] {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return mutableURLRequest
    }
    
    private static func request(endpoint: String, method: Alamofire.Method, queries: [String: String]? = nil, parameters: [String: AnyObject]?) -> SignalProducer<T, ApiError> {
        return SignalProducer { sink, disposable in
            if !Reachability.connectedToNetwork() {
                sink.sendError(ApiError(endpoint: endpoint, timeout: false, status: nil, message: "Offline", error: nil))
                return
            }
            
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
                            SessionService.logout()
                        }
                        
                        do {
                            let _ = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        } catch {}
                        
                        let apiError = ApiError(endpoint: endpoint, timeout: error.code == NSURLErrorTimedOut, status: response?.statusCode ?? -1, message: error.description, error: error)
                        sink.sendError(apiError)
                    } else {
                        if let data = data where data.length > 0 {
                            if let jsonStr = String(data: data, encoding: NSUTF8StringEncoding) where jsonStr != "[]" {
                                do {
                                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                                    if let object = Mapper<T>().map(json) {
                                        sink.sendNext(object)
                                    } else if let array = Mapper<T>().mapArray(json) {
                                        for object in array {
                                            sink.sendNext(object)
                                        }
                                    } else {
                                        let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "JSON couldn't be mapped to type T", error: nil)
                                        sink.sendError(apiError)
                                    }
                                } catch let error {
                                    let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "JSON invalid", error: error as NSError)
                                    sink.sendError(apiError)
                                }
                            }
                        } else {
                            sink.sendNext(Mapper<T>().map([:])!)
                        }
                        sink.sendCompleted()
                    }
                }
            
            disposable.addDisposable {
                request.cancel()
            }
        }
            .on(error: { error in
                if error.suspicious {
//                    NotificationService.push("Uh oh. Something went wrong. We're on it!", level: .Error)
                    print(error)
                    Answers.logCustomEventWithName("Error", customAttributes: ["type": "api", "error": error.message])
                }
            })
    }
}