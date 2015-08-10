//
//  EditProfileViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class EditProfileViewController: UIViewController, RedNavbar {
    
    let viewModel = EditProfileViewModel()
    
    // subviews
    let avatarImageView = UIImageView()
    let fullNameIconView = UILabel()
    let fullNameInputView = BottomLineTextField()
    let userNameIconView = UILabel()
    let userNameInputView = BottomLineTextField()
//    let userNameTakenView = UILabel() // TODO
    let descriptionIconView = UILabel()
    let descriptionInputView = UITextView()
    let lineView = UIView()
    let privateHeaderView = UILabel()
    let emailIconView = UILabel()
    let emailInputView = BottomLineTextField()
    let passwordIconView = UILabel()
    let passwordButtonView = UIButton()
    let debugIconView = UILabel()
    let debugLabelView = UILabel()
    let debugSwitchView = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        let attributes = [NSFontAttributeName: UIFont.robotoOfSize(17, withType: .Regular)]
        
        let cancelButton = UIBarButtonItem()
        cancelButton.title = "Cancel"
        cancelButton.setTitleTextAttributes(attributes, forState: .Normal)
        cancelButton.target = self
        cancelButton.action = "cancel"
        navigationItem.setLeftBarButtonItem(cancelButton, animated: false)
        
        let saveButton = UIBarButtonItem()
        saveButton.title = "Save"
        saveButton.setTitleTextAttributes(attributes, forState: .Normal)
        saveButton.target = self
        saveButton.action = "save"
        navigationItem.setRightBarButtonItem(saveButton, animated: false)
        
        navigationItem.title = "Edit Profile"
        
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.clipsToBounds = true
        view.addSubview(avatarImageView)
        
        viewModel.avatarUrl.producer
            .start(next: { url in
                if let avatarUrl = NSURL(string: url) {
                    self.avatarImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "avatar-placeholder"))
                }
            })
        
        fullNameIconView.font = .icomoonOfSize(20)
        fullNameIconView.text = .icomoonWithName(.VCard)
        fullNameIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(fullNameIconView)
        
        fullNameInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        fullNameInputView.textColor = UIColor(0x4d4d4d)
        fullNameInputView.autocorrectionType = .No
        fullNameInputView.rac_text <~ viewModel.fullName
        fullNameInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.fullName.value = $0 as! String })
        view.addSubview(fullNameInputView)
        
        userNameIconView.font = .icomoonOfSize(20)
        userNameIconView.text = .icomoonWithName(.Email)
        userNameIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(userNameIconView)
        
        userNameInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        userNameInputView.textColor = UIColor(0x4d4d4d)
        userNameInputView.autocorrectionType = .No
        userNameInputView.autocapitalizationType = .None
        userNameInputView.rac_text <~ viewModel.userName
        userNameInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.userName.value = $0 as! String })
        
        view.addSubview(userNameInputView)
        
        descriptionIconView.font = .icomoonOfSize(20)
        descriptionIconView.text = .icomoonWithName(.InfoWithCircle)
        descriptionIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(descriptionIconView)
        
        descriptionInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        descriptionInputView.textColor = UIColor(0x4d4d4d)
        descriptionInputView.rac_text <~ viewModel.description
        descriptionInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.description.value = $0 as! String })
        descriptionInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        descriptionInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        view.addSubview(descriptionInputView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(lineView)
        
        privateHeaderView.text = "PRIVATE INFORMATION"
        privateHeaderView.textColor = UIColor(0xcfcfcf)
        privateHeaderView.font = UIFont.robotoOfSize(15, withType: .Medium)
        view.addSubview(privateHeaderView)
        
        emailIconView.font = .icomoonOfSize(20)
        emailIconView.text = .icomoonWithName(.PaperPlane)
        emailIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(emailIconView)
        
        emailInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        emailInputView.textColor = UIColor(0x4d4d4d)
        emailInputView.keyboardType = .EmailAddress
        emailInputView.rac_text <~ viewModel.email
        emailInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.email.value = $0 as! String })
        view.addSubview(emailInputView)
        
        passwordIconView.font = .icomoonOfSize(20)
        passwordIconView.text = .icomoonWithName(.Lock)
        passwordIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(passwordIconView)
        
        passwordButtonView.titleEdgeInsets = UIEdgeInsetsZero
        passwordButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Medium)
        passwordButtonView.contentHorizontalAlignment = .Left
        passwordButtonView.setTitleColor(UIColor(0x4d4d4d), forState: .Normal)
        passwordButtonView.setTitle("Change password", forState: .Normal)
        passwordButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.showPasswordAlert()
            return RACSignal.empty()
        })
        view.addSubview(passwordButtonView)
        
        debugIconView.font = .icomoonOfSize(20)
        debugIconView.text = .icomoonWithName(.Cog)
        debugIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(debugIconView)
        
        debugLabelView.text = "Debugging"
        debugLabelView.textColor = UIColor(0x4d4d4d)
        debugLabelView.font = .robotoOfSize(15, withType: .Regular)
        view.addSubview(debugLabelView)
        
        debugSwitchView.on = viewModel.debugEnabled.value
        debugSwitchView.addTarget(self, action: "toggleDebug", forControlEvents: .ValueChanged)
        view.addSubview(debugSwitchView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 25)
        avatarImageView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 60, height: 60))
        
        fullNameIconView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: 5)
        fullNameIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        fullNameIconView.autoSetDimension(.Width, toSize: 20)
        
        fullNameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: fullNameIconView, withOffset: 0)
        fullNameInputView.autoPinEdge(.Left, toEdge: .Right, ofView: fullNameIconView, withOffset: 15)
        fullNameInputView.autoPinEdge(.Right, toEdge: .Left, ofView: avatarImageView, withOffset: -20)
        
        userNameIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: fullNameInputView, withOffset: 30)
        userNameIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        userNameIconView.autoSetDimension(.Width, toSize: 20)
        
        userNameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: userNameIconView, withOffset: 0)
        userNameInputView.autoPinEdge(.Left, toEdge: .Right, ofView: userNameIconView, withOffset: 15)
        userNameInputView.autoPinEdge(.Right, toEdge: .Right, ofView: fullNameInputView)
        
        descriptionIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: userNameInputView, withOffset: 30)
        descriptionIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        descriptionIconView.autoSetDimension(.Width, toSize: 20)
        
        descriptionInputView.autoPinEdge(.Top, toEdge: .Top, ofView: descriptionIconView, withOffset: 0)
        descriptionInputView.autoPinEdge(.Left, toEdge: .Right, ofView: descriptionIconView, withOffset: 15)
        descriptionInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        descriptionInputView.autoSetDimension(.Height, toSize: 80)
        
