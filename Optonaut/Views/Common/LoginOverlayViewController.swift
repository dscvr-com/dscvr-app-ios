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
import SwiftyUserDefaults

class LoginOverlayViewController: UIViewController{
    
    private let logoImageView = UIImageView()
    private let facebookButtonView = UIButton()
    
    private let contentView = UIView()
    
    private let viewModel = LoginOverlayViewModel()
    
    var loadingView = UIView()
    var container = UIView()
    var actInd = UIActivityIndicatorView()
    
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
        
        contentView.frame = UIScreen.mainScreen().bounds
        contentView.backgroundColor = UIColor(hex:0xf7f7f7)
        view.addSubview(contentView)
        
        let imageSize = UIImage(named: "logo_big")
        logoImageView.image = UIImage(named: "logo_big")
        contentView.addSubview(logoImageView)
        
        //facebookButtonView.rac_loading <~ viewModel.facebookPending
        facebookButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginOverlayViewController.facebook)))
        facebookButtonView.setBackgroundImage(UIImage(named:"facebook_btn"), forState: .Normal)
        contentView.addSubview(facebookButtonView)
        
        logoImageView.anchorToEdge(.Top, padding: 200, width: imageSize!.size.width, height: imageSize!.size.height)
        facebookButtonView.align(.UnderCentered, relativeTo: logoImageView, padding: 30, width: contentView.frame.width - 85, height: 50)
        
        showActivityIndicatory(contentView)
    }
    
    
    func showActivityIndicatory(uiView: UIView) {
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColor(hex:0xffffff).alpha(0.30)
        
        loadingView.frame = CGRectMake(0, 0, 80, 80)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(hex:0x444444).alpha(0.70)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        actInd.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.WhiteLarge
        actInd.center = CGPointMake(loadingView.frame.size.width / 2,
                                    loadingView.frame.size.height / 2);
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        
        self.loadingView.hidden = true
        self.container.hidden = true
        self.actInd.stopAnimating()
        
    }
    
    func sendCheckElite() -> SignalProducer<RequestCodeApiModel, ApiError> {
        
        let parameters = ["uuid": SessionService.personID]
        return ApiService<RequestCodeApiModel>.postForGate("api/check_status", parameters: parameters)
            .on(next: { data in
                print(data.message)
                print(data.status)
                print(data.request_text)
                
                self.loadingView.hidden = true
                self.container.hidden = true
                self.actInd.stopAnimating()
                
                if (data.status == "ok" && data.message == "3") {
                    Defaults[.SessionEliteUser] = true
                } else {
                    Defaults[.SessionEliteUser] = false
                }
                
            })
    }
    func checkElite() {
        self.loadingView.hidden = false
        self.container.hidden = false
        self.actInd.startAnimating()
        
        sendCheckElite().start()
    }
    
    dynamic private func facebook() {
        let loginManager = FBSDKLoginManager()
        let readPermission = ["public_profile","email","user_friends"]
        
        viewModel.facebookPending.value = true
        
        let errorBlock = { [weak self] (message: String) in
            self?.viewModel.facebookPending.value = false
            
            let alert = UIAlertController(title: "Facebook Signin unsuccessful", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Try again", style: .Default, handler: { _ in return }))
            self?.presentViewController(alert, animated: true, completion: nil)
        }
        
        let successBlock = { [weak self] (token: FBSDKAccessToken!) in
            print(token.tokenString)
            self?.viewModel.facebookSignin(token.userID, token: token.tokenString)
                .on(
                    failed: { _ in
                        loginManager.logOut()
                        errorBlock("Something went wrong and we couldn't sign you in. Please try again.")
                    },
                    completed: {
                        Defaults[.SessionUserDidFirstLogin] = true
                        self?.checkElite()
                    }
                )
                .start()
        }
        
        loginManager.logInWithReadPermissions(readPermission, fromViewController: self) { [weak self] result, error in
            
            if error != nil || result.isCancelled {
                print(error)
                self?.viewModel.facebookPending.value = false
                loginManager.logOut()
                //self!.cancel()
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
    
    
}