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
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let new = viewController as? UniqueView, let old = viewControllers.last as? UniqueView, new.uniqueIdentifier == old.uniqueIdentifier {
            return
        }
        super.pushViewController(viewController, animated: animated)
    }
    
}
