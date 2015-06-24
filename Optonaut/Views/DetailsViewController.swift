//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {
    
    var data: Optograph!
    
    required init(data: Optograph) {
        super.init(nibName: nil, bundle: nil)
        self.data = data
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        navigationItem.title = "Details"
        
        let title = UILabel(frame: view.frame)
        title.text = "TODO: Details: \(data.text)"
        
        view.addSubview(title)
    }
    
}
