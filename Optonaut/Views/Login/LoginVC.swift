//
//  LoginVC.swift
//  VC360Layout
//
//  Created by Thadz on 16/05/2016.
//  Copyright © 2016 Brewed Concepts. All rights reserved.
//

import UIKit

class LoginVC: UIViewController,TransparentNavbarWithStatusBar {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            
            
            updateNavbarAppear()
            self.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            self.view.backgroundColor = UIColor.clearColor();
            
            let blurEffectLight = UIBlurEffect(style: UIBlurEffectStyle.Light);
            let blurEffectView = UIVisualEffectView(effect: blurEffectLight);
            
            blurEffectView.frame = self.view.bounds;
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight];
            
            self.view.addSubview(blurEffectView);
            
            let headerImage = UIImage(named: "logo_big_black");
            let headerImageView = UIImageView(image: headerImage);
            headerImageView.frame = CGRectMake(0, 0, (headerImage?.size.width)!, (headerImage?.size.height)!);
            headerImageView.center = CGPoint(x: self.view.center.x, y: headerImageView.frame.size.height/2 + 50);
            
            self.view.addSubview(headerImageView);
            
            /////////username
            let usernameContainer = UIView();
            usernameContainer.frame = CGRectMake(0.0, 0.0, 290.0, 30.0 + 20.0);
            usernameContainer.backgroundColor = UIColor.clearColor();
            usernameContainer.center = CGPoint(x: self.view.center.x, y: headerImageView.center.y + headerImageView.frame.size.height/2 + 60 /*padding*/ + usernameContainer.frame.size.height/2);
            usernameContainer.layer.cornerRadius = 8.0;
            usernameContainer.layer.borderColor = UIColor.whiteColor().CGColor;
            usernameContainer.layer.borderWidth = 1.0;
            
            let usernameBG = UIView();
            usernameBG.frame = CGRectMake(0.0, 0.0, usernameContainer.frame.size.width, usernameContainer.frame.size.height);
            usernameBG.backgroundColor = UIColor.blackColor();
            usernameBG.layer.cornerRadius = 8.0;
            usernameBG.alpha = 0.3;
            
            let usernameImage = UIImage(named: "username_icn");
            let usernameImageView = UIImageView(image: usernameImage);
            usernameImageView.frame = CGRectMake(0.0, 0.0, (usernameImage?.size.width)!, (usernameImage?.size.width)!);
            usernameImageView.center = CGPoint(x: /*padding*/20.0 + (usernameImage?.size.width)!/2, y: usernameBG.center.y);
            
            let usernameTextField = UITextField();
            usernameTextField.frame = CGRectMake(usernameImageView.frame.origin.x + usernameImageView.frame.size.width + /*padding*/ 15.0, 10.0, usernameContainer.frame.size.width - usernameImageView.frame.size.width - /*padding total*/ 90.0, 30.0);
            usernameTextField.placeholder = "Username";
            usernameTextField.font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightRegular);
            
            usernameContainer.addSubview(usernameBG);
            usernameContainer.addSubview(usernameImageView);
            usernameContainer.addSubview(usernameTextField);
            /////////username
            
            /////////password
            let passwordContainer = UIView();
            passwordContainer.frame = CGRectMake(usernameContainer.frame.origin.x, usernameContainer.frame.origin.y + usernameContainer.frame.size.height + /*padding*/ 20.0, 290.0, 30.0 + 20.0);
            passwordContainer.backgroundColor = UIColor.clearColor();
            passwordContainer.layer.cornerRadius = 8.0;
            passwordContainer.layer.borderColor = UIColor.whiteColor().CGColor;
            passwordContainer.layer.borderWidth = 1.0;
            
            let passwordBG = UIView();
            passwordBG.frame = CGRectMake(0.0, 0.0, usernameContainer.frame.size.width, usernameContainer.frame.size.height);
            passwordBG.backgroundColor = UIColor.blackColor();
            passwordBG.layer.cornerRadius = 8.0;
            passwordBG.alpha = 0.3;
            
            let passwordImage = UIImage(named: "password_icn");
            let passwordImageView = UIImageView(image: passwordImage);
            passwordImageView.frame = CGRectMake(0.0, 0.0, 16.0, 21.0);
            passwordImageView.center = CGPoint(x: /*padding*/20.0 + (passwordImage?.size.width)!/2, y: passwordBG.center.y);
            
            let passwordTextField = UITextField();
            passwordTextField.frame = CGRectMake(passwordImageView.frame.origin.x + passwordImageView.frame.size.width + /*padding*/ 15.0, 10.0, passwordContainer.frame.size.width - passwordImageView.frame.size.width - /*padding total*/ 90.0, 30.0);
            passwordTextField.placeholder = "Password";
            passwordTextField.font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightRegular);
            passwordTextField.secureTextEntry = true;
            
            passwordContainer.addSubview(passwordBG);
            passwordContainer.addSubview(passwordImageView);
            passwordContainer.addSubview(passwordTextField);
            /////////password
            
            /////////loginButton
            let loginImage = UIImage(named: "login_btn");
            let loginButton = UIButton();
            loginButton.setImage(loginImage, forState: .Normal);
            loginButton.frame = CGRectMake(passwordContainer.frame.origin.x, passwordContainer.frame.origin.y + passwordContainer.frame.size.height + /*padding*/ 20.0, 290.0, 45.0);
            loginButton.layer.borderColor = UIColor.whiteColor().CGColor;
            loginButton.layer.borderWidth = 1.0;
            loginButton.layer.cornerRadius = 8.0
            /////////loginButton
            
            /////////registerButton
            let registerImage = UIImage(named: "register_btn");
            let registerButton = UIButton();
            registerButton.setImage(registerImage, forState: .Normal);
            registerButton.frame = CGRectMake(loginButton.frame.origin.x, loginButton.frame.origin.y + loginButton.frame.size.height + /*padding*/ 20.0, 290.0, 45.0);
            registerButton.layer.borderColor = UIColor.whiteColor().CGColor;
            registerButton.layer.borderWidth = 1.0;
            registerButton.layer.cornerRadius = 8.0
            /////////registerButton
            
            /////////note
            let forgotLabel = UILabel();
            forgotLabel.font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightRegular);
            forgotLabel.textColor = UIColor.whiteColor();
            forgotLabel.frame = CGRectMake(registerButton.frame.origin.x + /*adjustment*/ 35.0, registerButton.frame.origin.y + registerButton.frame.size.height + /*padding*/ 20.0, 0.0, 0.0);
            forgotLabel.text = "Forgot your password?";
