//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let add = UIButton(frame: view.frame)
        add.setTitle("Add temporary", forState: .Normal)
        add.setTitleColor(UIColor.blackColor(), forState: .Normal)
        add.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tmpAdd"))
        view.addSubview(add)
    }
    
    func tmpAdd() {
        var alert = UIAlertController(title: "Add Optograph", message: "This is just temporary", preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.text = "Some default text."
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let textField = alert.textFields![0] as! UITextField
            let parameters = [
                "text": textField.text,
                "location": [
                    "latitude": 12,
                    "longitude": 34,
                ]
            ]
            Api.post("optographs", authorized: true, parameters: parameters as? [String : AnyObject]).start()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
