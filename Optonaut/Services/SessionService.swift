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
import SwiftyUserDefaults

extension DefaultsKeys {
    static let SessionToken = DefaultsKey<String?>("session_auth_token")
    static let SessionPersonID = DefaultsKey<UUID?>("session_person_id")
    static let SessionPassword = DefaultsKey<String?>("session_password")
    static let SessionDebuggingEnabled = DefaultsKey<Bool>("session_debugging_enabled")
    static let SessionOnboardingVersion = DefaultsKey<Int>("session_onboarding_version")
    static let SessionVRGlassesSelected = DefaultsKey<Bool>("session_vr_glasses_selected")
    static let SessionVRGlasses = DefaultsKey<String>("session_vr_glasses")
}

let DefaultVRGlasses = "CgZHb29nbGUSEkNhcmRib2FyZCBJL08gMjAxNR2ZuxY9JbbzfT0qEAAASEIAAEhCAABIQgAASEJYADUpXA89OgiCc4Y-MCqJPlAAYAM"

class SessionService {
    
    static var isLoggedIn: Bool {
        return Defaults[.SessionPersonID] != nil && Defaults[.SessionToken] != nil
    }
    
    static var needsOnboarding: Bool {
        return Defaults[.SessionOnboardingVersion] < OnboardingVersion
    }
    
    private static var logoutCallbacks: [(performAlways: Bool, fn: () -> ())] = []
    
    static func prepare() {
        updateMixpanel()
        
        if Defaults[.SessionVRGlasses].isEmpty {
            Defaults[.SessionVRGlasses] = DefaultVRGlasses
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
                Defaults[.SessionPassword] = password
            })
            .flatMap(.Latest) { handleSignin($0) }
    }
    
    static func handleSignin(loginData: LoginMappable) -> SignalProducer<Void, ApiError> {
       return SignalProducer(value: loginData)
            .on(next: { loginData in
                Defaults[.SessionToken] = loginData.token
                Defaults[.SessionPersonID] = loginData.ID
                Defaults[.SessionDebuggingEnabled] = false
                Defaults[.SessionOnboardingVersion] = loginData.onboardingVersion
                Defaults[.SessionVRGlassesSelected] = false
                Defaults[.SessionVRGlasses] = DefaultVRGlasses
            })
            .flatMap(.Latest) { _ in ApiService<Person>.get("persons/me") }
            .on(
                next: { person in
                    try! person.insertOrUpdate()
                    Mixpanel.sharedInstance().createAlias(person.ID, forDistinctID: Mixpanel.sharedInstance().distinctId)
                    updateMixpanel()
                },
                failed: { _ in
                    reset()
                }
            )
            .flatMap(.Latest) { _ in SignalProducer.empty }
    }
    
    static func logout() {
        for (_, fn) in logoutCallbacks {
            fn()
        }
        
        reset()
        
        logoutCallbacks = logoutCallbacks.filter { (performAlways, _) in performAlways }
    }
    
    static func onLogout(performAlways performAlways: Bool = false, fn: () -> ()) {
        logoutCallbacks.append((performAlways, fn))
    }
    
    private static func reset() {
        Defaults[.SessionToken] = nil
        Defaults[.SessionPersonID] = nil
        Defaults[.SessionPassword] = nil
        Defaults[.SessionDebuggingEnabled] = false
        Defaults[.SessionOnboardingVersion] = 0
        Defaults[.SessionVRGlassesSelected] = false
        Defaults[.SessionVRGlasses] = DefaultVRGlasses
        
        Mixpanel.sharedInstance().reset()
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    private static func updateMixpanel() {
        guard let personID = Defaults[.SessionPersonID] else {
            return
        }
        
        let query = PersonTable.filter(PersonTable[PersonSchema.ID] ==- personID)
        if let person = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL) {
            Mixpanel.sharedInstance().identify(person.ID)
            Mixpanel.sharedInstance().people.set([
                "$first": person.displayName,
                "$username": person.userName,
                "$email": person.email!,
                "$created": person.createdAt,
                "Followers": person.followersCount,
                "Followed": person.followedCount,
            ])
        }
    }
    
}

struct LoginMappable: Mappable {
    var token: String = ""
    var ID:  UUID = ""
    var onboardingVersion: Int = 0
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        token              <- map["token"]
        ID                 <- map["id"]
        onboardingVersion  <- map["onboarding_version"]
    }
}

enum LoginIdentifier {
    case UserName(String)
    case Email(String)
}