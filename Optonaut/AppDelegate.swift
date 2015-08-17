//
//  AppDelegate.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
//import RealmSwift
import Device

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        print(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true))
        
        DatabaseManager.prepare()
        setupAppearanceDefaults()
        
        if NSUserDefaults.standardUserDefaults().objectForKey(PersonDefaultsKeys.DebugEnabled.rawValue) == nil {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: PersonDefaultsKeys.DebugEnabled.rawValue)
        }
        
        // TODO remove aws stuff
        let credProvider = AWSStaticCredentialsProvider(accessKey: "AKIAJ6AYCIIVD6E4FDLQ", secretKey: "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")
        let configuration = AWSServiceConfiguration(region: .EUWest1, credentialsProvider: credProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        if let window = window {
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "onNotificationLogout", name: NotificationKeys.Logout.rawValue, object: nil)
            
            window.backgroundColor = UIColor.whiteColor()
            
            let userIsLoggedIn = NSUserDefaults.standardUserDefaults().boolForKey(PersonDefaultsKeys.PersonIsLoggedIn.rawValue);
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
        NSUserDefaults.standardUserDefaults().setObject("", forKey: PersonDefaultsKeys.PersonToken.rawValue)
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: PersonDefaultsKeys.PersonIsLoggedIn.rawValue)
        
        // reset db
        let db = DatabaseManager.defaultConnection
        try! db.run(PersonTable.delete())
        try! db.run(OptographTable.delete())
        try! db.run(CommentTable.delete())
        
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

