//
//  OnboardingAccountViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Async
import Mixpanel

class OnboardingAccountViewController: UIViewController, UINavigationControllerDelegate {
    
    private let viewModel = OnboardingAccountViewModel()
    
    // subviews
    private let scrollView = UIScrollView()
    private let headlineTextView = UILabel()
    private let iconView = UILabel()
    private let emailInputView = LineTextField()
    private let passwordInputView = LineTextField()
    private let termsView = UILabel()
    private let nextButtonView = ActionButton()
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .Accent
    
        headlineTextView.rac_text <~ viewModel.nextStep.producer
            .map { state in
                switch state {
                case .Email: return "Let's setup your account"
                case .Password: return "Please choose a password"
                case .Done: return "That was easy, right?"
                }
            }
        
        headlineTextView.numberOfLines = 1
        headlineTextView.textAlignment = .Center
        headlineTextView.textColor = .whiteColor()
        headlineTextView.font = UIFont.displayOfSize(25, withType: .Thin)
        view.addSubview(headlineTextView)
        
        iconView.textAlignment = .Center
        iconView.text = String.iconWithName(.Rocket)
        iconView.textColor = .whiteColor()
        iconView.font = UIFont.iconOfSize(110)
        view.addSubview(iconView)
        
        emailInputView.size = .Large
        emailInputView.color = .Light
        emailInputView.placeholder = "Email address"
        emailInputView.returnKeyType = .Next
        emailInputView.autocorrectionType = .No
        emailInputView.autocapitalizationType = .None
        emailInputView.keyboardType = .EmailAddress
        emailInputView.delegate = self
        emailInputView.rac_status <~ viewModel.emailStatus
        emailInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.email.value = $0 as! String }
        view.addSubview(emailInputView)
        
        passwordInputView.size = .Large
        passwordInputView.color = .Light
        passwordInputView.placeholder = "Pick a password"
        passwordInputView.returnKeyType = .Done
        passwordInputView.secureTextEntry = true
        passwordInputView.delegate = self
        passwordInputView.rac_status <~ viewModel.passwordStatus
        passwordInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.password.value = $0 as! String }
        view.addSubview(passwordInputView)
        
        let termsTextStr = "By creating your account you accept\r\nour terms and conditions"
        let normalRange = termsTextStr.NSRangeOfString("By creating your account you accept")
        let linkRange = termsTextStr.NSRangeOfString("our terms and conditions")
        let attrString = NSMutableAttributedString(string: termsTextStr)
        attrString.addAttribute(NSFontAttributeName, value: UIFont.displayOfSize(12, withType: .Thin), range: normalRange!)
        attrString.addAttribute(NSFontAttributeName, value: UIFont.displayOfSize(12, withType: .Semibold), range: linkRange!)
        termsView.attributedText = attrString
        termsView.textColor = .whiteColor()
        termsView.numberOfLines = 2
        termsView.textAlignment = .Center
        termsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "openTerms"))
        view.addSubview(termsView)
        
        viewModel.nextStep.producer
            .startWithNext { state in
                if case .Done = state {
                    self.termsView.alpha = 1
                    self.nextButtonView.alpha = 1
                    self.termsView.userInteractionEnabled = true
                    self.nextButtonView.userInteractionEnabled = true
                } else {
                    self.termsView.alpha = 0.2
                    self.nextButtonView.alpha = 0.2
                    self.termsView.userInteractionEnabled = false
                    self.nextButtonView.userInteractionEnabled = false
                }
            }
        
        nextButtonView.rac_loading <~ viewModel.loading
        nextButtonView.setTitle("Create account", forState: .Normal)
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showHashtagOnboarding"))
        view.addSubview(nextButtonView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        headlineTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        headlineTextView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 75)
        headlineTextView.autoSetDimension(.Width, toSize: 300)
        
        iconView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        iconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: headlineTextView, withOffset: 60)
        
        emailInputView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        emailInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: iconView, withOffset: 40)
        emailInputView.autoSetDimension(.Width, toSize: 240)
        
        passwordInputView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        passwordInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailInputView, withOffset: 40)
        passwordInputView.autoSetDimension(.Width, toSize: 240)
        
        termsView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        termsView.autoPinEdge(.Bottom, toEdge: .Top, ofView: nextButtonView, withOffset: -15)
        termsView.autoSetDimension(.Width, toSize: 300)
        
        nextButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        nextButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -42)
        nextButtonView.autoSetDimension(.Height, toSize: 60)
        nextButtonView.autoSetDimension(.Width, toSize: 223)
        
        super.updateViewConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OnboardingAccount")
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.OnboardingAccount")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        view.frame.origin.y = -keyboardHeight + 120
    }
    
    func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func openTerms() {
        UIApplication.sharedApplication().openURL(NSURL(string:"http://optonaut.co/terms/")!)
    }
    
    func showHashtagOnboarding() {
        viewModel.createAccount()
            .on(
                error: { _ in
                    let confirmAlert = UIAlertController(title: "Email address taken", message: "Whoops. This email address is already taken. Maybe you already have an account?", preferredStyle: .Alert)
                    confirmAlert.addAction(UIAlertAction(title: "Try again", style: .Default, handler: { _ in
                        self.emailInputView.text = ""
                        self.emailInputView.becomeFirstResponder()
                    }))
                    confirmAlert.addAction(UIAlertAction(title: "Login with existing account", style: .Cancel, handler: { _ in
                        self.presentViewController(LoginViewController(), animated: false, completion: nil)
                    }))
                    self.presentViewController(confirmAlert, animated: true, completion: nil)
                },
                completed: {
                    self.presentViewController(OnboardingProfileViewController(), animated: false, completion: nil)
                }
            )
            .start()
        
    }
    
}

// MARK: - UITextFieldDelegate
extension OnboardingAccountViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailInputView {
            Async.main {
                self.passwordInputView.becomeFirstResponder()
            }
        }
        
        if textField == passwordInputView {
            view.endEditing(true)
        }
        
        return true
    }
    
}