//
//  MainViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/6/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async
import Icomoon
import SwiftyUserDefaults
import Result

class SwipeViewController: UIViewController{
    
    
    var scrollView: UIScrollView!
    let leftViewController: NavigationController
    
    required init() {
        leftViewController = FeedNavViewController()
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.backgroundColor = UIColor.blackColor()
        let scrollWidth: CGFloat  = 3 * self.view.frame.width
        let scrollHeight: CGFloat  = self.view.frame.size.height
        self.scrollView!.contentSize = CGSizeMake(scrollWidth, scrollHeight);
        self.scrollView!.pagingEnabled = true;
        
        let blueVC = UIViewController()
        blueVC.view.backgroundColor = UIColor.blueColor()
        
        let greenVC = UIViewController()
        greenVC.view.backgroundColor = UIColor.greenColor()
        
        self.addChildViewController(leftViewController)
        self.scrollView!.addSubview(leftViewController.view)
        leftViewController.didMoveToParentViewController(self)
        
        self.addChildViewController(blueVC)
        self.scrollView!.addSubview(blueVC.view)
        blueVC.didMoveToParentViewController(self)
        
        self.addChildViewController(greenVC)
        self.scrollView!.addSubview(greenVC.view)
        greenVC.didMoveToParentViewController(self)
        
        var adminFrame :CGRect = leftViewController.view.frame
        adminFrame.origin.x = adminFrame.width
        blueVC.view.frame = adminFrame
        
        var BFrame :CGRect = blueVC.view.frame
        BFrame.origin.x = 2*BFrame.width
        greenVC.view.frame = BFrame
        
        view.addSubview(scrollView)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
