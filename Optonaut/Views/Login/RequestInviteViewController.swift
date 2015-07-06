//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import ReactiveCocoa

class RequestInviteViewController: UIViewController {
    
    // subviews
    var logoView = UIImageView()
    let formView = UIView()
    let loginEmailOrUserNameInputView = UITextField()
    let loginPasswordInputView = UITextField()
    let loginSubmitButtonView = UIButton()
    let loginShowInviteButtonView = UILabel()
    let inviteEmailInputView = UITextField()
    let inviteSubmitButtonView = UIButton()
    let inviteAbortButtonView = UILabel()
    
    var formViewBottomConstraint: NSLayoutConstraint?
    var didSetConstraints = false
    
    let viewModel = LoginViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = baseColor()
        
        logoView.image = UIImage(named: "logo_white")
        logoView.contentMode = .ScaleAspectFit
        view.addSubview(logoView)
        
        view.addSubview(formView)
        
        let placeholderAttributes = [
            NSFontAttributeName: UIFont.robotoOfSize(15, withType: .Regular),
            NSForegroundColorAttributeName: UIColor.whiteColor().alpha(0.8),
        ]
        
        loginEmailOrUserNameInputView.backgroundColor = UIColor.whiteColor().alpha(0.3)
        loginEmailOrUserNameInputView.attributedPlaceholder = NSAttributedString(string:"Email or username", attributes: placeholderAttributes)
        loginEmailOrUserNameInputView.font = .robotoOfSize(15, withType: .Regular)
        loginEmailOrUserNameInputView.textColor = .whiteColor()
        loginEmailOrUserNameInputView.textAlignment = .Center
        loginEmailOrUserNameInputView.layer.cornerRadius = 5
        loginEmailOrUserNameInputView.clipsToBounds = true
        loginEmailOrUserNameInputView.autocorrectionType = .No
        loginEmailOrUserNameInputView.autocapitalizationType = .None
        loginEmailOrUserNameInputView.keyboardType = .EmailAddress
        loginEmailOrUserNameInputView.returnKeyType = .Next
        loginEmailOrUserNameInputView.delegate = self
        viewModel.loginEmailOrUserName <~ loginEmailOrUserNameInputView.rac_text
        formView.addSubview(loginEmailOrUserNameInputView)
        
        loginPasswordInputView.backgroundColor = UIColor.whiteColor().alpha(0.3)
        loginPasswordInputView.attributedPlaceholder = NSAttributedString(string:"Password", attributes: placeholderAttributes)
        loginPasswordInputView.font = .robotoOfSize(15, withType: .Regular)
        loginPasswordInputView.textColor = .whiteColor()
        loginPasswordInputView.textAlignment = .Center
        loginPasswordInputView.layer.cornerRadius = 5
        loginPasswordInputView.clipsToBounds = true
        loginPasswordInputView.secureTextEntry = true
        loginPasswordInputView.returnKeyType = .Go
        loginPasswordInputView.delegate = self
        //        loginPasswordInputView.rac_alpha <~ viewModel.pending.producer |> map { $0 ? CGFloat(0.5) : CGFloat(1) }
        //        loginPasswordInputView.rac_textColor <~ viewModel.loginPasswordValid.producer |> map { $0 ? .blackColor() : .redColor() }
        //        loginPasswordInputView.rac_hidden <~ viewModel.inviteFormVisible
        viewModel.loginPassword <~ loginPasswordInputView.rac_text
        formView.addSubview(loginPasswordInputView)
        
