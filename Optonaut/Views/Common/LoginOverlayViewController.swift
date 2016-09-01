//
//  OverlayViewController.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 30/05/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async
import Mixpanel
import FBSDKLoginKit
import SwiftyUserDefaults

class LoginOverlayViewController: UIViewController{
    
    private let logoImageView = UIImageView()
    private let facebookButtonView = UIButton()
    private let viewModel = LoginOverlayViewModel()
    
    private let headView = UIView()
    private let signupTabView = UILabel()
    private let loginTabView = UILabel()
    private let emailOrUserNameInputView = TextField()
    private let passwordInputView = TextField()
    private let submitButtonView = UIButton()
    private let forgotPasswordView = UILabel()
    
    private let signupHelpTextView = UILabel()
    private let loadingView = UIView()
    private let loginViewModel = LoginViewModel()
    let headerImage = UIImage(named: "login_logo")
    var headerImageView:UIImageView?
    var usernameStatus = UILabel()
    var passwordStatus = UILabel()
    let lineLabel = UILabel()
    
    init() {
        
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .OverCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        navigationController?.navigationBarHidden = true
        
        view.backgroundColor = UIColor(hex:0xf7f7f7)
        
        facebookButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginOverlayViewController.facebook)))
        facebookButtonView.setBackgroundImage(UIImage(named:"facebook_btn"), forState: .Normal)
        view.addSubview(facebookButtonView)
        
        headView.backgroundColor = UIColor(hex:0x3E3D3D)
        view.addSubview(headView)
        
        headerImageView = UIImageView(image: headerImage)
        headView.addSubview(headerImageView!)
        
        signupTabView.textAlignment = .Center
        signupTabView.text = "SIGN UP"
        signupTabView.font = .displayOfSize(14, withType: .Semibold)
        signupTabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginOverlayViewController.selectSignUpTab)))
        signupTabView.userInteractionEnabled = true
        //signupTabView.rac_alpha <~ loginViewModel.selectedTab.producer.equalsTo(.SignUp).mapToTuple(1, 0.5)
        headView.addSubview(signupTabView)
        
        loginTabView.textAlignment = .Center
        loginTabView.text = "LOG IN"
        loginTabView.font = .displayOfSize(14, withType: .Semibold)
        loginTabView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginOverlayViewController.selectLogInTab)))
        loginTabView.userInteractionEnabled = true
        //loginTabView.rac_alpha <~ loginViewModel.selectedTab.producer.equalsTo(.LogIn).mapToTuple(1, 0.5)
        headView.addSubview(loginTabView)
        
        emailOrUserNameInputView.rac_placeholder <~ loginViewModel.selectedTab.producer.equalsTo(.SignUp).mapToTuple("Email address", "Email address or username")
        
        emailOrUserNameInputView.layer.borderColor = UIColor(hex:0xFF8B00).CGColor
        emailOrUserNameInputView.layer.borderWidth = 2.0
        emailOrUserNameInputView.layer.cornerRadius = 7.0
        emailOrUserNameInputView.clipsToBounds = true
        emailOrUserNameInputView.autocorrectionType = .No
        emailOrUserNameInputView.autocapitalizationType = .None
        emailOrUserNameInputView.keyboardType = .EmailAddress
        emailOrUserNameInputView.returnKeyType = .Next
        emailOrUserNameInputView.delegate = self
        
        //emailOrUserNameInputView.rac_status <~ loginViewModel.emailOrUserNameStatus
        loginViewModel.emailOrUserNameStatus.producer
            .observeOnMain()
            .startWithNext { [weak self] status in
                
                switch status {
                case let .Warning(statusText):
                    print(statusText)
                    self?.usernameStatus.text = statusText
                default:
                    self?.usernameStatus.text = ""
                }
        }
        
        loginViewModel.emailOrUserName <~ emailOrUserNameInputView.rac_text
        view.addSubview(emailOrUserNameInputView)
        
        usernameStatus.font = UIFont(name: "Avenir-Book", size: 8)
        usernameStatus.textColor = UIColor.grayColor()
        usernameStatus.textAlignment = .Right
        view.addSubview(usernameStatus)
        
        passwordInputView.rac_placeholder <~ loginViewModel.selectedTab.producer.equalsTo(.SignUp).mapToTuple("Choose a password", "Password")
        passwordInputView.layer.borderColor = UIColor(hex:0xFF8B00).CGColor
        passwordInputView.layer.borderWidth = 2.0
        passwordInputView.layer.cornerRadius = 7.0
        passwordInputView.clipsToBounds = true
        passwordInputView.secureTextEntry = true
        passwordInputView.returnKeyType = .Go
        passwordInputView.delegate = self
        
        loginViewModel.password <~ passwordInputView.rac_text
        view.addSubview(passwordInputView)
        
        loginViewModel.passwordStatus.producer
            .observeOnMain()
            .startWithNext { [weak self] status in
                
                switch status {
                case let .Warning(statusText):
                    print(statusText)
                    self?.passwordStatus.text = statusText
                default:
                    self?.passwordStatus.text = ""
                }
        }
        
        passwordStatus.font = UIFont(name: "Avenir-Book", size: 8)
        passwordStatus.textColor = UIColor.grayColor()
        passwordStatus.textAlignment = .Right
        view.addSubview(passwordStatus)
        
        submitButtonView.addTarget(self, action: #selector(submit), forControlEvents: .TouchUpInside)
        submitButtonView.layer.cornerRadius = 7.0
        submitButtonView.clipsToBounds = true
        submitButtonView.backgroundColor = UIColor(hex:0xFF8B00)
        submitButtonView.setTitleColor(UIColor(hex:0xf7f7f7), forState: UIControlState.Normal)
        submitButtonView.titleLabel!.font = UIFont(name: "Avenir-Heavy", size: 15)
        view.addSubview(submitButtonView)
        
        forgotPasswordView.textColor = UIColor(hex:0xFF8B00)
        forgotPasswordView.textAlignment = .Center
        forgotPasswordView.text = "Forgot your password?"
        forgotPasswordView.font = UIFont(name: "Avenir-Book", size: 15)
        forgotPasswordView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginOverlayViewController.showForgotPasswordViewController)))
        forgotPasswordView.userInteractionEnabled = true
        forgotPasswordView.hidden = true
