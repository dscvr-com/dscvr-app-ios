//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ForgotPasswordViewController: UIViewController {
    
    // subviews
    let cancelButtonView = UIButton()
    let titleView = UILabel()
    let descriptionView = UILabel()
    let formView = UIView()
    let emailInputView = LineTextField()
    let submitButtonView = ActionButton()
    let backButtonView = ActionButton()
    let loadingView = UIView()
    
    var formViewBottomConstraint: NSLayoutConstraint?
    var didSetConstraints = false
    
    let viewModel = ForgotPasswordViewModel()
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.Accent
        
        cancelButtonView.setTitle(String.iconWithName(.Cross), forState: .Normal)
        cancelButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        cancelButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        cancelButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        view.addSubview(cancelButtonView)
        
        titleView.text = "Forgot your password?"
        titleView.textColor = .whiteColor()
        titleView.font = .displayOfSize(18, withType: .Regular)
        view.addSubview(titleView)
        
        descriptionView.text = "Don't worry. Please enter your email address and we will send you an email with a link to reset your password."
        descriptionView.textColor = .whiteColor()
        descriptionView.font = .displayOfSize(15, withType: .Thin)
        descriptionView.textAlignment = .Center
        descriptionView.numberOfLines = 0
        view.addSubview(descriptionView)
        
        view.addSubview(formView)
        
        // TODO implement feedback for wrong formatted data
        emailInputView.placeholder = "Email address"
        emailInputView.size = .Medium
        emailInputView.color = .Light
        emailInputView.autocorrectionType = .No
        emailInputView.autocapitalizationType = .None
        emailInputView.keyboardType = .EmailAddress
        emailInputView.returnKeyType = .Go
        emailInputView.delegate = self
        emailInputView.rac_status <~ viewModel.emailStatus
        emailInputView.rac_hidden <~ viewModel.sent
        viewModel.email <~ emailInputView.rac_text
        formView.addSubview(emailInputView)
        
        submitButtonView.setTitle(String.iconWithName(.Check), forState: .Normal)
        submitButtonView.setTitleColor(.Accent, forState: .Normal)
        submitButtonView.defaultBackgroundColor = .whiteColor()
        submitButtonView.titleLabel?.font = UIFont.iconOfSize(28)
        submitButtonView.layer.cornerRadius = 30
        submitButtonView.rac_userInteractionEnabled <~ viewModel.emailStatus.producer.equalsTo(.Normal)
        submitButtonView.rac_alpha <~ viewModel.emailStatus.producer.equalsTo(.Normal).map { $0 ? 1 : 0.2 }
        submitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "sendEmail"))
        submitButtonView.rac_loading <~ viewModel.pending
        submitButtonView.rac_hidden <~ viewModel.sent
        formView.addSubview(submitButtonView)
        
        backButtonView.setTitle("Back", forState: .Normal)
        backButtonView.setTitleColor(.Accent, forState: .Normal)
        backButtonView.defaultBackgroundColor = .whiteColor()
        backButtonView.rac_hidden <~ viewModel.sent.producer.map(negate)
        backButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        formView.addSubview(backButtonView)
        
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
            
            cancelButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 30)
            cancelButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 20)
            
            titleView.autoPinEdge(.Bottom, toEdge: .Top, ofView: descriptionView, withOffset: -15)
            titleView.autoAlignAxisToSuperviewAxis(.Vertical)
            
            descriptionView.autoPinEdge(.Bottom, toEdge: .Top, ofView: formView, withOffset: -70)
            descriptionView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 30)
            descriptionView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -30)
            
            let formBottomOffset = formBottomOffsetForKeyboardHeight(0, keyboardVisible: false)
            formViewBottomConstraint = formView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: formBottomOffset)
            formView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
            formView.autoSetDimension(.Width, toSize: 243)
            formView.autoSetDimension(.Height, toSize: 115)
            
            emailInputView.autoPinEdge(.Top, toEdge: .Top, ofView: formView)
            emailInputView.autoPinEdge(.Left, toEdge: .Left, ofView: formView)
            emailInputView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            
            submitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailInputView, withOffset: 30)
            submitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: formView)
            submitButtonView.autoSetDimension(.Width, toSize: 60)
            submitButtonView.autoSetDimension(.Height, toSize: 60)
            
            backButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: formView)
            backButtonView.autoAlignAxisToSuperviewAxis(.Vertical)
            backButtonView.autoSetDimension(.Width, toSize: 160)
            backButtonView.autoSetDimension(.Height, toSize: 60)
            
            loadingView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
            
            didSetConstraints = true
        }
        
        super.updateViewConstraints()
    }
    
    // needed for vertically centering (respecting keyboard visiblity)
    private func formBottomOffsetForKeyboardHeight(keyboardHeight: CGFloat, keyboardVisible: Bool) -> CGFloat {
        return keyboardVisible ? -keyboardHeight - 16 : -view.bounds.height / 2.5 + 115 / 2
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
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: [.BeginFromCurrentState, animationCurve],
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func sendEmail() {
        viewModel.sendEmail()
            .on(
                error: { [weak self] _ in
                    self?.viewModel.emailStatus.value = .Warning("We couldn't find that email address...")
                    
                },
                completed: { [weak self] in
                    self?.titleView.text = "Check your inbox"
                    self?.descriptionView.text = "We sent you an email with a link to reset your password by choosing a new one."
                }
            )
            .start()
    }
    
    func cancel() {
        view.window?.rootViewController = LoginViewController()
    }
    
}

// MARK: - UITextFieldDelegate
extension ForgotPasswordViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == emailInputView {
            view.endEditing(true)
            sendEmail()
        }
        
        return true
    }
    
}