        loginSubmitButtonView.backgroundColor = .whiteColor()
        loginSubmitButtonView.setTitle("Login", forState: .Normal)
        loginSubmitButtonView.setTitleColor(baseColor(), forState: .Normal)
        loginSubmitButtonView.layer.cornerRadius = 5
        loginSubmitButtonView.layer.masksToBounds = true
        loginSubmitButtonView.rac_hidden <~ viewModel.inviteFormVisible
        loginSubmitButtonView.rac_alpha <~ viewModel.loginAllowed.producer |> map { $0 ? CGFloat(1) : CGFloat(0.5) }
        loginSubmitButtonView.rac_userInteractionEnabled <~ viewModel.loginAllowed
        loginSubmitButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.login()
                |> start(
                    error: { _ in
                        let alert = UIAlertController(title: "Login failed", message: "The entered user data was wrong. Come on...", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
                        self.presentViewController(alert, animated: true, completion: nil)
                    },
                    completed: {
                        self.presentViewController(TabBarViewController(), animated: false, completion: nil)
                })
            return RACSignal.empty()
        })
        formView.addSubview(loginSubmitButtonView)
        
        loginShowInviteButtonView.textAlignment = .Center
        loginShowInviteButtonView.textColor = .whiteColor()
        loginShowInviteButtonView.text = "Request Invite"
        loginShowInviteButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleRequest"))
        loginShowInviteButtonView.userInteractionEnabled = true
        loginShowInviteButtonView.rac_hidden <~ viewModel.inviteFormVisible
        view.addSubview(loginShowInviteButtonView)
        
        inviteAbortButtonView.textColor = UIColor.whiteColor()
        inviteAbortButtonView.font = UIFont.icomoonOfSize(40)
        inviteAbortButtonView.text = String.icomoonWithName(Icomoon.Cross)
        inviteAbortButtonView.userInteractionEnabled = true
        inviteAbortButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleRequest"))
        inviteAbortButtonView.rac_hidden <~ viewModel.inviteFormVisible.producer |> map { !$0 }
        view.addSubview(inviteAbortButtonView)
        
        inviteEmailInputView.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        inviteEmailInputView.borderStyle = .RoundedRect
        inviteEmailInputView.autocorrectionType = .No
        inviteEmailInputView.autocapitalizationType = .None
        inviteEmailInputView.keyboardType = .EmailAddress
        inviteEmailInputView.rac_textColor <~ viewModel.inviteEmailValid.producer |> map { $0 ? .blackColor() : .redColor() }
        inviteEmailInputView.rac_hidden <~ viewModel.inviteFormVisible.producer |> map { !$0 }
        viewModel.inviteEmail <~ inviteEmailInputView.rac_text
        formView.addSubview(inviteEmailInputView)
        
        inviteSubmitButtonView.backgroundColor = .whiteColor()
        inviteSubmitButtonView.setTitle("Request Invite", forState: .Normal)
        inviteSubmitButtonView.setTitleColor(baseColor(), forState: .Normal)
        inviteSubmitButtonView.userInteractionEnabled = true
        inviteSubmitButtonView.layer.cornerRadius = 5
        inviteSubmitButtonView.layer.masksToBounds = true
        inviteSubmitButtonView.rac_alpha <~ viewModel.inviteEmailValid.producer |> map { $0 ? CGFloat(1) : CGFloat(0.5) }
        inviteSubmitButtonView.rac_userInteractionEnabled <~ viewModel.inviteEmailValid
        inviteSubmitButtonView.rac_hidden <~ viewModel.inviteFormVisible.producer |> map { !$0 }
        inviteSubmitButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.requestInvite()
                |> start(
                    error: { _ in
                        println("Invite request went wrong...")
                    },
                    completed: {
                        let alert = UIAlertController(title: "Request successful", message: "We heard you and will give you access to Optonaut as soon as possible.", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in
                            self.inviteEmailInputView.text = ""
                            self.viewModel.inviteFormVisible.put(false)
                        }))
                        self.presentViewController(alert, animated: true, completion: nil)
                })
            return RACSignal.empty()
        })
        formView.addSubview(inviteSubmitButtonView)
        
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
            logoView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 0.2)
            logoView.autoMatchDimension(.Width, toDimension: .Width, ofView: view, withMultiplier: 0.2)
            logoView.autoAlignAxisToSuperviewAxis(.Vertical)
            logoView.autoPinEdge(.Bottom, toEdge: .Top, ofView: formView, withOffset: -40)
            
            formViewBottomConstraint = formView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -view.bounds.height / 2 + 190 / 2)
            formView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
            formView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
            formView.autoSetDimension(.Height, toSize: 190)
            //        formView.autoAlignAxis(ALAxis.Horizontal, toSameAxisOfView: view)
            
            loginEmailOrUserNameInputView.autoSetDimension(.Height, toSize: 60)
            loginEmailOrUserNameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: formView)
            loginEmailOrUserNameInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView, withOffset: 20)
            loginEmailOrUserNameInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView, withOffset: -20)
            
            loginPasswordInputView.autoSetDimension(.Height, toSize: 60)
            loginPasswordInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: loginEmailOrUserNameInputView, withOffset: 5)
            loginPasswordInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView, withOffset: 20)
            loginPasswordInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView, withOffset: -20)
            
            loginSubmitButtonView.autoSetDimensionsToSize(CGSize(width: 150, height: 60))
            loginSubmitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: loginPasswordInputView, withOffset: 5)
            loginSubmitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: formView, withOffset: -20)
            
            loginShowInviteButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -20)
            loginShowInviteButtonView.autoAlignAxisToSuperviewAxis(.Vertical)
            
            inviteEmailInputView.autoSetDimension(.Height, toSize: 60)
            inviteEmailInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: logoView, withOffset: 60)
            inviteEmailInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView, withOffset: 20)
            inviteEmailInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView, withOffset: -20)
            
            inviteSubmitButtonView.autoSetDimensionsToSize(CGSize(width: 150, height: 60))
            inviteSubmitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: inviteEmailInputView, withOffset: 5)
            inviteSubmitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: formView, withOffset: -20)
            
            inviteAbortButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 30)
            inviteAbortButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -30)
            
            didSetConstraints = true
        }
        
        super.updateViewConstraints()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
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
        let animationCurve = UIViewAnimationOptions.init(UInt(rawAnimationCurve))
        let keyboardHeight = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame)
        let bottomOffset = keyboardVisible ? -keyboardHeight - 20 : -view.bounds.height / 2 + 190 / 2
        
        formViewBottomConstraint?.constant = bottomOffset
        
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: .BeginFromCurrentState | animationCurve, animations: {
            self.logoView.alpha = keyboardVisible ? 0 : 1
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func toggleRequest() {
        viewModel.inviteFormVisible.put(!viewModel.inviteFormVisible.value)
    }
    
}

// MARK: - UITextFieldDelegate
extension RequestInviteViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == loginEmailOrUserNameInputView {
            loginPasswordInputView.becomeFirstResponder()
        }
        
        if textField == loginPasswordInputView {
            view.endEditing(true)
            loginSubmitButtonView.sendActionsForControlEvents(.TouchUpInside)
        }
        
        return true
    }
    
}
