//
//  InvitationViewController.swift
//  DSCVR
//
//  Created by robert john alkuino on 6/30/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SwiftyUserDefaults

class InvitationViewController: UIViewController,UITextFieldDelegate {

    var label1 = UILabel()
    var label2 = UILabel()
    var label3 = UILabel()
    var logoImageView = UIImageView()
    var textPutCode = UITextField()
    var textRequestCode = UILabel()
    var buttonPutCode = UIButton()
    var view1 = UIView()
    var orImage = UIImageView()
    var requestButton = UIButton()
    var backView = UIView()
    var personBox: ModelBox<Person>!
    var fromProfilePage:Bool = false
    //var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        backView.backgroundColor = UIColor(hex:0x343434)
        view.addSubview(backView)
        backView.fillSuperview()
        
        let logo: UIImage = UIImage(named: "logo_invite")!
        logoImageView.image = logo
        backView.addSubview(logoImageView)
        
        let dragTextWidth = calcTextWidth("Super Secret Code:", withFont: .displayOfSize(20, withType: .Semibold))
        label1.text = "Super Secret Code:"
        label1.font = UIFont(name: "Avenir-Book", size: 20)
        label1.backgroundColor = UIColor.clearColor()
        label1.textColor = UIColor(hex:0x343434)
        label1.textAlignment = .Center
        backView.addSubview(label1)
        
        view1.backgroundColor = UIColor.clearColor()
        backView.addSubview(view1)
        
        textPutCode.backgroundColor = UIColor(hex:0xCACACA)
        textPutCode.layer.cornerRadius = 4
        textPutCode.autocapitalizationType = .Words
        view1.addSubview(textPutCode)
        
