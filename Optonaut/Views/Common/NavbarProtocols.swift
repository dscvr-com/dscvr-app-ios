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
        navigationController?.navigationBar.barTintColor = UIColor(hex:0x343434)
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.enabled = false
    }
    
}

extension UIColor {
    convenience init(hex: Int) {
        let r = hex / 0x10000
        let g = (hex - r*0x10000) / 0x100
        let b = hex - r*0x10000 - g*0x100
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
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