//        forgotPasswordView.rac_hidden <~ loginViewModel.selectedTab.producer.equalsTo(.SignUp)
//            .combineLatestWith(loginViewModel.password.producer.map(isNotEmpty)).map(or)
        view.addSubview(forgotPasswordView)
        
        lineLabel.backgroundColor = UIColor.grayColor()
        view.addSubview(lineLabel)
        
        loadingView.backgroundColor = UIColor.blackColor().alpha(0.3)
        loadingView.rac_hidden <~ loginViewModel.pending.producer.map(negate)
        view.addSubview(loadingView)
        
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginOverlayViewController.dismissKeyboard)))
        
        loginViewModel.selectedTab.producer.startWithNext { val in
            if val == .LogIn {
                self.loginTabView.backgroundColor = UIColor(hex:0xf7f7f7)
                self.signupTabView.backgroundColor = UIColor(hex:0x3E3D3D)
                
                self.loginTabView.textColor = UIColor(hex:0xFF8B00)
                self.signupTabView.textColor = UIColor(hex:0xf7f7f7)
                self.submitButtonView.setTitle("LOGIN", forState: UIControlState.Normal)
            } else {
                self.loginTabView.backgroundColor = UIColor(hex:0x3E3D3D)
                self.signupTabView.backgroundColor = UIColor(hex:0xf7f7f7)
                
                self.loginTabView.textColor = UIColor(hex:0xf7f7f7)
                self.signupTabView.textColor = UIColor(hex:0xFF8B00)
                self.submitButtonView.setTitle("SIGNUP", forState: UIControlState.Normal)
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let size = view.frame.size
        
        headView.anchorAndFillEdge(.Top, xPad: 0, yPad: 0, otherSize: (size.height * 0.3) + ((size.height * 0.3)/2))
        headerImageView!.anchorInCenter(width: headerImage!.size.width, height: (headerImage?.size
            .height)!)
        logoImageView.anchorInCenter(width: 150, height: 50)
        signupTabView.anchorInCorner(.BottomLeft, xPad: 0, yPad: 0, width: size.width / 2, height: 60)
        loginTabView.anchorInCorner(.BottomRight, xPad: 0, yPad: 0, width: size.width / 2, height: 60)
        emailOrUserNameInputView.align(.UnderCentered, relativeTo: headView, padding: 29, width: size.width - 100, height: 45)
        passwordInputView.align(.UnderCentered, relativeTo: emailOrUserNameInputView, padding: 20, width: size.width - 100, height: 45)
        submitButtonView.align(.UnderMatchingRight, relativeTo: passwordInputView, padding: 25, width: size.width - 100, height: 45)
        forgotPasswordView.align(.UnderCentered, relativeTo: submitButtonView, padding: 30, width: 200, height: 20)
        lineLabel.align(.UnderCentered, relativeTo: forgotPasswordView, padding: 10, width: size.width - 50, height: 2)
        
        let r = (size.height - lineLabel.frame.origin.y)
        
        facebookButtonView.align(.UnderCentered, relativeTo: forgotPasswordView, padding: (r/2) - 25, width: UIImage(named:"facebook_btn")!.size.width, height: 50)
        
        usernameStatus.align(.UnderMatchingRight, relativeTo: emailOrUserNameInputView, padding: 2, width: 100, height: 8)
        passwordStatus.align(.UnderMatchingRight, relativeTo: passwordInputView, padding: 2, width: 100, height: 12)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showForgotPasswordViewController() {
        presentViewController(ForgotPasswordViewController(), animated: false, completion: nil)
    }
    
    func selectLogInTab() {
        loginViewModel.selectedTab.value = .LogIn
    }
    
    func selectSignUpTab() {
        loginViewModel.selectedTab.value = .SignUp
    }
    
    func submit() {
        print("pumasok dito")
        if !loginViewModel.allowed.value { return }
        
        submitButtonView.enabled = false
        
        loginViewModel.submit()
            .on(
                failed: { [unowned self] _ in
                    self.submitButtonView.enabled = true
                    let alert: UIAlertController
                    if case .LogIn = self.loginViewModel.selectedTab.value {
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
//        dismissViewControllerAnimated(true, completion: {
//            Defaults[.SessionNeedRefresh] = true
//            self.successCallback()
//        })
        Defaults[.SessionUserDidFirstLogin] = true
        self.checkElite()
    }
    
    func sendCheckElite() -> SignalProducer<RequestCodeApiModel, ApiError> {
        
        LoadingIndicatorView.show()
        
        let parameters = ["uuid": SessionService.personID]
        return ApiService<RequestCodeApiModel>.postForGate("api/check_status", parameters: parameters)
            .on(next: { data in
                print(data.message)
                print(data.status)
                print(data.request_text)
                
                LoadingIndicatorView.hide()
                
                if (data.status == "ok" && data.message == "3") {
                    Defaults[.SessionEliteUser] = true
                } else {
                    Defaults[.SessionEliteUser] = false
                }
                
            })
    }
    func checkElite() {
        sendCheckElite().start()
    }
    
    dynamic private func facebook() {
        
        let loginManager = FBSDKLoginManager()
        let readPermission = ["public_profile","email","user_friends"]
        
        viewModel.facebookPending.value = true
        
        let errorBlock = { [weak self] (message: String) in
            self?.viewModel.facebookPending.value = false
            LoadingIndicatorView.hide()
            let alert = UIAlertController(title: "Facebook Signin unsuccessful", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Try again", style: .Default, handler: { _ in return }))
            self?.presentViewController(alert, animated: true, completion: nil)
        }
        
        let successBlock = { [weak self] (token: FBSDKAccessToken!) in
            self?.viewModel.facebookSignin(token.userID, token: token.tokenString)
                .on(
                    failed: { _ in
                        loginManager.logOut()
                        LoadingIndicatorView.hide()
                        errorBlock("Something went wrong and we couldn't sign you in. Please try again.")
                    },
                    completed: {
                        Defaults[.SessionUserDidFirstLogin] = true
                        LoadingIndicatorView.hide()
                        self?.checkElite()
                    }
                )
                .start()
        }
        
        loginManager.logInWithReadPermissions(readPermission, fromViewController: self) { [weak self] result, error in
            
            if error != nil || result.isCancelled {
                self?.viewModel.facebookPending.value = false
                loginManager.logOut()
            } else {
                LoadingIndicatorView.show()
                let grantedPermissions = result.grantedPermissions.map( {"\($0)"} )
                let allPermissionsGranted = readPermission.reduce(true) { $0 && grantedPermissions.contains($1) }

                if allPermissionsGranted {
                    successBlock(result.token)
                } else {
                    errorBlock("Please allow access to all points in the list. Don't worry, your data will be kept safe.")
                }
            }
        }
    }
}

extension LoginOverlayViewController: UITextFieldDelegate {
    
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

class TextField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 5);
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}