//
//  TabViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class TabViewController: UIViewController {
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = CollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        addChildViewController(vc)
        
        view.insertSubview(vc.view, atIndex: 0)
        
        blurView.frame = CGRect(x: 0, y: view.frame.height - 108, width: view.frame.width, height: 108)
        blurView.alpha = 0.9
        view.addSubview(blurView)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
