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
    
    fileprivate var originalBrightness: CGFloat?
    fileprivate var targetBrightness: CGFloat?
    fileprivate var fadeTimer: Timer?
    
    fileprivate init() {}
    
    func max() {
        originalBrightness = UIScreen.main.brightness
        fadeTimer?.invalidate()
        targetBrightness = 1
        fadeTimer = Timer.scheduledTimer(timeInterval: 1 / 60, target: self, selector: "tick", userInfo: nil, repeats: true)
    }
    
    func reset() {
        fadeTimer?.invalidate()
        targetBrightness = originalBrightness
        fadeTimer = Timer.scheduledTimer(timeInterval: 1 / 60, target: self, selector: "tick", userInfo: nil, repeats: true)
    }
    
    func hardReset() {
        fadeTimer?.invalidate()
        if let originalBrightness = originalBrightness {
            UIScreen.main.brightness = originalBrightness
        }
    }
    
    func restore() {
        fadeTimer = Timer.scheduledTimer(timeInterval: 1 / 60, target: self, selector: "tick", userInfo: nil, repeats: true)
    }
    
    dynamic func tick() {
        guard let targetBrightness = targetBrightness else {
            fadeTimer?.invalidate()
            return
        }
        
        let diff = targetBrightness - UIScreen.main.brightness
        if diff != 0 {
            if abs(diff) < 0.01 {
                UIScreen.main.brightness += diff
            } else {
                UIScreen.main.brightness += (diff / 10)
            }
        } else {
            fadeTimer?.invalidate()
            fadeTimer = nil
        }
    }
    
}
