//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS

class LoginViewController: UIViewController {
    
    var showInviteRequest = false
    var didSetupContraints = false
    
    // subviews
    var logoView = UIImageView()
    var emailInputView = UITextField()
    var passwordInputView = UITextField()
    var loginSubmitButtonView = UILabel()
    var showInviteButtonView = UILabel()
    var inviteInputView = UITextField()
    var inviteSubmitButtonView = UILabel()
    var abortButtonView = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = baseColor()
        
        logoView.image = UIImage(named: "logo_white")
        logoView.contentMode = .ScaleAspectFit
        view.addSubview(logoView)
        
        emailInputView.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        emailInputView.borderStyle = .RoundedRect
        emailInputView.autocorrectionType = .No
        emailInputView.autocapitalizationType = .None
        emailInputView.keyboardType = .EmailAddress
        view.addSubview(emailInputView)
        
        passwordInputView.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        passwordInputView.borderStyle = .RoundedRect
        passwordInputView.secureTextEntry = true
        view.addSubview(passwordInputView)
        
        loginSubmitButtonView.backgroundColor = .whiteColor()
        loginSubmitButtonView.textAlignment = .Center
        loginSubmitButtonView.textColor = baseColor()
        loginSubmitButtonView.text = "Login"
        loginSubmitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "submitLogin"))
        loginSubmitButtonView.userInteractionEnabled = true
        loginSubmitButtonView.layer.cornerRadius = 5
        loginSubmitButtonView.layer.masksToBounds = true
        view.addSubview(loginSubmitButtonView)
        
        showInviteButtonView.textAlignment = .Center
        showInviteButtonView.textColor = .whiteColor()
        showInviteButtonView.text = "Request Invite"
        showInviteButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleRequest"))
        showInviteButtonView.userInteractionEnabled = true
        view.addSubview(showInviteButtonView)
        
        abortButtonView.textColor = UIColor.whiteColor()
        abortButtonView.text = "x"
        abortButtonView.font = UIFont.boldSystemFontOfSize(30)
        abortButtonView.userInteractionEnabled = true
        abortButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleRequest"))
        view.addSubview(abortButtonView)
        
        inviteInputView.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        inviteInputView.borderStyle = .RoundedRect
        inviteInputView.autocorrectionType = .No
        inviteInputView.autocapitalizationType = .None
        inviteInputView.keyboardType = .EmailAddress
        view.addSubview(inviteInputView)
        
        inviteSubmitButtonView.backgroundColor = .whiteColor()
        inviteSubmitButtonView.textAlignment = .Center
        inviteSubmitButtonView.textColor = baseColor()
        inviteSubmitButtonView.text = "Request Invite"
        inviteSubmitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "submitRequest"))
        inviteSubmitButtonView.userInteractionEnabled = true
        inviteSubmitButtonView.layer.cornerRadius = 5
        inviteSubmitButtonView.layer.masksToBounds = true
        view.addSubview(inviteSubmitButtonView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        updateView()
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        if !didSetupContraints {
            logoView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 0.3)
            logoView.autoMatchDimension(.Width, toDimension: .Width, ofView: view, withMultiplier: 0.3)
            logoView.autoAlignAxisToSuperviewAxis(.Vertical)
            logoView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 80)
            
            emailInputView.autoSetDimension(.Height, toSize: 60)
            emailInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: logoView, withOffset: 60)
            emailInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 20)
            emailInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
            
            passwordInputView.autoSetDimension(.Height, toSize: 60)
            passwordInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailInputView, withOffset: 5)
            passwordInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 20)
            passwordInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
            
            loginSubmitButtonView.autoSetDimensionsToSize(CGSize(width: 150, height: 60))
            loginSubmitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordInputView, withOffset: 5)
            loginSubmitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
            
            showInviteButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -20)
            showInviteButtonView.autoAlignAxisToSuperviewAxis(.Vertical)
            
            inviteInputView.autoSetDimension(.Height, toSize: 60)
            inviteInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: logoView, withOffset: 60)
            inviteInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 20)
            inviteInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
            
            inviteSubmitButtonView.autoSetDimensionsToSize(CGSize(width: 150, height: 60))
            inviteSubmitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: inviteInputView, withOffset: 5)
            inviteSubmitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
            
            abortButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 20)
            abortButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
            
            didSetupContraints = true
        }
        
        super.updateViewConstraints()
    }
    
    func updateView() {
        if showInviteRequest {
            emailInputView.hidden = true
            passwordInputView.hidden = true
            loginSubmitButtonView.hidden = true
            showInviteButtonView.hidden = true
            abortButtonView.hidden = false
            inviteInputView.hidden = false
            inviteSubmitButtonView.hidden = false
        } else {
            abortButtonView.hidden = true
            inviteInputView.hidden = true
            inviteSubmitButtonView.hidden = true
            emailInputView.hidden = false
            passwordInputView.hidden = false
            loginSubmitButtonView.hidden = false
            showInviteButtonView.hidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func toggleRequest() {
        showInviteRequest = !showInviteRequest
        updateView()
    }
    
    func submitLogin() {
        let parameters = [
            "email": emailInputView.text,
            "password": passwordInputView.text,
        ]
        Api().post("users/login", authorized: false, parameters: parameters,
            success: { json in
                let token = json!["token"].stringValue
                let id = json!["id"].intValue
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: UserDefaultsKeys.USER_IS_LOGGED_IN.rawValue)
                NSUserDefaults.standardUserDefaults().setObject(token, forKey: UserDefaultsKeys.USER_TOKEN.rawValue)
                NSUserDefaults.standardUserDefaults().setInteger(id, forKey: UserDefaultsKeys.USER_ID.rawValue)
                self.presentViewController(TabBarViewController(), animated: false, completion: nil)
            },
            fail: { error in
                self.emailInputView.textColor = .redColor()
                println(error)
            }
        )
    }
    
    func submitRequest() {
        let parameters = [
            "email": emailInputView.text,
        ]
        Api().post("users/request-invite", authorized: false, parameters: parameters,
            success: { json in
                self.inviteInputView.textColor = .greenColor()
            },
            fail: { error in
                println(error)
                self.inviteInputView.textColor = .redColor()
            }
        )
    }
    
}

