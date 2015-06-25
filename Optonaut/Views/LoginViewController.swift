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

class LoginViewController: UIViewController {
    
    // subviews
    var logoView = UIImageView()
    var loginEmailInputView = UITextField()
    var loginPasswordInputView = UITextField()
    var loginSubmitButtonView = UIButton()
    var loginShowInviteButtonView = UILabel()
    var inviteEmailInputView = UITextField()
    var inviteSubmitButtonView = UIButton()
    var inviteAbortButtonView = UILabel()
    
    var viewModel = LoginViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = baseColor()
        
        logoView.image = UIImage(named: "logo_white")
        logoView.contentMode = .ScaleAspectFit
        view.addSubview(logoView)
        
        loginEmailInputView.attributedPlaceholder = NSAttributedString(string:"Email", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        loginEmailInputView.borderStyle = .RoundedRect
        loginEmailInputView.autocorrectionType = .No
        loginEmailInputView.autocapitalizationType = .None
        loginEmailInputView.keyboardType = .EmailAddress
        loginEmailInputView.rac_textColor <~ viewModel.loginEmailValid.producer |> map { $0 ? .blackColor() : .redColor() }
        loginEmailInputView.rac_hidden <~ viewModel.inviteFormVisible
        viewModel.loginEmail <~ loginEmailInputView.rac_text
        view.addSubview(loginEmailInputView)
        
        loginPasswordInputView.attributedPlaceholder = NSAttributedString(string:"Password", attributes:[NSForegroundColorAttributeName: UIColor.grayColor()])
        loginPasswordInputView.borderStyle = .RoundedRect
        loginPasswordInputView.secureTextEntry = true
        loginPasswordInputView.rac_textColor <~ viewModel.loginPasswordValid.producer |> map { $0 ? .blackColor() : .redColor() }
        loginPasswordInputView.rac_hidden <~ viewModel.inviteFormVisible
        viewModel.loginPassword <~ loginPasswordInputView.rac_text
        view.addSubview(loginPasswordInputView)
        
        loginSubmitButtonView.backgroundColor = .whiteColor()
        loginSubmitButtonView.setTitle("Login", forState: .Normal)
        loginSubmitButtonView.setTitleColor(baseColor(), forState: .Normal)
        loginSubmitButtonView.setTitleColor(UIColor.grayColor(), forState: .Disabled)
        loginSubmitButtonView.layer.cornerRadius = 5
        loginSubmitButtonView.layer.masksToBounds = true
        loginSubmitButtonView.rac_hidden <~ viewModel.inviteFormVisible
        loginSubmitButtonView.rac_enabled <~ viewModel.loginAllowed
        loginSubmitButtonView.rac_userInteractionEnabled <~ viewModel.loginAllowed
        loginSubmitButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.login()
                |> observe(
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
        view.addSubview(loginSubmitButtonView)
        
        loginShowInviteButtonView.textAlignment = .Center
        loginShowInviteButtonView.textColor = .whiteColor()
        loginShowInviteButtonView.text = "Request Invite"
        loginShowInviteButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleRequest"))
        loginShowInviteButtonView.userInteractionEnabled = true
        loginShowInviteButtonView.rac_hidden <~ viewModel.inviteFormVisible
        view.addSubview(loginShowInviteButtonView)
        
        inviteAbortButtonView.textColor = UIColor.whiteColor()
        inviteAbortButtonView.text = "x"
        inviteAbortButtonView.font = UIFont.boldSystemFontOfSize(30)
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
        view.addSubview(inviteEmailInputView)
        
        inviteSubmitButtonView.backgroundColor = .whiteColor()
        inviteSubmitButtonView.setTitle("Request Invite", forState: .Normal)
        inviteSubmitButtonView.setTitleColor(baseColor(), forState: .Normal)
        inviteSubmitButtonView.setTitleColor(UIColor.grayColor(), forState: .Disabled)
        inviteSubmitButtonView.userInteractionEnabled = true
        inviteSubmitButtonView.layer.cornerRadius = 5
        inviteSubmitButtonView.layer.masksToBounds = true
        inviteSubmitButtonView.rac_enabled <~ viewModel.inviteEmailValid
        inviteSubmitButtonView.rac_userInteractionEnabled <~ viewModel.inviteEmailValid
        inviteSubmitButtonView.rac_hidden <~ viewModel.inviteFormVisible.producer |> map { !$0 }
        inviteSubmitButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.requestInvite()
                |> observe(
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
        view.addSubview(inviteSubmitButtonView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        logoView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 0.3)
        logoView.autoMatchDimension(.Width, toDimension: .Width, ofView: view, withMultiplier: 0.3)
        logoView.autoAlignAxisToSuperviewAxis(.Vertical)
        logoView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 80)
        
        loginEmailInputView.autoSetDimension(.Height, toSize: 60)
        loginEmailInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: logoView, withOffset: 60)
        loginEmailInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 20)
        loginEmailInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        
        loginPasswordInputView.autoSetDimension(.Height, toSize: 60)
        loginPasswordInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: loginEmailInputView, withOffset: 5)
        loginPasswordInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 20)
        loginPasswordInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        
        loginSubmitButtonView.autoSetDimensionsToSize(CGSize(width: 150, height: 60))
        loginSubmitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: loginPasswordInputView, withOffset: 5)
        loginSubmitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        
        loginShowInviteButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -20)
        loginShowInviteButtonView.autoAlignAxisToSuperviewAxis(.Vertical)
        
        inviteEmailInputView.autoSetDimension(.Height, toSize: 60)
        inviteEmailInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: logoView, withOffset: 60)
        inviteEmailInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 20)
        inviteEmailInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        
        inviteSubmitButtonView.autoSetDimensionsToSize(CGSize(width: 150, height: 60))
        inviteSubmitButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: inviteEmailInputView, withOffset: 5)
        inviteSubmitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        
        inviteAbortButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 30)
        inviteAbortButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -30)
        
        super.updateViewConstraints()
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
        viewModel.inviteFormVisible.put(!viewModel.inviteFormVisible.value)
    }
    
}

