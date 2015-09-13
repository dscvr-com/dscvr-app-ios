//
//  SessionService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/3/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper
import ReactiveCocoa
import Crashlytics

enum LoginIdentifier {
    case UserName(String)
    case Email(String)
}

struct SessionData {
    let id: UUID
    var token: String {
        willSet {
            NSUserDefaults.standardUserDefaults().setObject(token, forKey: "session_person_token")
        }
    }
    var password: String {
        willSet {
            NSUserDefaults.standardUserDefaults().setObject(password, forKey: "session_person_password")
        }
    }
    var debuggingEnabled: Bool {
        willSet {
            NSUserDefaults.standardUserDefaults().setBool(debuggingEnabled, forKey: "session_person_debugging_enabled")
        }
    }
}

class SessionService {

    static var sessionData: SessionData? {
        willSet {
            if let newValue = newValue {
                NSUserDefaults.standardUserDefaults().setObject(newValue.id, forKey: "session_person_id")
                NSUserDefaults.standardUserDefaults().setObject(newValue.token, forKey: "session_person_token")
                NSUserDefaults.standardUserDefaults().setObject(newValue.password, forKey: "session_person_password")
                NSUserDefaults.standardUserDefaults().setBool(newValue.debuggingEnabled, forKey: "session_person_debugging_enabled")
            } else {
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_id")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_token")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_password")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_debugging_enabled")
            }
        }
    }
    
    static var isLoggedIn: Bool {
        return sessionData != nil
    }
    
    private static var logoutCallbacks: [(performAlways: Bool, fn: () -> ())] = []
    
    static func prepare() {
        
        let id = NSUserDefaults.standardUserDefaults().objectForKey("session_person_id") as? UUID
        let token = NSUserDefaults.standardUserDefaults().objectForKey("session_person_token") as? String
        let password = NSUserDefaults.standardUserDefaults().objectForKey("session_person_password") as? String
        let debuggingEnabled = NSUserDefaults.standardUserDefaults().boolForKey("session_person_debugging_enabled")
        if let id = id, token = token, password = password {
            sessionData = SessionData(id: id, token: token, password: password, debuggingEnabled: debuggingEnabled)
        } else {
            return
        }
        
        let query = PersonTable.filter(PersonTable[PersonSchema.id] ==- SessionService.sessionData!.id)
        if let person = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL) {
            Crashlytics.sharedInstance().setUserIdentifier(person.id)
            Crashlytics.sharedInstance().setUserEmail(person.email)
            Crashlytics.sharedInstance().setUserName(person.userName)
        }
    }
    
    static func login(identifier: LoginIdentifier, password: String) -> SignalProducer<Void, ApiError> {
        
        var parameters: [String: AnyObject] = ["email": "", "user_name": "", "password": password]
        switch identifier {
        case .Email(let email): parameters["email"] = email
        case .UserName(let userName): parameters["user_name"] = userName
        }
        
        return ApiService<LoginMappable>.post("persons/login", parameters: parameters)
            .on(next: { loginData in
                sessionData = SessionData(id: loginData.id, token: loginData.token, password: password, debuggingEnabled: false)
            })
            .flatMap(.Latest) { _ in SignalProducer.empty }
    }
    
    static func logout() {
        for (_, fn) in logoutCallbacks {
            fn()
        }
        
        logoutCallbacks = logoutCallbacks.filter { (performAlways, _) in performAlways }
    }
    
    static func onLogout(performAlways performAlways: Bool = false, fn: () -> ()) {
        logoutCallbacks.append((performAlways, fn))
    }
    
}

struct LoginMappable: Mappable {
    var token: String = ""
    var id: UUID = ""
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        token   <- map["token"]
        id      <- map["id"]
    }
}
