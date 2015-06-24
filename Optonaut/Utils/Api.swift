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

class Api {
    let host = "192.168.2.102"
    let port = 3000
    
    func get(endpoint: String, authorized: Bool, success: JSON? -> Void, fail: NSError -> Void) {
        request(endpoint, method: "GET", authorized: authorized, parameters: nil, success: success, fail: fail)
    }
    
    func post(endpoint: String, authorized: Bool, parameters: [String: AnyObject]?, success: JSON? -> Void, fail: NSError -> Void) {
        request(endpoint, method: "POST", authorized: authorized, parameters: parameters, success: success, fail: fail)
    }
    
    func delete(endpoint: String, authorized: Bool, success: JSON? -> Void, fail: NSError -> Void) {
        request(endpoint, method: "DELETE", authorized: authorized, parameters: nil, success: success, fail: fail)
    }
    
    private func request(endpoint: String, method: String, authorized: Bool, parameters: [String: AnyObject]?, success: JSON? -> Void, fail: NSError -> Void) {
        let URL = NSURL(string: "http://\(host):\(port)/\(endpoint)")!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = method
        
        if parameters != nil {
            var JSONSerializationError: NSError? = nil
            mutableURLRequest.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters!, options: nil, error: &JSONSerializationError)
            mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if JSONSerializationError != nil {
                fail(JSONSerializationError!)
                return
            }
        }
        
        if authorized {
            let token = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.USER_TOKEN.rawValue) as! String
            mutableURLRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        Alamofire.request(mutableURLRequest)
            .validate()
            .responseJSON { (_, _, data, error) in
                if error != nil {
                    fail(error!)
                } else {
                    if data != nil {
                        success(JSON(data!))
                    } else {
                        success(nil)
                    }
                }
        }
    }
}