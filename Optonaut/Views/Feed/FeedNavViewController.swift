//
//  CollectionNavViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 01/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class FeedNavViewController: NavigationController {
    
    let viewController = OptographCollectionViewController(viewModel: FeedOptographCollectionViewModel())
    
    //weak var parentViewController: UIViewController?
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navTitle = UIImage(named:"iam360_navTitle")
        let imageView = UIImageView(image:navTitle)
        viewController.navigationItem.titleView = imageView
        
        pushViewController(viewController, animated: false)
    }
}