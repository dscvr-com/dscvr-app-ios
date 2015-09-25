//
//  NavigationController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/7/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

protocol UniqueView {
    var uniqueIdentifier: String { get }
}

class NavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interactivePopGestureRecognizer?.delegate = self
    }
    
    override func pushViewController(viewController: UIViewController, animated: Bool) {
        if let new = viewController as? UniqueView, old = viewControllers.last as? UniqueView where new.uniqueIdentifier == old.uniqueIdentifier {
            return
        }
        super.pushViewController(viewController, animated: animated)
    }
    
}

extension NavigationController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
    
}
