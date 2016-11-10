//
//  SessionService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/3/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite
import Mixpanel
import SwiftyUserDefaults
import TwitterKit
import FBSDKLoginKit

extension DefaultsKeys {
    static let SessionToken = DefaultsKey<String?>("session_auth_token")
    static let SessionPersonID = DefaultsKey<UUID?>("session_person_id")
    static let SessionPassword = DefaultsKey<String?>("session_password")
    static let SessionDebuggingEnabled = DefaultsKey<Bool>("session_debugging_enabled")
    static let SessionOnboardingVersion = DefaultsKey<Int>("session_onboarding_version")
    static let SessionVRGlassesSelected = DefaultsKey<Bool>("session_vr_glasses_selected")
    static let SessionVRGlasses = DefaultsKey<String>("session_vr_glasses")
    static let SessionShareToggledFacebook = DefaultsKey<Bool>("session_share_toggled_facebook")
    static let SessionShareToggledTwitter = DefaultsKey<Bool>("session_share_toggled_twitter")
    static let SessionShareToggledInstagram = DefaultsKey<Bool>("session_share_toggled_instagram")
    static let SessionUseMultiRing = DefaultsKey<Bool>("session_use_multi_ring")
    static let SessionUploadMode = DefaultsKey<String?>("session_upload_mode")
    static let SessionNeedRefresh = DefaultsKey<Bool>("session_profile_need_refresh")
    static let SessionMotor = DefaultsKey<Bool>("session_use_motor")
    static let SessionGyro = DefaultsKey<Bool>("session_use_gyro")
    static let SessionVRMode = DefaultsKey<Bool>("session_use_vr")
    static let SessionPhoneModel = DefaultsKey<String?>("session_phone_model")
    static let SessionPhoneOS = DefaultsKey<String?>("session_phone_os")
    static let SessionEliteUser = DefaultsKey<Bool>("session_elite_user")
    static let SessionUserDidFirstLogin = DefaultsKey<Bool>("session_did_first_login")
    static let SessionBPS = DefaultsKey<String?>("session_ball_per_second")
    static let SessionStepCount = DefaultsKey<String?>("session_step_count")
    static let SessionStoryOptoID = DefaultsKey<UUID?>("session_story_opto_id")
}

let DefaultVRGlasses = "CgZHb29nbGUSEkNhcmRib2FyZCBJL08gMjAxNR2ZuxY9JbbzfT0qEAAASEIAAEhCAABIQgAASEJYADUpXA89OgiCc4Y-MCqJPlAAYAM"

class SessionService {
    
    static var isLoggedIn: Bool {
        return Defaults[.SessionPersonID] != nil && Defaults[.SessionToken] != nil
    }
    
    static var personID: String {
        return Defaults[.SessionPersonID] ?? Person.guestID
    }
    
    static var needsOnboarding: Bool {
        return Defaults[.SessionOnboardingVersion] < OnboardingVersion
    }
    
    private static var logoutCallbacks: [(performAlways: Bool, fn: () -> ())] = []
    
    static let loginNotifiaction = NotificationSignal<Void>()
    
    static func prepare() {
        
        if isLoggedIn {
            let query = PersonTable.filter(PersonTable[PersonSchema.ID] == personID)
            let person = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL)!
            Models.persons.create(person)
            
            //updateMixpanel()
        }
        
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
        
        return ApiService<LoginApiModel>.post("persons/login", parameters: parameters)
            .on(next: { loginData in
                Defaults[.SessionPassword] = password
            })
            .flatMap(.Latest) { handleSignin($0) }
    }
    
    static func handleSignin(loginData: LoginApiModel) -> SignalProducer<Void, ApiError> {
       return SignalProducer(value: loginData)
            .on(next: { loginData in
                Defaults[.SessionToken] = loginData.token
                Defaults[.SessionPersonID] = loginData.ID
                Defaults[.SessionDebuggingEnabled] = false
                Defaults[.SessionOnboardingVersion] = loginData.onboardingVersion
                Defaults[.SessionVRGlassesSelected] = false
                Defaults[.SessionVRGlasses] = DefaultVRGlasses
                //Defaults[.SessionShareToggledFacebook] = safeOptional(FBSDKAccessToken.currentAccessToken())?.hasGranted("publish_actions") ?? false
                Defaults[.SessionShareToggledTwitter] = false
                Defaults[.SessionShareToggledInstagram] = false
                Defaults[.SessionUseMultiRing] = false
                Defaults[.SessionNeedRefresh] = true
            })
            .flatMap(.Latest) { _ in
                ApiService<PersonApiModel>.get("persons/me") }
            .map(Person.fromApiModel)
            .on(
                next: { person in
                    
                    Models.persons.touch(person).insertOrUpdate()
                    //Defaults[.SessionEliteUser] = person.eliteStatus == 1 ? true:false
                    Mixpanel.sharedInstance().createAlias(person.ID, forDistinctID: Mixpanel.sharedInstance().distinctId)
                    //updateMixpanel()
                    loginNotifiaction.notify(())
                },
                failed: { _ in
                    reset()
                }
            )
            .flatMap(.Latest) { _ in SignalProducer.empty }
    }
    
    static func facebookSignin(userID: String, token: String) -> SignalProducer<Void, ApiError> {
        let parameters = [
            "facebook_user_id": userID,
            "facebook_token": token,
        ]
        print(parameters)
        return ApiService<LoginApiModel>.post("persons/facebook/signin", parameters: parameters)
            .flatMap(.Latest) { SessionService.handleSignin($0) }
    }
    
    static func logout() {
        for (_, fn) in logoutCallbacks {
            fn()
        }
        // logout twitter
        if let session = Twitter.sharedInstance().sessionStore.session() {
            Twitter.sharedInstance().sessionStore.logOutUserID(session.userID)
        }
        
        // logout facebook
        FBSDKAccessToken.setCurrentAccessToken(nil)
        
        reset()
        
        logoutCallbacks = logoutCallbacks.filter { (performAlways, _) in performAlways }
    }
    
    static func onLogout(performAlways performAlways: Bool = false, fn: () -> ()) {
        logoutCallbacks.append((performAlways, fn))
    }
    static func logoutReset() {
        reset()
    }
    
    private static func reset() {
        Defaults[.SessionToken] = nil
        Defaults[.SessionPersonID] = nil
        Defaults[.SessionPassword] = nil
        Defaults[.SessionDebuggingEnabled] = false
        Defaults[.SessionOnboardingVersion] = 0
        Defaults[.SessionVRGlassesSelected] = false
        Defaults[.SessionVRGlasses] = DefaultVRGlasses
        Defaults[.SessionShareToggledFacebook] = false
        Defaults[.SessionShareToggledTwitter] = false
        Defaults[.SessionShareToggledInstagram] = false
        //Defaults[.SessionEliteUser] = false
        
        //Mixpanel.sharedInstance().reset()
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    private static func updateMixpanel() {
        let person = Models.persons[personID]!.model
        
        Mixpanel.sharedInstance().identify(person.ID)
        Mixpanel.sharedInstance().people.set([
            "$first": person.displayName,
            "$username": person.userName,
            "$email": person.email!,
            "$created": person.createdAt,
            "Followers": person.followersCount,
            "Followed": person.followedCount,
            "EliteStatus": person.eliteStatus
        ])
    }
    
}

enum LoginIdentifier {
    case UserName(String)
    case Email(String)
}