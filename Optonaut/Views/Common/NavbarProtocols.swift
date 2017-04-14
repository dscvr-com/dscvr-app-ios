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
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
        
        UIApplication.shared.setStatusBarHidden(true, with: .none)
    }
    
}

protocol TransparentNavbarWithStatusBar {
    func updateNavbarAppear()
}
extension TransparentNavbarWithStatusBar where Self: UIViewController {
    
    func updateNavbarAppear() {
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
}

protocol RedNavbar {
    func updateNavbarAppear()
}

extension RedNavbar where Self: UIViewController {

    func updateNavbarAppear() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor(hex:0x343434)
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(0, for: .default)
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.white,
        ]
        
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
}
protocol WhiteNavBar {
    func updateNavbarAppear()
}
extension WhiteNavBar where Self: UIViewController {
    
    func updateNavbarAppear() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor(hex:0xf7f7f7)
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(0, for: .default)
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.white,
        ]
        
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
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
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }
    
}
