//
//  OverlayViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 30/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import FBSDKLoginKit

class LoginOverlayViewController: UIViewController {
    
    private let containerView = UIView()
    private let backgroundImageView = UIImageView()
    private let titleView = UILabel()
    private let continueView = UILabel()
    private let cancelView = BoundingLabel()
    private let loginView = BoundingLabel()
    private let facebookButtonView = ActionButton()
    
    private let viewModel = LoginOverlayViewModel()
    
    private let successCallback: () -> ()
    private let cancelCallback: () -> Bool
    private let alwaysCallback: () -> ()
    
    init(title: String, successCallback: () -> (), cancelCallback: () -> Bool, alwaysCallback: () -> ()) {
        titleView.text = title
        self.successCallback = successCallback
        self.cancelCallback = cancelCallback
        self.alwaysCallback = alwaysCallback
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .OverCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor().alpha(0.7)
        
        backgroundImageView.image = UIImage(named: "onboarding")
        containerView.addSubview(backgroundImageView)
        
        titleView.font = UIFont.displayOfSize(21, withType: .Light)
        titleView.textAlignment = .Center
        titleView.textColor = .DarkGrey
        containerView.addSubview(titleView)
        
        continueView.text = "Continue with..."
        continueView.font = UIFont.displayOfSize(15, withType: .Light)
        continueView.textAlignment = .Center
        continueView.textColor = .DarkGrey
        containerView.addSubview(continueView)
        
        facebookButtonView.defaultBackgroundColor = UIColor(0x3C5193)
        facebookButtonView.activeBackgroundColor = UIColor(0x405BB0)
        facebookButtonView.disabledBackgroundColor = UIColor(0x405BB0)
        facebookButtonView.setTitle("FACEBOOK", forState: .Normal)
        facebookButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        facebookButtonView.titleLabel!.font = UIFont.displayOfSize(16, withType: .Semibold)
        facebookButtonView.layer.cornerRadius = 8
        facebookButtonView.rac_loading <~ viewModel.facebookPending
        facebookButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "facebook"))
        containerView.addSubview(facebookButtonView)
        
        cancelView.text = "Back"
        cancelView.font = UIFont.displayOfSize(16, withType: .Semibold)
        cancelView.textAlignment = .Left
        cancelView.textColor = .DarkGrey
        cancelView.userInteractionEnabled = true
        cancelView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        containerView.addSubview(cancelView)
        
        loginView.text = "Use existing account"
        loginView.font = UIFont.displayOfSize(16, withType: .Semibold)
        loginView.textAlignment = .Right
        loginView.textColor = .DarkGrey
        loginView.userInteractionEnabled = true
        loginView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "login"))
        containerView.addSubview(loginView)
        
        view.addSubview(containerView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let screenBounds = UIScreen.mainScreen().bounds
        let aspectRatio: CGFloat = 1.535
        let width, height: CGFloat
        if screenBounds.height / screenBounds.width < aspectRatio {
            height = screenBounds.height - 10
            width = height * (screenBounds.width / screenBounds.height)
        } else {
            width = screenBounds.width - 10
            height = width * aspectRatio
        }
        
        containerView.frame = CGRect(x: (screenBounds.width - width) / 2, y: (screenBounds.height - height) / 2, width: width, height: height)
        
        backgroundImageView.fillSuperview()
        
        titleView.anchorToEdge(.Top, padding: height * 0.1 - 10, width: width, height: 23)
        
        facebookButtonView.anchorToEdge(.Bottom, padding: height * 0.22 - 30, width: width * 0.8, height: 60)
        continueView.alignAndFillWidth(align: .AboveCentered, relativeTo: facebookButtonView, padding: 15, height: 18)
        
        cancelView.anchorInCorner(.BottomLeft, xPad: 20, yPad: 20, width: 100, height: 18)
        loginView.anchorInCorner(.BottomRight, xPad: 20, yPad: 20, width: 160, height: 18)
    }
    
    dynamic private func facebook() {
        let loginManager = FBSDKLoginManager()
        let readPermission = ["public_profile","email"]
        
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
                        self?.successCallback()
                        self?.dismissViewControllerAnimated(true, completion: nil)
                        self?.alwaysCallback()
                    }
                )
                .start()
        }
        
        loginManager.logInWithReadPermissions(readPermission, fromViewController: self) { [weak self] result, error in
            
            if error != nil || result.isCancelled {
                print(error)
                self?.viewModel.facebookPending.value = false
                loginManager.logOut()
            } else {
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
    
    dynamic private func login() {
        presentViewController(LoginViewController(successCallback: {
            self.dismissViewControllerAnimated(true, completion: {
                self.successCallback()
                self.alwaysCallback()
            })
        }), animated: false, completion: nil)
    }
    
    dynamic private func cancel() {
        if cancelCallback() {
            dismissViewControllerAnimated(true, completion: nil)
            alwaysCallback()
        }
    }
    
}