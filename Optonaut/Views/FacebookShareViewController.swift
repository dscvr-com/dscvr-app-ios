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
    var labelTitle = UILabel()
    var labelLine = UILabel()
    var labelFacebook = UILabel()
    var buttonViews = UIView()
    var optographId:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.backgroundColor = UIColor(hex:0x595959).alpha(0.70)
        
        
        theView.backgroundColor = UIColor.whiteColor()
        theView.layer.cornerRadius = 8
        theView.clipsToBounds = true
        view.addSubview(theView)
        
        buttonViews.backgroundColor = UIColor.whiteColor()
        theView.addSubview(buttonViews)
        
        buttonCancel.setTitle("CANCEL", forState: .Normal)
        buttonCancel.titleLabel!.font =  UIFont(name: "Helvetica", size: 12)
        buttonCancel.backgroundColor = UIColor.whiteColor()
        buttonCancel.contentEdgeInsets = UIEdgeInsetsMake(0, -25, 0, 0)
        buttonCancel.setTitleColor(UIColor.grayColor(), forState: .Normal)
        buttonCancel.addTarget(self,action: #selector(dismissPage),forControlEvents: .TouchUpInside)
        buttonViews.addSubview(buttonCancel)
        
        labelFacebook.text = "Facebook"
        labelFacebook.textColor = UIColor.blackColor()
        labelFacebook.font = UIFont.boldSystemFontOfSize(18.0)
        labelFacebook.textAlignment = .Center
        buttonViews.addSubview(labelFacebook)
        
        buttonPost.setTitle("POST", forState: .Normal)
        buttonPost.titleLabel!.font =  UIFont(name: "Helvetica", size: 12)
        buttonPost.backgroundColor = UIColor.whiteColor()
        buttonPost.setTitleColor(UIColor(hex:0x0076FF), forState: .Normal)
        buttonPost.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -25)
        buttonPost.addTarget(self,action: #selector(postFb),forControlEvents: .TouchUpInside)
        buttonViews.addSubview(buttonPost)
        
        labelLine.backgroundColor = UIColor.grayColor()
        theView.addSubview(labelLine)
        
        labelTitle.text = "Say something about this 360 photo"
        labelTitle.textAlignment = .Center
        theView.addSubview(labelTitle)
        
        textField.backgroundColor = UIColor.grayColor()
        textField.textColor = UIColor.blackColor()
        let placeholder = NSAttributedString(string: "Check out this amazing scene in virtual reality", attributes: [NSForegroundColorAttributeName : UIColor.blackColor()])
        textField.attributedText = placeholder
        textField.becomeFirstResponder()
        theView.addSubview(textField)
        
        buttonViews.anchorInCorner(.TopLeft, xPad: 0, yPad: 10, width: view.frame.width-20, height: 20)
        buttonCancel.anchorToEdge(.Left, padding: 0, width: 100, height: 20)
        buttonPost.anchorToEdge(.Right, padding: 0, width: 100, height: 20)
        labelFacebook.alignBetweenHorizontal(align: .ToTheRightMatchingTop, primaryView: buttonCancel, secondaryView: buttonPost, padding: 10, height: 20)
        
        labelLine.align(.UnderMatchingLeft, relativeTo: buttonViews, padding: 10, width: view.frame.width - 20, height: 1)
        labelTitle.align(.UnderCentered, relativeTo: labelLine, padding: 10, width: view.frame.width - 20, height: 30)
        textField.align(.UnderCentered, relativeTo: labelTitle, padding: 10, width: view.frame.width - 40, height: 100)
        
        

        // Do any additional setup after loading the view.
    }
    
    func dismissPage() {
        self.dismissViewControllerAnimated(true,completion: nil)
    }
    func postFb() {
        
        let parameters = [
            "optograph_id": optographId,
            "caption": textField.text == "" ? "Check out this amazing scene in virtual reality":textField.text
        ]
        print(parameters)
        
        ApiService<EmptyResponse>.post("optographs/share_facebook", parameters: parameters)
            .on(
                completed: {
                    print("success")
                    let alert = UIAlertController(title: "", message: "Posted Successfully.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { val in
                        self.dismissPage()
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                },
                failed: { _ in
                    let alert = UIAlertController(title: "", message: "Posting Failed.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {val in
                        self.dismissPage()
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                }
            )
            .start()
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
