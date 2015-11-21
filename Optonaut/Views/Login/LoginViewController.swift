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
import Mixpanel

class LoginViewController: UIViewController {
    
    // subviews
    let logoView = UILabel()
    let formView = UIView()
    let emailOrUserNameInputView = LineTextField()
    let passwordInputView = LineTextField()
    let submitButtonView = ActionButton()
    let forgotPasswordView = UILabel()
    let signupTextView = UILabel()
    let signupHelpTextView = UILabel()
    let loadingView = UIView()
    let skipTextView = UILabel()
    
    var formViewBottomConstraint: NSLayoutConstraint?
    var didSetConstraints = false
    
    let viewModel = LoginViewModel()
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.Accent
        
        logoView.text = String.iconWithName(.LogoText)
        logoView.textColor = .whiteColor()
        logoView.font = UIFont.iconOfSize(35)
        view.addSubview(logoView)
        
        skipTextView.textColor = .whiteColor()
        skipTextView.text = "Skip"
        skipTextView.font = .displayOfSize(14, withType: .Semibold)
        skipTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "skip"))
        skipTextView.userInteractionEnabled = true
        view.addSubview(skipTextView)
        
        view.addSubview(formView)
        
        emailOrUserNameInputView.placeholder = "Email address or username"
        emailOrUserNameInputView.size = .Medium
        emailOrUserNameInputView.color = .Light
        emailOrUserNameInputView.autocorrectionType = .No
        emailOrUserNameInputView.autocapitalizationType = .None
        emailOrUserNameInputView.keyboardType = .EmailAddress
        emailOrUserNameInputView.returnKeyType = .Next
        emailOrUserNameInputView.delegate = self
        emailOrUserNameInputView.rac_status <~ viewModel.emailOrUserNameStatus
        viewModel.emailOrUserName <~ emailOrUserNameInputView.rac_text
        formView.addSubview(emailOrUserNameInputView)
        
        passwordInputView.placeholder = "Password"
        passwordInputView.size = .Medium
        passwordInputView.color = .Light
        passwordInputView.secureTextEntry = true
        passwordInputView.returnKeyType = .Go
        passwordInputView.delegate = self
        passwordInputView.rac_status <~ viewModel.passwordStatus
        viewModel.password <~ passwordInputView.rac_text
        formView.addSubview(passwordInputView)
        
        forgotPasswordView.textColor = .whiteColor()
        forgotPasswordView.text = "Forgot?"
        forgotPasswordView.font = .displayOfSize(13, withType: .Semibold)
        forgotPasswordView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showForgotPasswordViewController"))
        forgotPasswordView.userInteractionEnabled = true
        forgotPasswordView.rac_userInteractionEnabled <~ viewModel.passwordStatus.producer.equalsTo(.Disabled).map(negate)
        forgotPasswordView.rac_alpha <~ viewModel.passwordStatus.producer.equalsTo(.Disabled).map { $0 ? 0.15 : 1 }
        view.addSubview(forgotPasswordView)
        
        submitButtonView.setTitle(String.iconWithName(.Check), forState: .Normal)
        submitButtonView.setTitleColor(.Accent, forState: .Normal)
        submitButtonView.defaultBackgroundColor = .whiteColor()
        submitButtonView.titleLabel?.font = UIFont.iconOfSize(28)
        submitButtonView.layer.cornerRadius = 30
        submitButtonView.rac_userInteractionEnabled <~ viewModel.allowed
        submitButtonView.rac_alpha <~ viewModel.allowed.producer.map { $0 ? 1 : 0.2 }
        submitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "login"))
        submitButtonView.rac_loading <~ viewModel.pending
        formView.addSubview(submitButtonView)
        
        signupHelpTextView.textColor = .whiteColor()
        signupHelpTextView.text = "Don't have an account yet?"
        signupHelpTextView.font = .displayOfSize(14, withType: .Thin)
        view.addSubview(signupHelpTextView)
        
        signupTextView.textColor = .whiteColor()
        signupTextView.text = "Sign up"
        signupTextView.font = .displayOfSize(18, withType: .Semibold)
        signupTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showSignup"))
        signupTextView.userInteractionEnabled = true
        view.addSubview(signupTextView)
        
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
        
        Mixpanel.sharedInstance().timeEvent("View.Login")
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Login")
    }
    
    override func updateViewConstraints() {
        if !didSetConstraints {
            
            skipTextView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 50)
            skipTextView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -30)
            
            logoView.autoAlignAxisToSuperviewAxis(.Vertical)
            logoView.autoPinEdge(.Bottom, toEdge: .Top, ofView: formView, withOffset: -100)
            
            let formBottomOffset = formBottomOffsetForKeyboardHeight(0, keyboardVisible: false)
            formViewBottomConstraint = formView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: formBottomOffset)
            formView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
            formView.autoSetDimension(.Width, toSize: 243)
            formView.autoSetDimension(.Height, toSize: 158)
            
            emailOrUserNameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: formView)
            emailOrUserNameInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            emailOrUserNameInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
            passwordInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailOrUserNameInputView, withOffset: 35)
            passwordInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            passwordInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
            forgotPasswordView.autoPinEdge(.Right, toEdge: .Right, ofView: passwordInputView, withOffset: 0)
            forgotPasswordView.autoAlignAxis(.Horizontal, toSameAxisOfView: passwordInputView)
            
            submitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordInputView, withOffset: 30)
            submitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            submitButtonView.autoSetDimension(.Width, toSize: 60)
            submitButtonView.autoSetDimension(.Height, toSize: 60)
            
            signupHelpTextView.autoPinEdge(.Bottom, toEdge: .Top, ofView: signupTextView, withOffset: -5)
            signupHelpTextView.autoAlignAxisToSuperviewAxis(.Vertical)
            
            signupTextView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -36)
            signupTextView.autoAlignAxisToSuperviewAxis(.Vertical)
            
            loadingView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
            
            didSetConstraints = true
        }
        
        super.updateViewConstraints()
    }
    
    // needed for vertically centering (respecting keyboard visiblity)
    private func formBottomOffsetForKeyboardHeight(keyboardHeight: CGFloat, keyboardVisible: Bool) -> CGFloat {
        return keyboardVisible ? -keyboardHeight - 16 : -view.bounds.height / 2 + 158 / 2 + 52
    }
    
    func showSignup() {
        presentViewController(OnboardingInfoViewController(), animated: false, completion: nil)
    }
    
    func showForgotPasswordViewController() {
        presentViewController(ForgotPasswordViewController(), animated: false, completion: nil)
    }
    
    func skip() {
        presentViewController(TabBarViewController(), animated: false, completion: nil)
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