//        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionInputView, withOffset: 10)
//        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
//        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
//        lineView.autoSetDimension(.Height, toSize: 1)
        
        privateHeaderView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionInputView, withOffset: 10)
        privateHeaderView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
//        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
//        lineView.autoSetDimension(.Height, toSize: 1)
        
        emailIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: privateHeaderView, withOffset: 30)
        emailIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        emailIconView.autoSetDimension(.Width, toSize: 20)

        emailInputView.autoPinEdge(.Top, toEdge: .Top, ofView: emailIconView, withOffset: 0)
        emailInputView.autoPinEdge(.Left, toEdge: .Right, ofView: emailIconView, withOffset: 15)
        emailInputView.autoPinEdge(.Right, toEdge: .Right, ofView: fullNameInputView)
        
        passwordIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailInputView, withOffset: 30)
        passwordIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        passwordIconView.autoSetDimension(.Width, toSize: 20)

        passwordButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: passwordIconView, withOffset: -4)
        passwordButtonView.autoPinEdge(.Left, toEdge: .Right, ofView: passwordIconView, withOffset: 15)
        passwordButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: fullNameInputView)
        
        debugIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordButtonView, withOffset: 30)
        debugIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        debugIconView.autoSetDimension(.Width, toSize: 20)
        
        debugLabelView.autoPinEdge(.Top, toEdge: .Top, ofView: debugIconView, withOffset: -1)
        debugLabelView.autoPinEdge(.Left, toEdge: .Right, ofView: debugIconView, withOffset: 15)
        debugLabelView.autoPinEdge(.Right, toEdge: .Right, ofView: fullNameInputView)
        
        debugSwitchView.autoPinEdge(.Top, toEdge: .Top, ofView: debugIconView, withOffset: -4)
        debugSwitchView.autoPinEdge(.Left, toEdge: .Right, ofView: debugLabelView, withOffset: 15)
        
        super.updateViewConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.enabled = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.enabled = true
    }
    
    func toggleDebug() {
        viewModel.toggleDebug()
    }
    
    func cancel() {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func save() {
        viewModel.updateData()
            .start(
                completed: {
                    self.navigationController?.popViewControllerAnimated(false)
                },
                error: { err in
                    print(err)
                }
        )
    }
    
    func showPasswordAlert() {
        let oldPasswordAlert = UIAlertController(title: "Old password", message: "Please enter old password", preferredStyle: .Alert)
        let newPasswordAlert = UIAlertController(title: "New password", message: "Please enter a new password", preferredStyle: .Alert)
        
        oldPasswordAlert.addTextFieldWithConfigurationHandler { textField in
            textField.secureTextEntry = true
            textField.text = ""
        }
        
        oldPasswordAlert.addAction(UIAlertAction(title: "Continue", style: .Default, handler: { _ in
            self.presentViewController(newPasswordAlert, animated: true, completion: nil)
        }))
        
        oldPasswordAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        newPasswordAlert.addTextFieldWithConfigurationHandler { textField in
            textField.secureTextEntry = true
            textField.text = ""
        }
        
        newPasswordAlert.addAction(UIAlertAction(title: "Update", style: .Destructive, handler: { _ in
            let oldPasswordtextField = oldPasswordAlert.textFields![0] as UITextField
            let newPasswordtextField = newPasswordAlert.textFields![0] as UITextField
            let oldPassword = oldPasswordtextField.text!
            let newPassword = newPasswordtextField.text!
            self.viewModel.updatePassword(oldPassword, newPassword: newPassword)
        }))
        
        newPasswordAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(oldPasswordAlert, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}