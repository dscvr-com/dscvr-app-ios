//
//  AppDelegate.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import Device
import Fabric
import Crashlytics
import TwitterKit
import PureLayout
import Mixpanel
import Neon
import FBSDKCoreKit
import Kingfisher
import SwiftyUserDefaults
import ReactiveSwift

let Env = EnvType.staging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let filePath = url.appendingPathComponent("optographs.sqlite3")?.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath!) {
            print("DataBase AVAILABLE")
        } else {
            print("DataBase NOT AVAILABLE - newly created")
            let database = DataBase.sharedInstance
            database.createDataBase()
            if fileManager.fileExists(atPath: filePath!) {
                print("DataBase AVAILABLE")
            }
        }
        
        prepareAndExecute(requireLogin: true) {
            let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
            if launchedBefore  {
                print("Not first launch.")
            }
            else {
                print("First launch, setting NSUserDefault.")
                UserDefaults.standard.set(true, forKey: "launchedBefore")
                Defaults[.SessionVRMode] = true
                Defaults[.SessionUseMultiRing] = false
            }
            
            Mixpanel.sharedInstance()?.track("Launch.Notification")
            
            Defaults[.SessionPhoneModel] = UIDevice.current.modelName
            Defaults[.SessionPhoneOS] = UIDevice.current.systemVersion
            
            let tabBarViewController = TabViewController()
            self.window?.rootViewController = tabBarViewController
            
            Defaults[.SessionGyro] = true
            Defaults[.SessionEliteUser] = true
            
            //motor configurations
            
            Defaults[.SessionPPS] = 250
            Defaults[.SessionRotateCount] = 5111
            Defaults[.SessionTopCount] = 1999
            Defaults[.SessionBotCount] = -3998
            Defaults[.SessionBuffCount] = 0
            
        }
        return true
    }
    
    deinit {
    }

    func applicationWillResignActive(_ application: UIApplication) {
        ScreenService.sharedInstance.hardReset()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        ScreenService.sharedInstance.restore()
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        // Re-register background task if necassary.
        StitchingService.onApplicationResuming()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        Defaults[.SessionStoryOptoID] = nil
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    fileprivate func prepareAndExecute(requireLogin: Bool, fn: () -> ()) {
        
        print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true))
        
//        #if !DEBUG
            Twitter.sharedInstance().start(withConsumerKey: "QZJ8OamzEQ76FghX0EKWqmA7e", consumerSecret: "jhhzAwZGl386N4QxpIvwuIB5nwLeAMoCLYQaDpAm9pXb6IQAZB")
            Fabric.with([Crashlytics.sharedInstance(), Twitter.sharedInstance()])
//        #endif    
        
        if case .production = Env {
            print("production mixpanel")
            //Mixpanel.sharedInstanceWithToken("2cb0781fb2aaac9ef23bb1e92694caae")
        } else {
            print("staging mixpanel")
            Mixpanel.sharedInstance(withToken: "905eb49cf2c78af5ceb307939f02c092")
        }
        
        try! DatabaseService.prepare()
        
        setupAppearanceDefaults()
        
        KingfisherManager.shared.downloader.downloadTimeout = 60
        KingfisherManager.shared.cache.maxDiskCacheSize = 200000000
        KingfisherManager.shared.cache.maxMemoryCost = 10
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        window?.backgroundColor = .white
        
//        SessionService.prepare()

        window?.makeKeyAndVisible()
        
        VersionService.updateToLatest()
        
        fn()
    }
    
}

public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}
