//
//  ScreenService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class ScreenService {
    
    static let sharedInstance = ScreenService()
    
    private var originalBrightness: CGFloat?
    private var targetBrightness: CGFloat?
    private var fadeTimer: NSTimer?
    
    private init() {}
    
    func max() {
        originalBrightness = UIScreen.mainScreen().brightness
        fadeTimer?.invalidate()
        targetBrightness = 1
        fadeTimer = NSTimer.scheduledTimerWithTimeInterval(1 / 60, target: self, selector: "tick", userInfo: nil, repeats: true)
    }
    
    func reset() {
        fadeTimer?.invalidate()
        targetBrightness = originalBrightness
        fadeTimer = NSTimer.scheduledTimerWithTimeInterval(1 / 60, target: self, selector: "tick", userInfo: nil, repeats: true)
    }
    
    func hardReset() {
        fadeTimer?.invalidate()
        if let originalBrightness = originalBrightness {
            UIScreen.mainScreen().brightness = originalBrightness
        }
    }
    
    func restore() {
        fadeTimer = NSTimer.scheduledTimerWithTimeInterval(1 / 60, target: self, selector: "tick", userInfo: nil, repeats: true)
    }
    
    @objc func tick() {
        guard let targetBrightness = targetBrightness else {
            fadeTimer?.invalidate()
            return
        }
        
        let diff = targetBrightness - UIScreen.mainScreen().brightness
        if diff != 0 {
            if abs(diff) < 0.01 {
                UIScreen.mainScreen().brightness += diff
            } else {
                UIScreen.mainScreen().brightness += (diff / 10)
            }
        } else {
            fadeTimer?.invalidate()
            fadeTimer = nil
        }
    }
    
}