//            forgotLabel.backgroundColor = UIColor.redColor();
            forgotLabel.sizeToFit();
            
            let forgotButton = UIButton();
            forgotButton.setTitle("Reset here.", forState: .Normal);
            forgotButton.titleLabel?.font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightBold);
            forgotButton.titleLabel?.textColor = UIColor.whiteColor();
            forgotButton.frame = CGRectMake(forgotLabel.frame.origin.x + forgotLabel.frame.size.width + /*padding*/ 5.0, forgotLabel.frame.origin.y - 6.0, 0.0, 0.0);
//            forgotButton.backgroundColor = UIColor.blueColor();
            forgotButton.sizeToFit();
            
            let divider = UIView();
            divider.frame = CGRectMake(registerButton.frame.origin.x, forgotLabel.frame.origin.y + forgotLabel.frame.size.height + /*padding*/ 5.0, 290.0, 1.0);
            divider.backgroundColor = UIColor.whiteColor();
            divider.alpha = 0.3;
            /////////note
            
            /////////facebook
            let facebookImage = UIImage(named: "facebook_btn");
            let facebookButton = UIButton();
            facebookButton.setImage(facebookImage, forState: .Normal);
            facebookButton.frame = CGRectMake(divider.frame.origin.x, divider.frame.origin.y + divider.frame.size.height + /*padding*/ 20.0, 290.0, 45.0);
            /////////facebook
            
            self.view.addSubview(facebookButton);
            self.view.addSubview(divider);
            self.view.addSubview(forgotLabel);
            self.view.addSubview(forgotButton);
            self.view.addSubview(registerButton);
            self.view.addSubview(loginButton);
            self.view.addSubview(usernameContainer);
            self.view.addSubview(passwordContainer);
            //self.navigationController?.navigationBar.translucent = false;
        } 
        else {
            print("disabled");
            self.view.backgroundColor = UIColor.blackColor();
        }
    }

}
