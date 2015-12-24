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
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    // subviews
    private let headView = UIView()
    private let skipTextView = BoundingLabel()
    private let logoView = UILabel()
    private let signupTabView = BoundingLabel()
    private let loginTabView = BoundingLabel()
    private let emailOrUserNameInputView = LineTextField()
    private let passwordInputView = LineTextField()
    private let submitButtonView = ActionButton()
    private let forgotPasswordView = UILabel()
    private let signupTextView = UILabel()
    private let signupHelpTextView = UILabel()
    private let loadingView = UIView()
    private let facebookButtonView = ActionButton()
    
    private let viewModel = LoginViewModel()
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        headView.backgroundColor = .Accent
        view.addSubview(headView)
        
        skipTextView.textColor = .whiteColor()
        skipTextView.textAlignment = .Right
        skipTextView.text = "Try app without login"
        skipTextView.font = .displayOfSize(14, withType: .Thin)
        skipTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showApp"))
        skipTextView.userInteractionEnabled = true
        headView.addSubview(skipTextView)
        
        logoView.text = String.iconWithName(.LogoText)
        logoView.textAlignment = .Center
        logoView.textColor = .whiteColor()
        logoView.font = UIFont.iconOfSize(35)
        headView.addSubview(logoView)
        
        signupTabView.textColor = .whiteColor()
        signupTabView.textAlignment = .Center
        signupTabView.text = "SIGN UP"
        signupTabView.font = .displayOfSize(14, withType: .Semibold)
        signupTabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectSignUpTab"))
        signupTabView.userInteractionEnabled = true
        signupTabView.rac_alpha <~ viewModel.selectedTab.producer.equalsTo(.SignUp).mapToTuple(1, 0.5)
        headView.addSubview(signupTabView)
        
        loginTabView.textColor = .whiteColor()
        loginTabView.textAlignment = .Center
        loginTabView.text = "LOG IN"
        loginTabView.font = .displayOfSize(14, withType: .Semibold)
        loginTabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectLogInTab"))
        loginTabView.userInteractionEnabled = true
        loginTabView.rac_alpha <~ viewModel.selectedTab.producer.equalsTo(.LogIn).mapToTuple(1, 0.5)
        headView.addSubview(loginTabView)
        
        emailOrUserNameInputView.rac_placeholder <~ viewModel.selectedTab.producer.equalsTo(.SignUp).mapToTuple("Email address", "Email address or username")
        emailOrUserNameInputView.size = .Medium
        emailOrUserNameInputView.color = .Dark
        emailOrUserNameInputView.autocorrectionType = .No
        emailOrUserNameInputView.autocapitalizationType = .None
        emailOrUserNameInputView.keyboardType = .EmailAddress
        emailOrUserNameInputView.returnKeyType = .Next
        emailOrUserNameInputView.delegate = self
        emailOrUserNameInputView.rac_status <~ viewModel.emailOrUserNameStatus
        viewModel.emailOrUserName <~ emailOrUserNameInputView.rac_text
        view.addSubview(emailOrUserNameInputView)
        
        passwordInputView.rac_placeholder <~ viewModel.selectedTab.producer.equalsTo(.SignUp).mapToTuple("Choose a password", "Password")
        passwordInputView.size = .Medium
        passwordInputView.color = .Dark
        passwordInputView.secureTextEntry = true
        passwordInputView.returnKeyType = .Go
        passwordInputView.delegate = self
        passwordInputView.rac_status <~ viewModel.passwordStatus
        viewModel.password <~ passwordInputView.rac_text
        view.addSubview(passwordInputView)
        
        forgotPasswordView.textColor = .Accent
        forgotPasswordView.textAlignment = .Right
        forgotPasswordView.text = "Forgot?"
        forgotPasswordView.font = .displayOfSize(13, withType: .Regular)
        forgotPasswordView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showForgotPasswordViewController"))
        forgotPasswordView.userInteractionEnabled = true
        forgotPasswordView.rac_hidden <~ viewModel.selectedTab.producer.equalsTo(.SignUp)
            .combineLatestWith(viewModel.password.producer.map(isNotEmpty)).map(or)
        view.addSubview(forgotPasswordView)
        
        submitButtonView.setTitle(String.iconWithName(.Send), forState: .Normal)
        submitButtonView.setTitleColor(.Accent, forState: .Normal)
        submitButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        submitButtonView.titleLabel?.textAlignment = .Right
        submitButtonView.rac_userInteractionEnabled <~ viewModel.allowed
        submitButtonView.rac_hidden <~ viewModel.allowed.producer.map(negate)
        submitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "submit"))
        submitButtonView.rac_loading <~ viewModel.pending
        submitButtonView.defaultBackgroundColor = .clearColor()
        submitButtonView.activeBackgroundColor = .clearColor()
        submitButtonView.disabledBackgroundColor = .clearColor()
        submitButtonView.layer.cornerRadius = 0
        view.addSubview(submitButtonView)
        
        signupHelpTextView.textColor = .Accent
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
        
        facebookButtonView.defaultBackgroundColor = UIColor(0x3C5193)
        facebookButtonView.activeBackgroundColor = UIColor(0x405BB0)
        facebookButtonView.disabledBackgroundColor = UIColor(0x405BB0)
        facebookButtonView.titleLabel?.font = UIFont.displayOfSize(14, withType: .Semibold)
        facebookButtonView.rac_title <~ viewModel.selectedTab.producer.equalsTo(.SignUp).mapToTuple("Sign up with Facebook", "Log in with Facebook")
        facebookButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        facebookButtonView.layer.cornerRadius = 4
        facebookButtonView.clipsToBounds = true
        facebookButtonView.rac_loading <~ viewModel.facebookPending
        facebookButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "facebook"))
        view.addSubview(facebookButtonView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
    }
    
    override func viewDidAppear(animated: Bool) {
        Mixpanel.sharedInstance().timeEvent("View.Login")
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
        
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Login")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let size = view.frame.size
        
        headView.anchorAndFillEdge(.Top, xPad: 0, yPad: 0, otherSize: size.height - 216 - 137) // 216: keyboard, 127: input fields
        skipTextView.anchorInCorner(.TopRight, xPad: 23, yPad: 23, width: 300, height: 20)
        logoView.anchorInCenter(width: 268, height: 84)
        signupTabView.anchorInCorner(.BottomLeft, xPad: 0, yPad: 21, width: size.width / 2, height: 20)
        loginTabView.anchorInCorner(.BottomRight, xPad: 0, yPad: 21, width: size.width / 2, height: 20)
        emailOrUserNameInputView.align(.UnderCentered, relativeTo: headView, padding: 29, width: size.width - 50, height: emailOrUserNameInputView.frame.height)
        passwordInputView.align(.UnderCentered, relativeTo: emailOrUserNameInputView, padding: 12, width: size.width - 50, height: passwordInputView.frame.height)
        forgotPasswordView.align(.UnderMatchingRight, relativeTo: emailOrUserNameInputView, padding: 12, width: 50, height: 20)
        submitButtonView.align(.UnderMatchingRight, relativeTo: emailOrUserNameInputView, padding: 11, width: 20, height: 20)
        facebookButtonView.anchorToEdge(.Bottom, padding: 25, width: size.width - 50, height: 50)
    }
    
    func showForgotPasswordViewController() {
        view.window?.rootViewController = ForgotPasswordViewController()
    }
    
    func showApp() {
        view.window?.rootViewController = TabBarViewController()
    }
    
    func selectSignUpTab() {
        viewModel.selectedTab.value = .SignUp
    }
    
    func selectLogInTab() {
        viewModel.selectedTab.value = .LogIn
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func submit() {
        if !viewModel.allowed.value { return }
        
        viewModel.submit()
            .on(
                failed: { [unowned self] _ in
                    let alert: UIAlertController
                    if case .LogIn = self.viewModel.selectedTab.value {
                        alert = UIAlertController(title: "Login unsuccessful", message: "Your entered data wasn't correct. Please try again.", preferredStyle: .Alert)
                    } else {
                        alert = UIAlertController(title: "Signup unsuccessful", message: "This email address seems to be already taken. Please try another one or login using your existing account.", preferredStyle: .Alert)
                    }
                    alert.addAction(UIAlertAction(title: "Try again", style: .Default, handler: { _ in return }))
                    self.presentViewController(alert, animated: true, completion: nil)
                },
                completed: { [weak self] in
                    self?.forward()
                }
            )
            .start()
    }
    
    func forward() {
        if SessionService.needsOnboarding {
            view.window?.rootViewController = OnboardingInfoViewController()
        } else {
            showApp()
        }
    }
    
    func facebook() {
        let loginManager = FBSDKLoginManager()
        let facebookReadPermissions = ["public_profile", "email"]
        
        viewModel.facebookPending.value = true
        
        let errorBlock = { [weak self] (message: String) in
            self?.viewModel.facebookPending.value = false
            
            let alert = UIAlertController(title: "Facebook Signin unsuccessful", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Try again", style: .Default, handler: { _ in return }))
            self?.presentViewController(alert, animated: true, completion: nil)
        }
        
        let successBlock = { [weak self] (token: FBSDKAccessToken!) in
            self?.viewModel.facebookSignin(token.userID, token: token.tokenString)
                .on(
                    failed: { _ in
                        loginManager.logOut()
                        
                        errorBlock("Something went wrong and we couldn't sign you in. Please try again.")
                    },
                    completed: {
                        self?.forward()
                    }
                )
                .start()
        }
        
        if let token = FBSDKAccessToken.currentAccessToken() where facebookReadPermissions.reduce(true, combine: { $0 && token.hasGranted($1) }) {
            successBlock(token)
            return
        }
        
        loginManager.logInWithReadPermissions(facebookReadPermissions, fromViewController: self) { [weak self] result, error in
            if error != nil || result.isCancelled {
                self?.viewModel.facebookPending.value = false
                loginManager.logOut()
            } else {
                let grantedPermissions = result.grantedPermissions.map( {"\($0)"} )
                let allPermissionsGranted = facebookReadPermissions.reduce(true) { $0 && grantedPermissions.contains($1) }
                
                if allPermissionsGranted {
                    successBlock(result.token)
                } else {
                    errorBlock("Please allow access to all points in the list. Don't worry, your data will be kept safe.")
                }
            }
        }
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
            Async.main { [weak self] in
                self?.submit()
            }
        }
        
        return true
    }
    
}