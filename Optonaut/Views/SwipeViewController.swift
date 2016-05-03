//
//  SwipeViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 4/29/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import EZSwipeController
import ReactiveCocoa

class SwipeViewController: EZSwipeController {
    
    private let navigationBar = UINavigationBar()

    override func setupView() {
        datasource = self
        print("Pumasok dito")
    }
    
    dynamic private func showCardboardAlert() {
        let confirmAlert = UIAlertController(title: "Put phone in VR viewer", message: "Please turn your phone and put it into your VR viewer.", preferredStyle: .Alert)
        confirmAlert.addAction(UIAlertAction(title: "Continue", style: .Cancel, handler: { _ in return }))
        navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
    }
}
protocol appsNavigationBar {
    func returnNavigationBar()
}


extension SwipeViewController: EZSwipeControllerDataSource {
    
    func navigationBarDataForPageIndex(index: Int) -> UINavigationBar {
        
        navigationBar.translucent = false
        navigationBar.barTintColor = UIColor(hex:0x343434)
        navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
        navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.enabled = false
        
        let cardboardButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
        cardboardButton.text = String.iconWithName(.Cardboard)
        cardboardButton.textColor = .whiteColor()
        cardboardButton.font = UIFont.iconOfSize(24)
        cardboardButton.userInteractionEnabled = true
        cardboardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SwipeViewController.showCardboardAlert)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cardboardButton)
        navigationBar.pushNavigationItem(navigationItem, animated: false)
        
        return navigationBar
    }
    
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
