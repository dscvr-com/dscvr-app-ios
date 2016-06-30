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
    
    var loadingView = UIView()
    var container = UIView()
    var actInd = UIActivityIndicatorView()

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
        
        textField.backgroundColor = UIColor(hex:0xCACACA)
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
        
        showActivityIndicatory(view)
    }
    
    func showActivityIndicatory(uiView: UIView) {
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColor(hex:0xffffff).alpha(0.30)
        
        loadingView.frame = CGRectMake(0, 0, 80, 80)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(hex:0x444444).alpha(0.70)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        actInd.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.WhiteLarge
        actInd.center = CGPointMake(loadingView.frame.size.width / 2,
                                    loadingView.frame.size.height / 2);
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        
        self.loadingView.hidden = true
        self.container.hidden = true
        self.actInd.stopAnimating()
        
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
                    self.loadingView.hidden = true
                    self.container.hidden = true
                    self.actInd.stopAnimating()
                    let alert = UIAlertController(title: "", message: "Posted Successfully.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { val in
                        self.dismissPage()
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                },
                failed: { _ in
                    self.loadingView.hidden = true
                    self.container.hidden = true
                    self.actInd.stopAnimating()
                    let alert = UIAlertController(title: "", message: "Posting Failed.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {val in
                        self.dismissPage()
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                },started: { _ in
                    self.loadingView.hidden = false
                    self.container.hidden = false
                    self.actInd.startAnimating()
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
