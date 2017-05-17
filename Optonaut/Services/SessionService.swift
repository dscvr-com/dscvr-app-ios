//
//  SessionService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/3/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveSwift
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
    static let SessionGyro = DefaultsKey<Bool>("session_use_gyro")
    static let SessionVRMode = DefaultsKey<Bool>("session_use_vr")
    static let SessionPhoneModel = DefaultsKey<String?>("session_phone_model")
    static let SessionPhoneOS = DefaultsKey<String?>("session_phone_os")
    static let SessionEliteUser = DefaultsKey<Bool>("session_elite_user")
    static let SessionUserDidFirstLogin = DefaultsKey<Bool>("session_did_first_login")
    static let SessionBPS = DefaultsKey<String?>("session_ball_per_second")
    static let SessionStepCount = DefaultsKey<String?>("session_step_count")
    static let SessionStoryOptoID = DefaultsKey<UUID?>("session_story_opto_id")
    
    static let SessionMotor = DefaultsKey<Bool>("session_use_motor")
    static let SessionPPS = DefaultsKey<Int?>("session_pulse_per_second")
    static let SessionRotateCount = DefaultsKey<Int?>("session_rotate_count")
    static let SessionTopCount = DefaultsKey<Int?>("session_top_count")
    static let SessionBotCount = DefaultsKey<Int?>("session_bot_count")
    static let SessionBuffCount = DefaultsKey<Int?>("session_buff_count")
}

let DefaultVRGlasses = "CgZHb29nbGUSEkNhcmRib2FyZCBJL08gMjAxNR2ZuxY9JbbzfT0qEAAASEIAAEhCAABIQgAASEJYADUpXA89OgiCc4Y-MCqJPlAAYAM"

class SessionService {
    
    static var isLoggedIn: Bool {
        return Defaults[.SessionPersonID] != nil && Defaults[.SessionToken] != nil
    }
    
//    static var personID: String {
//        return Defaults[.SessionPersonID] ?? Person.guestID
//    }

    static var needsOnboarding: Bool {
        return Defaults[.SessionOnboardingVersion] < OnboardingVersion
    }
    
    fileprivate static var logoutCallbacks: [(performAlways: Bool, fn: () -> ())] = []
    
    static let loginNotifiaction = NotificationSignal<Void>()
    
    static func prepare() {
        
//        if isLoggedIn {
//            let query = PersonTable.filter(PersonTable[PersonSchema.ID] == personID)
//            let person = try! DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL)!
//            Models.persons.create(person)
//            
//            updateMixpanel()
//        }

        if Defaults[.SessionVRGlasses].isEmpty {
            Defaults[.SessionVRGlasses] = DefaultVRGlasses
        }
    }
    

    static func logoutReset() {
        reset()
    }
    
    fileprivate static func reset() {
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
        
        Mixpanel.sharedInstance()?.reset()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
}

enum LoginIdentifier {
    case userName(String)
    case email(String)
}
