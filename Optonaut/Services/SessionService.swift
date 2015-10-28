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
import Mixpanel

enum LoginIdentifier {
    case UserName(String)
    case Email(String)
}

struct SessionData {
    let ID: UUID
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
    var onboardingVersion: Int {
        willSet {
            NSUserDefaults.standardUserDefaults().setInteger(onboardingVersion, forKey: "session_person_onboarding_version")
        }
    }
    var vrGlasses: String {
        willSet {
            NSUserDefaults.standardUserDefaults().setObject(vrGlasses, forKey: "session_person_vr_glasses")
        }
    }
}

class SessionService {

    static var sessionData: SessionData? {
        willSet {
            if let newValue = newValue {
                NSUserDefaults.standardUserDefaults().setObject(newValue.ID, forKey: "session_person_id")
                NSUserDefaults.standardUserDefaults().setObject(newValue.token, forKey: "session_person_token")
                NSUserDefaults.standardUserDefaults().setObject(newValue.password, forKey: "session_person_password")
                NSUserDefaults.standardUserDefaults().setBool(newValue.debuggingEnabled, forKey: "session_person_debugging_enabled")
                NSUserDefaults.standardUserDefaults().setInteger(newValue.onboardingVersion, forKey: "session_person_onboarding_version")
                NSUserDefaults.standardUserDefaults().setObject(newValue.vrGlasses, forKey: "session_person_vr_glasses")
            } else {
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_id")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_token")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_password")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_debugging_enabled")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_onboarding_version")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("session_person_vr_glasses")
            }
        }
    }
    
    static var deviceToken: String? {
        didSet {
            updateDeviceToken()
        }
    }
    
    static var isLoggedIn: Bool {
        return sessionData != nil
    }
    
    static var needsOnboarding: Bool {
        return sessionData?.onboardingVersion < OnboardingVersion
    }
    
    private static var logoutCallbacks: [(performAlways: Bool, fn: () -> ())] = []
    
    static func prepare() {
        
        let ID = NSUserDefaults.standardUserDefaults().objectForKey("session_person_id") as? UUID
        let token = NSUserDefaults.standardUserDefaults().objectForKey("session_person_token") as? String
        let password = NSUserDefaults.standardUserDefaults().objectForKey("session_person_password") as? String
        let debuggingEnabled = NSUserDefaults.standardUserDefaults().boolForKey("session_person_debugging_enabled")
        let onboardingVersion = NSUserDefaults.standardUserDefaults().integerForKey("session_person_onboarding_version")
        let vrGlasses = NSUserDefaults.standardUserDefaults().objectForKey("session_person_vr_glasses") as? String
        if let ID = ID, token = token, password = password, vrGlasses = vrGlasses {
            sessionData = SessionData(
                ID: ID,
                token: token,
                password: password,
                debuggingEnabled: debuggingEnabled,
                onboardingVersion: onboardingVersion,
                vrGlasses: vrGlasses
            )
            
            PipelineService.check()
            
            updateMixpanel()
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
                sessionData = SessionData(
                    ID: loginData.ID,
                    token: loginData.token,
                    password: password,
                    debuggingEnabled: false,
                    onboardingVersion: loginData.onboardingVersion,
                    vrGlasses: "CgZHb29nbGUSEkNhcmRib2FyZCBJL08gMjAxNR2ZuxY9JbbzfT0qEAAASEIAAEhCAABIQgAASEJYADUpXA89OgiCc4Y-MCqJPlAAYAM"
                )
                updateDeviceToken()
            })
            .flatMap(.Latest) { _ in ApiService<Person>.get("persons/me") }
            .on(
                next: { person in
                    try! person.insertOrUpdate()
                    updateMixpanel()
                },
                error: { _ in
                    sessionData = nil
                }
            )
            .flatMap(.Latest) { _ in SignalProducer.empty }
    }
    
    static func logout() {
        for (_, fn) in logoutCallbacks {
            fn()
        }
        
        sessionData = nil
        logoutCallbacks = logoutCallbacks.filter { (performAlways, _) in performAlways }
    }
    
    static func onLogout(performAlways performAlways: Bool = false, fn: () -> ()) {
        logoutCallbacks.append((performAlways, fn))
    }
    
    private static func updateMixpanel() {
        let query = PersonTable.filter(PersonTable[PersonSchema.ID] ==- SessionService.sessionData!.ID)
        if let person = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL) {
            Mixpanel.sharedInstance().identify(person.ID)
            Mixpanel.sharedInstance().people.set([
                "$first": person.displayName,
                "$username": person.userName,
                "$email": person.email ?? "test",
                "$created": person.createdAt,
                "Followers": person.followersCount,
                "Followed": person.followedCount,
            ])
        }
    }
    
    private static func updateDeviceToken() {
        if let deviceToken = deviceToken where isLoggedIn {
            ApiService<EmptyResponse>.post("persons/me/update-device-token", parameters: ["token": deviceToken])
                .start()
        }
    }
    
}

struct LoginMappable: Mappable {
    var token: String = ""
    var ID:  UUID = ""
    var onboardingVersion: Int = 0
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        token                   <- map["token"]
        ID                      <- map["id"]
        onboardingVersion       <- map["onboarding_version"]
    }
}
