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
import PureLayout
import Mixpanel
import WebImage

//let Env = EnvType.Development
let Env = EnvType.Staging
//let Env = EnvType.Production

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        prepareAndExecute {
            self.window?.rootViewController = TabBarViewController()
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
        
        //Re-register background task if necassary. 
        StitchingService.onApplicationResuming()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        prepareAndExecute {
            let tabBarViewController = TabBarViewController()
            
            if case .Optograph(let uuid) = url.applicationURLData {
                let detailsViewController = DetailsTableViewController(optographId: uuid)
                tabBarViewController.feedNavViewController.pushViewController(detailsViewController, animated: false)
            }
            
            self.window?.rootViewController = tabBarViewController
        }
        
        return true
    }
    
    private func prepareAndExecute(fn: () -> ()) {
        print(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true))
        
        Fabric.with([Crashlytics.self()])
        
        if case .Production = Env {
            Mixpanel.sharedInstanceWithToken("10ba57dae2871ca534c61f0f89bab97d")
        } else {
            Mixpanel.sharedInstanceWithToken("544f3d4afdb4836ed2e070e33a328249")
        }
        
        try! DatabaseService.prepare()
        
        setupAppearanceDefaults()
        
        SDImageCache.sharedImageCache().shouldDecompressImages = false
        SDImageCache.sharedImageCache().shouldCacheImagesInMemory = false
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        window?.backgroundColor = .whiteColor()
        
        SessionService.prepare()
        SessionService.onLogout(performAlways: true) { self.window?.rootViewController = LoginViewController() }
        
        if SessionService.isLoggedIn {
            if SessionService.needsOnboarding {
                window?.rootViewController = OnboardingInfoViewController()
            } else {
                fn()
            }
        } else {
            window?.rootViewController = LoginViewController()
        }
        
        VersionService.onOutdatedApiVersion {
            let alert = UIAlertController(title: "Update needed", message: "It seems like you run a pretty old version of Optonaut. Please update to the newest version.", preferredStyle: .Alert)
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

