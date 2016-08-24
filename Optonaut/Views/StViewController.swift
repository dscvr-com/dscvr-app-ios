//
//  StViewController.swift
//  DSCVR
//
//  Created by robert john alkuino on 8/24/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class StViewController: UIViewController,TabControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()
        let strLabel = UILabel()
        strLabel.frame = CGRect(x: 40,y: 40,width: 100,height: 40)
        strLabel.text = "SAAAAAD!"
        strLabel.textAlignment = .Center
        view.addSubview(strLabel)
        
        tabController!.delegate = self
    }
    
    func tapRightButton() {
        tabController!.leftButtonAction()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }

}
