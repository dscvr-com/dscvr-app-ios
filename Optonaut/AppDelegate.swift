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

//let Env = EnvType.Development
//let Env = EnvType.localStaging
let Env = EnvType.Staging
//let Env = EnvType.Production

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        prepareAndExecute(requireLogin: true) {
//            let tabBarViewController = TabBarViewController()
//            
//            if let notification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject: AnyObject] {
//                Mixpanel.sharedInstance().track("Launch.Notification")
//                self.application(application, didReceiveRemoteNotification: notification)
//                tabBarViewController.selectedIndex = 2
//            }
            
//            self.window?.rootViewController = tabBarViewController
            
            let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
            let pushNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
            Mixpanel.sharedInstance().track("Launch.Notification")
            application.registerUserNotificationSettings(pushNotificationSettings)
            application.registerForRemoteNotifications()
            self.window?.rootViewController = TabViewController()
        }
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        ScreenService.sharedInstance.hardReset()
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        ScreenService.sharedInstance.restore()
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        FBSDKAppEvents.activateApp()
        
        // Re-register background task if necassary.
        StitchingService.onApplicationResuming()
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0;
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if url.scheme.hasPrefix("fb\(FBSDKSettings.appID())") && url.host == "authorize" {
            return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
        }

        prepareAndExecute(requireLogin: false) {
//            let tabBarViewController = TabBarViewController()
//            
//            if case .Optograph(let uuid) = url.applicationURLData {
//                let detailsViewController = DetailsTableViewController(optographID: uuid)
//                tabBarViewController.feedNavViewController.pushViewController(detailsViewController, animated: false)
//            }
//            
//            self.window?.rootViewController = tabBarViewController
            self.window?.rootViewController = TabViewController()
        }
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
        var tokenString = ""
        
        print("DEVICE TOKEN = \(deviceToken)")
        
        for var i = 0; i < deviceToken.length; i++ {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        DeviceTokenService.deviceToken = tokenString
    }
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("my error===",error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject: AnyObject]) {
//        if let tabBarViewController = window?.rootViewController as? TabBarViewController where SessionService.isLoggedIn {
//            tabBarViewController.activityNavViewController.activityTableViewController.viewModel.refreshNotification.notify(())
//        }
    }
    
    private func prepareAndExecute(requireLogin requireLogin: Bool, fn: () -> ()) {
        
        print(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true))
        
//        #if !DEBUG
            Twitter.sharedInstance().startWithConsumerKey("sKBlhsebljhzzejrOWdWVAYKD", consumerSecret: "jZE8ccXXGf869FZrmaeTV2Al0CZqSWLz6dBvBLOqEVBg0igaNi")
            Fabric.with([Crashlytics.sharedInstance(), Twitter.sharedInstance()])
//        #endif
        
        if case .Production = Env {
            Mixpanel.sharedInstanceWithToken("10ba57dae2871ca534c61f0f89bab97d")
        } else {
            //Mixpanel.sharedInstanceWithToken("544f3d4afdb4836ed2e070e33a328249")
            Mixpanel.sharedInstanceWithToken("4acea0241fb1192f8f598174acbc8759")
        }
        
        try! DatabaseService.prepare()
        
        setupAppearanceDefaults()
        
        KingfisherManager.sharedManager.downloader.downloadTimeout = 60
        KingfisherManager.sharedManager.cache.maxDiskCacheSize = 200000000 // 200mb
//        KingfisherManager.sharedManager.cache.maxMemoryCost = 400000000 // 100mb = 4e+8 pixels
//        KingfisherManager.sharedManager.cache.maxMemoryCost = 25000000 // 100mb = 2.5e+7 pixels
        KingfisherManager.sharedManager.cache.maxMemoryCost = 10 // 100mb = 2.5e+7 pixels
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        window?.backgroundColor = .whiteColor()
        
        SessionService.prepare()
        SessionService.onLogout(performAlways: true) { self.window?.rootViewController = TabViewController() }
        
//        if SessionService.isLoggedIn || !requireLogin {
//            if SessionService.needsOnboarding && requireLogin {
//                window?.rootViewController = OnboardingInfoViewController()
//            } else {
                fn()
//            }
//        } else {
//            window?.rootViewController = LoginViewController()
//        }
        
        VersionService.onOutdatedApiVersion {
            let alert = UIAlertController(title: "Update needed", message: "It seems like you run a pretty old version of IAM360. Please update to the newest version.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Update", style: .Default, handler: { _ in
                let appId = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? NSString
                let url = NSURL(string: "itms-apps://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftwareUpdate?id=\(appId!)&mt=8")
                UIApplication.sharedApplication().openURL(url!)
            }))
            self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
        
        window?.makeKeyAndVisible()
        
        VersionService.updateToLatest()
    }
    
}