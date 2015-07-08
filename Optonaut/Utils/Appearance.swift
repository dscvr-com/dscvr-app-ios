//
//  Appearance.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/8/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

func setupAppearanceDefaults() {
    UINavigationBar.appearance().tintColor = .whiteColor()
    UINavigationBar.appearance().setBackgroundImage(UIImage(), forBarMetrics:UIBarMetrics.Default)
}