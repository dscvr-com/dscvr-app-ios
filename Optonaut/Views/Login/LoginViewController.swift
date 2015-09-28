//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async

class LoginViewController: UIViewController {
    
    // subviews
    let logoView = UILabel()
    let formView = UIView()
    let emailOrUserNameInputView = UITextField()
    let passwordInputView = UITextField()
    let submitButtonView = UIButton()
//    let forgotPasswordView = UILabel()
    let showInviteView = UILabel()
    let loadingView = UIView()
    
    var formViewBottomConstraint: NSLayoutConstraint?
    var didSetConstraints = false
    
    let viewModel = LoginViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.Accent
        
        logoView.text = String.icomoonWithName(.LogoText)
        logoView.textColor = .whiteColor()
        logoView.font = UIFont.icomoonOfSize(60)
        view.addSubview(logoView)
        
        view.addSubview(formView)
        
        let placeholderAttributes = [
            NSFontAttributeName: UIFont.robotoOfSize(15, withType: .Regular),
            NSForegroundColorAttributeName: UIColor.whiteColor().alpha(0.8),
        ]
        
        // TODO implement feedback for wrong formatted data
        emailOrUserNameInputView.backgroundColor = UIColor.whiteColor().alpha(0.3)
        emailOrUserNameInputView.attributedPlaceholder = NSAttributedString(string:"Email or username", attributes: placeholderAttributes)
        emailOrUserNameInputView.font = .robotoOfSize(15, withType: .Regular)
        emailOrUserNameInputView.textColor = .whiteColor()
        emailOrUserNameInputView.textAlignment = .Center
        emailOrUserNameInputView.layer.cornerRadius = 5
        emailOrUserNameInputView.clipsToBounds = true
        emailOrUserNameInputView.autocorrectionType = .No
        emailOrUserNameInputView.autocapitalizationType = .None
        emailOrUserNameInputView.keyboardType = .EmailAddress
        emailOrUserNameInputView.returnKeyType = .Next
        emailOrUserNameInputView.delegate = self
        viewModel.emailOrUserName <~ emailOrUserNameInputView.rac_text
        formView.addSubview(emailOrUserNameInputView)
        
        passwordInputView.backgroundColor = UIColor.whiteColor().alpha(0.3)
        passwordInputView.attributedPlaceholder = NSAttributedString(string:"Password", attributes: placeholderAttributes)
        passwordInputView.font = .robotoOfSize(15, withType: .Regular)
        passwordInputView.textColor = .whiteColor()
        passwordInputView.textAlignment = .Center
        passwordInputView.layer.cornerRadius = 5
        passwordInputView.clipsToBounds = true
        passwordInputView.secureTextEntry = true
        passwordInputView.returnKeyType = .Go
        passwordInputView.delegate = self
        viewModel.password <~ passwordInputView.rac_text
        formView.addSubview(passwordInputView)
        
        submitButtonView.backgroundColor = UIColor(0xb5362c)
        submitButtonView.setTitle("Login", forState: .Normal)
        submitButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        submitButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Medium)
        submitButtonView.layer.cornerRadius = 5
        submitButtonView.layer.masksToBounds = true
        submitButtonView.rac_userInteractionEnabled <~ viewModel.allowed
        submitButtonView.rac_alpha <~ viewModel.allowed.producer.map { $0 ? 1 : 0.5 }
        submitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "login"))
        formView.addSubview(submitButtonView)
        
//        forgotPasswordView.textColor = .whiteColor()
//        forgotPasswordView.text = "Forgot your password?"
//        forgotPasswordView.font = .robotoOfSize(13, withType: .Regular)
//        forgotPasswordView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showForgotPasswordViewController"))
//        forgotPasswordView.userInteractionEnabled = true
//        view.addSubview(forgotPasswordView)
        
        showInviteView.textColor = .whiteColor()
        showInviteView.text = "Request Invite"
        showInviteView.font = .robotoOfSize(15, withType: .Regular)
        showInviteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showRequestInviteViewController"))
        showInviteView.userInteractionEnabled = true
        view.addSubview(showInviteView)
        
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
    
    override func viewDidAppear(animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func updateViewConstraints() {
        if !didSetConstraints {
            logoView.autoAlignAxisToSuperviewAxis(.Vertical)
            logoView.autoPinEdge(.Bottom, toEdge: .Top, ofView: formView, withOffset: -40)
            
            let formBottomOffset = formBottomOffsetForKeyboardHeight(0, keyboardVisible: false)
            formViewBottomConstraint = formView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: formBottomOffset)
            formView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
            formView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
            formView.autoSetDimension(.Height, toSize: 158)
            
            emailOrUserNameInputView.autoSetDimension(.Height, toSize: 45)
            emailOrUserNameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: formView)
            emailOrUserNameInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            emailOrUserNameInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
            passwordInputView.autoSetDimension(.Height, toSize: 45)
            passwordInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailOrUserNameInputView, withOffset: 7)
            passwordInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            passwordInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
            submitButtonView.autoSetDimension(.Height, toSize: 45)
            submitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordInputView, withOffset: 16)
            submitButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            submitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
//            forgotPasswordView.autoPinEdge(.Top, toEdge: .Bottom, ofView: formView, withOffset: 23)
//            forgotPasswordView.autoAlignAxisToSuperviewAxis(.Vertical)
            
            showInviteView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -28)
            showInviteView.autoAlignAxisToSuperviewAxis(.Vertical)
            
            loadingView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
            
            didSetConstraints = true
        }
        
        super.updateViewConstraints()
    }
    
    // needed for vertically centering (respecting keyboard visiblity)
    private func formBottomOffsetForKeyboardHeight(keyboardHeight: CGFloat, keyboardVisible: Bool) -> CGFloat {
        return keyboardVisible ? -keyboardHeight - 16 : -view.bounds.height / 2 + 158 / 2
    }
    
    func showRequestInviteViewController() {
        presentViewController(RequestInviteViewController(), animated: false, completion: nil)
    }
    
    func showForgotPasswordViewController() {
        presentViewController(ForgotPasswordViewController(), animated: false, completion: nil)
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
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
        let keyboardHeight = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame)
        let rawAnimationCurve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedIntValue << 16
        let animationCurve = UIViewAnimationOptions.init(rawValue: UInt(rawAnimationCurve))
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
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
    
    func login() {
        viewModel.login()
            .on(
                error: { _ in 
                    let alert = UIAlertController(title: "Login unsuccessful", message: "Your entered data wasn't correct. Please try again.", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
                    self.presentViewController(alert, animated: true, completion: nil)
                }, 
                completed: {
                    if SessionService.needsOnboarding {
                        self.presentViewController(OnboardingInfoViewController(), animated: false, completion: nil)
                    } else {
                        self.presentViewController(TabBarViewController(), animated: false, completion: nil)
                    }
                }
            )
            .start()
    }
    
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailOrUserNameInputView {
            passwordInputView.becomeFirstResponder()
        }
        
        if textField == passwordInputView {
            view.endEditing(true)
            Async.main {
                self.login()
            }
        }
        
        return true
    }
    
}