//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {
    
    var viewModel: OptographViewModel!
    
    required init(viewModel: OptographViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        navigationItem.title = "Details"
        
        
//        previewImageView.rac_image <~ viewModel.imageUrl.producer |> map { name in UIImage(named: name) }
        
        let title = UILabel(frame: view.frame)
        title.text = "TODO: Details: \(viewModel.imageUrl.value)"
        
        view.addSubview(title)
    }
    
}
