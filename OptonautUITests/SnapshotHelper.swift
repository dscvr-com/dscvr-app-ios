//
//  SnapshotHelper.swift
//  Example
//
//  Created by Felix Krause on 10/8/15.
//  Copyright © 2015 Felix Krause. All rights reserved.
//

import Foundation
import XCTest

var deviceLanguage = ""

func setLanguage(_ app: XCUIApplication)
{
    Snapshot.setLanguage(app)
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool = false)
{
    Snapshot.snapshot(name, waitForLoadingIndicator: waitForLoadingIndicator)
}



@objc class Snapshot: NSObject
{
    class func setLanguage(_ app: XCUIApplication)
    {
        let path = "/tmp/language.txt"

        do {
            let locale = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
            deviceLanguage = locale.substring(to: locale.characters.index(locale.startIndex, offsetBy: 2, limitedBy:locale.endIndex)!)
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))", "-AppleLocale", "\"\(locale)\"","-ui_testing"]
        } catch {
            print("Couldn't detect/set language...")
        }
    }
    
    class func snapshot(_ name: String, waitForLoadingIndicator: Bool = false)
    {
        if (waitForLoadingIndicator)
        {
            waitForLoadingIndicatorToDisappear()
        }
        print("snapshot: \(name)") // more information about this, check out https://github.com/krausefx/snapshot
        
        sleep(1) // Waiting for the animation to be finished (kind of)
        XCUIDevice.shared().orientation = .unknown
    }
    
    class func waitForLoadingIndicatorToDisappear()
    {
        let query = XCUIApplication().statusBars.children(matching: .other).element(boundBy: 1).children(matching: .other)
        
        while (query.count > 4) {
            sleep(1)
            print("Number of Elements in Status Bar: \(query.count)... waiting for status bar to disappear")
        }
    }
}

// Please don't remove the lines below
// They are used to detect outdated configuration files
// SnapshotHelperVersion [[1.0]]
