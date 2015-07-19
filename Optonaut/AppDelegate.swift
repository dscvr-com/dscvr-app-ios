//
//  AppDelegate.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
//        try! NSFileManager.defaultManager().removeItemAtPath(Realm.defaultPath)
        
        setupAppearanceDefaults()
        
        if NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.DebugEnabled.rawValue) == nil {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: UserDefaultsKeys.DebugEnabled.rawValue)
        }
        
        let credProvider = AWSStaticCredentialsProvider(accessKey: "AKIAJ6AYCIIVD6E4FDLQ", secretKey: "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")
        let configuration = AWSServiceConfiguration(region: .EUWest1, credentialsProvider: credProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if let window = window {
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "onNotificationLogout", name: NotificationKeys.Logout.rawValue, object: nil)
            
            window.backgroundColor = UIColor.whiteColor()
            
            let userIsLoggedIn = NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultsKeys.UserIsLoggedIn.rawValue);
            if userIsLoggedIn {
                window.rootViewController = TabBarViewController()
            } else {
                window.rootViewController = LoginViewController()
            }
            window.makeKeyAndVisible()
        }
        
        return true
    }
    
    func onNotificationLogout() {
        NSUserDefaults.standardUserDefaults().setObject("", forKey: UserDefaultsKeys.UserToken.rawValue)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: UserDefaultsKeys.UserIsLoggedIn.rawValue)
        
        if let window = window {
            window.rootViewController = LoginViewController()
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