        buttonPutCode.setTitle("GO", forState: .Normal)
        buttonPutCode.layer.cornerRadius = 4
        buttonPutCode.titleLabel!.font =  UIFont(name: "HelveticaNeue-Bold", size: 15)
        buttonPutCode.backgroundColor = UIColor(hex:0xFF8B00)
        buttonPutCode.setTitleColor(UIColor(hex:0x343434), forState: .Normal)
        buttonPutCode.addTarget(self,action: #selector(sendCode),forControlEvents: .TouchUpInside)
        view1.addSubview(buttonPutCode)
        
        let orText: UIImage = UIImage(named: "or_icn")!
        orImage.image = orText
        backView.addSubview(orImage)
        
        label2.text = "Get a Super Secret Code:"
        label2.font = UIFont(name: "Avenir-Book", size: 20)
        label2.backgroundColor = UIColor.clearColor()
        label2.textAlignment = .Center
        label2.textColor = UIColor(hex:0x343434)
        backView.addSubview(label2)
        
        textRequestCode.backgroundColor = UIColor.clearColor()
        textRequestCode.font = UIFont(name: "Avenir-Book", size: 20)
        textRequestCode.textColor = UIColor(hex:0x343434)
        textRequestCode.textAlignment = .Center
        backView.addSubview(textRequestCode)
        
        requestButton.setTitle("SEND", forState: .Normal)
        requestButton.layer.cornerRadius = 4
        requestButton.titleLabel!.font =  UIFont(name: "HelveticaNeue-Bold", size: 15)
        requestButton.backgroundColor = UIColor(hex:0xFF8B00)
        requestButton.setTitleColor(UIColor(hex:0x343434), forState: .Normal)
        requestButton.addTarget(self,action: #selector(sendRequest),forControlEvents: .TouchUpInside)
        backView.addSubview(requestButton)
        
        label3.text = "Reach us at TEAM@DSCVR.COM"
        label3.font = UIFont(name: "Avenir-Book", size: 17)
        label3.backgroundColor = UIColor.clearColor()
        label3.textAlignment = .Center
        label3.textColor = UIColor(hex:0x343434)
        backView.addSubview(label3)
        
        logoImageView.anchorToEdge(.Top, padding: 60, width: logo.size.width, height: logo.size.height)
        label1.align(.UnderCentered, relativeTo: logoImageView, padding: 55, width: dragTextWidth, height: 25)
        
        let viewwidth = (view.frame.width-49)/3
        
        textPutCode.anchorInCorner(.TopLeft, xPad: 0, yPad: 0, width: (viewwidth * 2)+20, height: 50)
        buttonPutCode.align(.ToTheRightMatchingBottom, relativeTo: textPutCode, padding: 5, width: viewwidth - 20, height: 50)
        view1.align(.UnderCentered, relativeTo: label1, padding: 16, width: view.frame.width-49, height: 50)
        orImage.align(.UnderCentered, relativeTo: view1, padding: 49, width: orText.size.width, height: orText.size.height)
        label2.align(.UnderCentered, relativeTo: orImage, padding: 22, width: view.frame.width-44, height: 50)
        
        textRequestCode.align(.UnderCentered, relativeTo: label2, padding: 16, width: view.frame.width-44, height: 50)
        requestButton.align(.UnderCentered, relativeTo: textRequestCode, padding: 13, width: view.frame.width-44, height: 50)
        
        let footerWidth = calcTextWidth("Reach us at TEAM@DSCVR.COM", withFont: .displayOfSize(17, withType: .Semibold))
        label3.anchorToEdge(.Bottom, padding: 10, width: footerWidth, height:20)
        
        textPutCode.delegate = self
        backView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeKeyboard)))
        
        let closeButton = UIButton()
        closeButton.setBackgroundImage(UIImage(named:"close_icn"), forState: .Normal)
        closeButton.anchorInCorner(.TopLeft, xPad: 10, yPad: 20, width: 30 , height: 30)
        closeButton.addTarget(self, action: #selector(close), forControlEvents: .TouchUpInside)
        backView.addSubview(closeButton)
        
        if fromProfilePage {
            closeButton.hidden = true
        }
        
        personBox = Models.persons[SessionService.personID]!
        
        textRequestCode.text = personBox.model.email!
        
//        activityIndicator.hidesWhenStopped = true
//        activityIndicator.center = view.center
//        activityIndicator.stopAnimating()
//        backView.addSubview(activityIndicator)
    }
    
    
    func close() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func closeKeyboard() {
        view.endEditing(true)
    }
    
    func sendRequest() {
        sendApiRequestCode().start()
    }
    
    func sendApiRequestCode() -> SignalProducer<RequestCodeApiModel, ApiError> {
        //activityIndicator.startAnimating()
        LoadingIndicatorView.show()
        let parameters = ["uuid": SessionService.personID]
        print(parameters)
        return ApiService<RequestCodeApiModel>.postForGate("api/request_code", parameters:parameters)
            .on(next: { data in
                //self.activityIndicator.stopAnimating()
                LoadingIndicatorView.hide()
                print(data.message)
                print(data.status)
                print(data.request_text)
                
                if (data.status == "ok" && data.message == "Updated to status 2") {
                    Defaults[.SessionEliteUser] = false
                    self.label2.text = data.request_text
                    self.label2.font = UIFont(name: "Avenir-Book", size: 13)
                    self.requestButton.enabled = false
                    self.sendAlert(data.prompt)
                }
            })
    }
    
    func pushCode() -> SignalProducer<RequestCodeApiModel, ApiError> {
        
        //activityIndicator.startAnimating()
        LoadingIndicatorView.show()
        let parameters = ["uuid": SessionService.personID,"code":textPutCode.text!]
        print(parameters)
        return ApiService<RequestCodeApiModel>.postForGate("api/use_code", parameters: parameters)
            .on(next: { data in
                //self.activityIndicator.stopAnimating()
                LoadingIndicatorView.hide()
                print(data.message)
                print(data.status)
                print(data.request_text)
                if (data.status == "ok") {
                    Defaults[.SessionEliteUser] = true
                }
                self.sendAlert(data.prompt)
                
            })
    }
    func sendCode() {
        pushCode().start()
    }
    
    func sendCheckElite() -> SignalProducer<RequestCodeApiModel, ApiError> {
        
        //activityIndicator.startAnimating()
        LoadingIndicatorView.show()
        let parameters = ["uuid": SessionService.personID]
        print(parameters)
        return ApiService<RequestCodeApiModel>.postForGate("api/check_status", parameters: parameters)
            .on(next: { data in
                print(data.message)
                print(data.status)
                print(data.request_text)
                if (data.status == "ok" && data.message == "1") {
                    self.label2.text = data.request_text
                    self.label2.font = UIFont(name: "Avenir-Book", size: 20)
                    self.requestButton.enabled = true
                    Defaults[.SessionEliteUser] = false
                    LoadingIndicatorView.hide()
                } else if (data.status == "ok" && data.message == "2"){
                    self.label2.text = data.request_text
                    self.label2.font = UIFont(name: "Avenir-Book", size: 13)
                    self.requestButton.enabled = false
                    Defaults[.SessionEliteUser] = false
                    LoadingIndicatorView.hide()
                } else if (data.status == "ok" && data.message == "3"){
                    LoadingIndicatorView.hide()
                    self.navigationController?.popViewControllerAnimated(false)
                }
                
            })
    }
    func checkElite() {
        sendCheckElite().start()
    }
    
    
    func sendAlert(message:String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in
            if Defaults[.SessionEliteUser] {
                self.navigationController?.popViewControllerAnimated(true)
            }
            
            return }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if fromProfilePage {
            self.navigationItem.setHidesBackButton(true, animated:true);
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        checkElite()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if fromProfilePage {
            self.navigationItem.setHidesBackButton(false, animated:true);
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        if textRequestCode.isFirstResponder() {
            backView.frame = CGRect(x: 0,y: backView.frame.origin.y - keyboardHeight ,width: view.frame.width,height: view.frame.height)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        if textRequestCode.isFirstResponder() {
            backView.frame = CGRect(x: 0,y: backView.frame.origin.y + keyboardHeight ,width: view.frame.width,height: view.frame.height)
        }
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
