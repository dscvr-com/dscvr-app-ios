//
//  NavbarProtocols.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/8/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

protocol TransparentNavbar {
    func updateNavbarAppear()
}

extension TransparentNavbar where Self: UIViewController {

    func updateNavbarAppear() {
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
    }
    
}

protocol RedNavbar {
    func updateNavbarAppear()
}

extension RedNavbar where Self: UIViewController {

    func updateNavbarAppear() {
        navigationController?.navigationBar.translucent = false
        navigationController?.navigationBar.barTintColor = UIColor.Accent
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
        navigationController?.navigationBar.titleTextAttributes = [
//            NSFontAttributeName: UIFont.robotoOfSize(17, withType: .Medium),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
    }
    
}

protocol NoNavbar {
    func updateNavbarAppear()
}

extension NoNavbar where Self: UIViewController {

    func updateNavbarAppear() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
    }
    
}