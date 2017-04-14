//
//  ApiService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/23/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import Alamofire
import ReactiveSwift
import ObjectMapper
import Crashlytics
import SwiftyUserDefaults

struct EmptyResponse: Mappable {
    init() {}
    init?(map: Map) {}
    mutating func mapping(map: Map) {}
}

struct ApiError: Error {
    
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
    // TODO: No Api for us
    /*
    fileprivate static var host: String {
        switch Env {
        case .development: return "optonaut.ngrok.io"
        case .staging: return "api-staging.dscvr.com"
        case .localStaging: return "192.168.1.69:3000"
        case .production: return "api-production-v9.dscvr.com"
        }
    }
    
    static func checkVersion() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.get("public/info")
    }
    
    static func get(_ endpoint: String, queries: [String: String]? = nil) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .GET, queries: queries, parameters: nil)
    }
    
    static func post(_ endpoint: String, queries: [String: String]? = nil, parameters: [String: AnyObject]? = nil) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .POST, queries: queries, parameters: parameters)
    }
    static func postForGate(_ endpoint: String, queries: [String: String]? = nil, parameters: [String: AnyObject]? = nil) -> SignalProducer<T, ApiError> {
        return requestForGate(endpoint, method: .POST, queries: queries, parameters: parameters)
    }
    static func getForGate(_ endpoint: String, queries: [String: String]? = nil, parameters: [String: AnyObject]? = nil) -> SignalProducer<T, ApiError> {
        return requestForGate(endpoint, method: .GET, queries: queries, parameters: parameters)
    }
    static func putForGate(_ endpoint: String, queries: [String: String]? = nil, parameters: [String: AnyObject]? = nil) -> SignalProducer<T, ApiError> {
        return requestForGate(endpoint, method: .PUT, queries: queries, parameters: parameters)
    }
    
    static func put(_ endpoint: String, queries: [String: String]? = nil, parameters: [String: AnyObject]? = nil) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .PUT, queries: queries, parameters: parameters)
    }
    
    static func delete(_ endpoint: String, queries: [String: String]? = nil) -> SignalProducer<T, ApiError> {
        return request(endpoint, method: .DELETE, queries: queries, parameters: nil)
    }
    static func deleteNewEndpoint(_ endpoint: String, queries: [String: String]? = nil) -> SignalProducer<T, ApiError> {
        return requestForGate(endpoint, method: .DELETE, queries: queries, parameters: nil)
    }
    
    static func upload(_ endpoint: String, uploadData: [String: String]) -> SignalProducer<Float, NSError> {
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
                                sink.sendFailed(error)
                            } else {
                                sink.sendCompleted()
                            }
                    }
                case .Failure(let error):
                    sink.sendFailed(error as NSError)
                }
            }
            
            disposable.addDisposable {
                request?.cancel()
            }
        }
    }
    
    static func uploadForGate(_ endpoint: String, multipartFormData: (MultipartFormData) -> Void) -> SignalProducer<Void, ApiError> {
        return SignalProducer { sink, disposable in
            let mutableURLRequest = buildURLRequestForGate(endpoint, method: .POST, queries: nil)
            
            var request: Alamofire.Request?
            Alamofire.upload(mutableURLRequest, multipartFormData: multipartFormData) { result in
                
                switch result {
                case .Success(let upload, _, _):
                    request = upload
                        .validate(statusCode: 200..<300)
                        .response { _, _, _, error in
                            if let error = error {
                                let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "Upload failed", error: error)
                                sink.sendFailed(apiError)
                            } else {
                                sink.sendCompleted()
                            }
                    }
                case .Failure(let error):
                    let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "Upload failed", error: error as NSError)
                    print("error: \(error)")
                    sink.sendFailed(apiError)
                }
            }
            
            disposable.addDisposable {
                request?.cancel()
            }
            }
            .on(failed: { error in
                if error.suspicious {
                    //                    NotificationService.push("Uh oh. Something went wrong. We're on it!", level: .Error)
                    Answers.logCustomEventWithName("Error", customAttributes: ["type": "api", "error": error.message])
                }
            })
    }
    
    static func upload(_ endpoint: String, multipartFormData: (MultipartFormData) -> Void) -> SignalProducer<Void, ApiError> {
        return SignalProducer { sink, disposable in
            let mutableURLRequest = buildURLRequest(endpoint, method: .POST, queries: nil)
            
            var request: Alamofire.Request?
            Alamofire.upload(mutableURLRequest, multipartFormData: multipartFormData) { result in
                switch result {
                case .Success(let upload, _, _):
                    request = upload
                        .validate(statusCode: 200..<300)
                        .response { _, _, _, error in
                            if let error = error {
                                let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "Upload failed", error: error)
                                sink.sendFailed(apiError)
                            } else {
                                sink.sendCompleted()
                            }
                    }
                case .Failure(let error):
                    let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "Upload failed", error: error as NSError)
                    sink.sendFailed(apiError)
                }
            }
            
            disposable.addDisposable {
                request?.cancel()
            }
        }
            .on(failed: { error in
                if error.suspicious {
                    //NotificationService.push("Uh oh. Something went wrong. We're on it!", level: .Error)
                    Answers.logCustomEventWithName("Error", customAttributes: ["type": "api", "error": error.message])
                }
            })
    }
    
    fileprivate static func buildURLRequest(_ endpoint: String, method: Alamofire.Method, queries: [String: String]?) -> NSMutableURLRequest {
        var queryStr = ""
        if let queries = queries {
            for (index, (key, value)) in queries.enumerated() {
                queryStr += index == 0 ? "?" : "&"
                queryStr += "\(key)=\(value.escaped)"
            }
        }
        
        let URL = Foundation.URL(string: "https://\(host)/\(endpoint)\(queryStr)")!
        let mutableURLRequest = NSMutableURLRequest(url: URL)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let token = Defaults[.SessionToken] {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print ("Bearer ",token)
        }
        
        return mutableURLRequest
    }
    fileprivate static func buildURLRequestForGate(_ endpoint: String, method: Alamofire.Method, queries: [String: String]?) -> NSMutableURLRequest {
        var queryStr = ""
        if let queries = queries {
            for (index, (key, value)) in queries.enumerated() {
                queryStr += index == 0 ? "?" : "&"
                queryStr += "\(key)=\(value.escaped)"
            }
        }
        let URL = Foundation.URL(string: "https://mapi.dscvr.com/\(endpoint)\(queryStr)")!
        
        let mutableURLRequest = NSMutableURLRequest(url: URL)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let token = Defaults[.SessionToken] {
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return mutableURLRequest
    }
    
    fileprivate static func request(_ endpoint: String, method: Alamofire.Method, queries: [String: String]? = nil, parameters: [String: AnyObject]?) -> SignalProducer<T, ApiError> {
        return SignalProducer { sink, disposable in
            if !Reachability.connectedToNetwork() {
                sink.sendFailed(ApiError(endpoint: endpoint, timeout: false, status: nil, message: "Offline", error: nil))
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
                            let data = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        } catch {}
                        
                        let apiError = ApiError(endpoint: endpoint, timeout: error.code == NSURLErrorTimedOut, status: response?.statusCode ?? -1, message: error.description, error: error)
                        sink.sendFailed(apiError)
                    } else {
                        if let data = data, data.length > 0 {
                            if let jsonStr = String(data: data, encoding: NSUTF8StringEncoding), jsonStr != "[]" {
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
                                        sink.sendFailed(apiError)
                                    }
                                } catch let error {
                                    let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "JSON invalid", error: error as NSError)
                                    sink.sendFailed(apiError)
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
            .on(failed: { error in
                if error.suspicious {
                    //NotificationService.push("Uh oh. Something went wrong. We're on it!", level: .Error)
                    Answers.logCustomEventWithName("Error", customAttributes: ["type": "api", "error": error.message])
                }
            })
    }
    
    fileprivate static func requestForGate(_ endpoint: String, method: Alamofire.Method, queries: [String: String]? = nil, parameters: [String: AnyObject]?) -> SignalProducer<T, ApiError> {
        return SignalProducer { sink, disposable in
            if !Reachability.connectedToNetwork() {
                sink.sendFailed(ApiError(endpoint: endpoint, timeout: false, status: nil, message: "Offline", error: nil))
                return
            }
            
            let mutableURLRequest = buildURLRequestForGate(endpoint, method: method, queries: queries)
            
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
                        print("error",error)
                        
                        do {
                            let data = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        } catch {}
                        
                        let apiError = ApiError(endpoint: endpoint, timeout: error.code == NSURLErrorTimedOut, status: response?.statusCode ?? -1, message: error.description, error: error)
                        sink.sendFailed(apiError)
                    } else {
                        if let data = data, data.length > 0 {
                            if let jsonStr = String(data: data, encoding: NSUTF8StringEncoding), jsonStr != "[]" {
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
                                        sink.sendFailed(apiError)
                                    }
                                } catch let error {
                                    let apiError = ApiError(endpoint: endpoint, timeout: false, status: -1, message: "JSON invalid", error: error as NSError)
                                    sink.sendFailed(apiError)
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
            .on(failed: { error in
                if error.suspicious {
                    //                    NotificationService.push("Uh oh. Something went wrong. We're on it!", level: .Error)
                    Answers.logCustomEventWithName("Error", customAttributes: ["type": "api", "error": error.message])
                }
            })

    }*/ 
}
