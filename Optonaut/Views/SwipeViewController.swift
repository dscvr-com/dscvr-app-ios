//
//  SwipeViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 4/29/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import EZSwipeController

class SwipeViewController: EZSwipeController {

    override func setupView() {
        datasource = self
        print("Pumasok dito")
    }
}

extension SwipeViewController: EZSwipeControllerDataSource {
    
//    func navigationBarDataForPageIndex(index: Int) -> UINavigationBar {
//        let navigationBar = UINavigationBar()
//        
//        navigationBar.pushNavigationItem(navigationItem, animated: false)
//        return navigationBar
//    }
    
    func viewControllerData() -> [UIViewController] {
        print("Pumasok dito 2")
        let redVC = UIViewController()
        redVC.view.backgroundColor = UIColor.redColor()
        
        let blueVC = UIViewController()
        blueVC.view.backgroundColor = UIColor.blueColor()
        
        let greenVC = UIViewController()
        greenVC.view.backgroundColor = UIColor.greenColor()
        //return [redVC,blueVC,greenVC]
        
        return [OptographCollectionViewController(viewModel: FeedOptographCollectionViewModel()), blueVC, greenVC]
    }
}
