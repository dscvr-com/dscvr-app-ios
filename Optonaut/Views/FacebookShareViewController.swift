//
//  FacebookShareViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 6/29/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class FacebookShareViewController: UIViewController,UITextFieldDelegate {
    
    var theView = UIView()
    var buttonCancel = UIButton()
    var buttonPost = UIButton()
    var textField = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.backgroundColor = UIColor(hex:0x595959).alpha(0.60)
        view.addSubview(theView)
        
        theView.backgroundColor = UIColor.whiteColor()
        
        buttonCancel.setTitle("CANCEL", forState: .Normal)
        buttonCancel.backgroundColor = UIColor.whiteColor()
        buttonCancel.setTitleColor(UIColor.grayColor(), forState: .Normal)
        buttonCancel.addTarget(self,action: #selector(dismissPage),forControlEvents: .TouchUpInside)
        
        buttonPost.setTitle("POST", forState: .Normal)
        buttonPost.backgroundColor = UIColor.whiteColor()
        buttonPost.setTitleColor(UIColor.blueColor(), forState: .Normal)
        buttonPost.addTarget(self,action: #selector(dismissPage),forControlEvents: .TouchUpInside)
        
        buttonCancel.anchorInCorner(.TopLeft, xPad: 10, yPad: 10, width: 100, height: 20)
        buttonPost.anchorInCorner(.TopRight, xPad: 10, yPad: 10, width: 100, height: 20)
        
        theView.addSubview(buttonCancel)
        theView.addSubview(buttonPost)
        theView.addSubview(textField)
        
        textField.becomeFirstResponder()

        // Do any additional setup after loading the view.
    }
    
    func dismissPage() {
        self.dismissViewControllerAnimated(true,completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        
        let viewHeight = (view.frame.height - keyboardHeight) * 0.5
        let paddingHeight = ((view.frame.height - keyboardHeight) - viewHeight) / 2
        
        theView.anchorToEdge(.Top, padding: paddingHeight, width: view.frame.width - 20, height: viewHeight)
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
