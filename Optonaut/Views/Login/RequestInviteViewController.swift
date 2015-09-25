//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class RequestInviteViewController: UIViewController {
    
    // subviews
    let titleView = UILabel()
    let descriptionView = UILabel()
    let formView = UIView()
    let emailInputView = UITextField()
    let submitButtonView = UIButton()
    let cancelButtonView = UIButton()
    let loadingView = UIView()
    
    var formViewBottomConstraint: NSLayoutConstraint?
    var didSetConstraints = false
    
    let viewModel = RequestInviteViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.Accent
        
        titleView.text = "Be one of the first"
        titleView.textColor = .whiteColor()
        titleView.font = .robotoOfSize(18, withType: .Medium)
        view.addSubview(titleView)
        
        descriptionView.text = "Optonaut is still early stage in development and currently restricted to a limited number of users. In order to get early access please request an invite by providing your email address. We will invite you as soon possible."
        descriptionView.textColor = .whiteColor()
        descriptionView.font = .robotoOfSize(15, withType: .Light)
        descriptionView.textAlignment = .Center
        descriptionView.numberOfLines = 0
        view.addSubview(descriptionView)
        
        view.addSubview(formView)
        
        let placeholderAttributes = [
            NSFontAttributeName: UIFont.robotoOfSize(15, withType: .Regular),
            NSForegroundColorAttributeName: UIColor.whiteColor().alpha(0.8),
        ]
        
        // TODO implement feedback for wrong formatted data
        emailInputView.backgroundColor = UIColor.whiteColor().alpha(0.3)
        emailInputView.attributedPlaceholder = NSAttributedString(string:"Email", attributes: placeholderAttributes)
        emailInputView.font = .robotoOfSize(15, withType: .Regular)
        emailInputView.textColor = .whiteColor()
        emailInputView.textAlignment = .Center
        emailInputView.layer.cornerRadius = 6
        emailInputView.clipsToBounds = true
        emailInputView.autocorrectionType = .No
        emailInputView.autocapitalizationType = .None
        emailInputView.keyboardType = .EmailAddress
        emailInputView.returnKeyType = .Go
        emailInputView.delegate = self
        viewModel.email <~ emailInputView.rac_text
        formView.addSubview(emailInputView)
        
        submitButtonView.backgroundColor = UIColor(0xb5362c)
        submitButtonView.setTitle("Send Request", forState: .Normal)
        submitButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        submitButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Medium)
        submitButtonView.layer.cornerRadius = 6
        submitButtonView.layer.masksToBounds = true
        submitButtonView.rac_userInteractionEnabled <~ viewModel.emailValid
        submitButtonView.rac_alpha <~ viewModel.emailValid.producer.map { $0 ? 1 : 0.5 }
        submitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "requestInvite"))
        formView.addSubview(submitButtonView)
        
        cancelButtonView.backgroundColor = UIColor(0xb5362c)
        cancelButtonView.setTitle("Cancel", forState: .Normal)
        cancelButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        cancelButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Medium)
        cancelButtonView.layer.cornerRadius = 6
        cancelButtonView.layer.masksToBounds = true
        cancelButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showLogin"))
        formView.addSubview(cancelButtonView)
        
        loadingView.backgroundColor = UIColor.blackColor().alpha(0.3)
        loadingView.rac_hidden <~ viewModel.pending.producer.map(negate)
        view.addSubview(loadingView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func updateViewConstraints() {
        if !didSetConstraints {
            
            titleView.autoPinEdge(.Bottom, toEdge: .Top, ofView: descriptionView, withOffset: -15)
            titleView.autoAlignAxisToSuperviewAxis(.Vertical)
            
            descriptionView.autoPinEdge(.Bottom, toEdge: .Top, ofView: formView, withOffset: -36)
            descriptionView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
            descriptionView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
            
            let formBottomOffset = formBottomOffsetForKeyboardHeight(0, keyboardVisible: false)
            formViewBottomConstraint = formView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: formBottomOffset)
            formView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
            formView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
            formView.autoSetDimension(.Height, toSize: 158)
            
            emailInputView.autoSetDimension(.Height, toSize: 45)
            emailInputView.autoPinEdge(.Top, toEdge: .Top, ofView: formView)
            emailInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            emailInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
            submitButtonView.autoSetDimension(.Height, toSize: 45)
            submitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailInputView, withOffset: 16)
            submitButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            submitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
            cancelButtonView.autoSetDimension(.Height, toSize: 45)
            cancelButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: submitButtonView, withOffset: 7)
            cancelButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            cancelButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
            loadingView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
            
            didSetConstraints = true
        }
        
        super.updateViewConstraints()
    }
    
    // needed for vertically centering (respecting keyboard visiblity)
    private func formBottomOffsetForKeyboardHeight(keyboardHeight: CGFloat, keyboardVisible: Bool) -> CGFloat {
        return keyboardVisible ? -keyboardHeight - 16 : -view.bounds.height / 3 + 158 / 2
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - keyboard stuff
    func keyboardWillShowNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification, keyboardVisible: true)
    }
    
    func keyboardWillHideNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification, keyboardVisible: false)
    }
    
    func updateBottomLayoutConstraintWithNotification(notification: NSNotification, keyboardVisible: Bool) {
        let userInfo = notification.userInfo!
        
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
        let rawAnimationCurve = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedIntValue << 16
        let animationCurve = UIViewAnimationOptions.init(rawValue: UInt(rawAnimationCurve))
        let keyboardHeight = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame)
        
        formViewBottomConstraint?.constant = formBottomOffsetForKeyboardHeight(keyboardHeight, keyboardVisible: keyboardVisible)
        
        UIView.animateWithDuration(animationDuration,
            delay: 0,
            options: [.BeginFromCurrentState, animationCurve],
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func requestInvite() {
        viewModel.requestInvite()
            .on(
                error: { _ in
                    let alert = UIAlertController(title: "Something went wrong", message: "The request was unsuccessful. Maybe you've already requested an invite?", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
                    self.presentViewController(alert, animated: true, completion: nil)
                },
                completed: {
                    self.emailInputView.userInteractionEnabled = false
                    self.emailInputView.alpha = 0.5
                    self.submitButtonView.userInteractionEnabled = false
                    self.submitButtonView.alpha = 0.5
                    self.titleView.text = "Congratulations"
                    self.cancelButtonView.setTitle("Back", forState: .Normal)
                    self.descriptionView.text = "Thanks for your request. We'll be in touch soon. In order to stay up to date you can follow us on Facebook or Twitter. Cheers!"
                }
            )
            .start()
    }
    
    func showLogin() {
        presentViewController(LoginViewController(), animated: false, completion: nil)
    }
    
}

// MARK: - UITextFieldDelegate
extension RequestInviteViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == emailInputView {
            view.endEditing(true)
            submitButtonView.sendActionsForControlEvents(.TouchUpInside)
        }
        
        return true
    }
    
}
