//
//  ShareModalViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 6/21/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class ShareModalViewController: UIViewController,UITextFieldDelegate{
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex:0x595959).alpha(0.70)
        view.opaque = false
        
        let theView = UIView()
        theView.frame = CGRect(x: 15,y: 40,width: view.frame.width - 30,height: 200)
        theView.backgroundColor = UIColor.yellowColor()
        theView.layer.cornerRadius = 5
        theView.layer.masksToBounds = true
        view.addSubview(theView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
    }
    
    func keyboardWillHide(notification: NSNotification) {
    
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return true
    }
    
    
        

}
