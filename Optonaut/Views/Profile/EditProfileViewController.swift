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
    
    var viewModel: EditProfileViewModel
    
    // subviews
    let avatarImageView = UIImageView()
    let nameIconView = UILabel()
    let nameInputView = BottomLineTextField()
    let userNameIconView = UILabel()
    let userNameInputView = BottomLineTextField()
    let bioIconView = UILabel()
    let bioInputView = UITextView()
    let lineView = UIView()
    let emailIconView = UILabel()
    let emailInputView = BottomLineTextField()
    let passwordIconView = UILabel()
    let passwordButtonView = UIButton()
    let debugIconView = UILabel()
    let debugLabelView = UILabel()
    let debugSwitchView = UISwitch()
    
    required init(userId: Int) {
        viewModel = EditProfileViewModel(id: userId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        viewModel = EditProfileViewModel(id: 0)
        super.init(coder: aDecoder)
    }
    
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
        
        nameIconView.font = .icomoonOfSize(20)
        nameIconView.text = .icomoonWithName(.VCard)
        nameIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(nameIconView)
        
        nameInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        nameInputView.textColor = UIColor(0x4d4d4d)
        nameInputView.autocorrectionType = .No
        nameInputView.rac_text <~ viewModel.name
        nameInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.name.value = $0 as! String })
        view.addSubview(nameInputView)
        
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
        
        bioIconView.font = .icomoonOfSize(20)
        bioIconView.text = .icomoonWithName(.InfoWithCircle)
        bioIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(bioIconView)
        
        bioInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        bioInputView.textColor = UIColor(0x4d4d4d)
        bioInputView.rac_text <~ viewModel.bio
        bioInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.bio.value = $0 as! String })
        bioInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        bioInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        view.addSubview(bioInputView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(lineView)
        
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
        
        nameIconView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: 5)
        nameIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        nameIconView.autoSetDimension(.Width, toSize: 20)
        
        nameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: nameIconView, withOffset: 0)
        nameInputView.autoPinEdge(.Left, toEdge: .Right, ofView: nameIconView, withOffset: 15)
        nameInputView.autoPinEdge(.Right, toEdge: .Left, ofView: avatarImageView, withOffset: -20)
        
        userNameIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameInputView, withOffset: 30)
        userNameIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        userNameIconView.autoSetDimension(.Width, toSize: 20)
        
        userNameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: userNameIconView, withOffset: 0)
        userNameInputView.autoPinEdge(.Left, toEdge: .Right, ofView: userNameIconView, withOffset: 15)
        userNameInputView.autoPinEdge(.Right, toEdge: .Right, ofView: nameInputView)
        
        bioIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: userNameInputView, withOffset: 30)
        bioIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        bioIconView.autoSetDimension(.Width, toSize: 20)
        
        bioInputView.autoPinEdge(.Top, toEdge: .Top, ofView: bioIconView, withOffset: 0)
        bioInputView.autoPinEdge(.Left, toEdge: .Right, ofView: bioIconView, withOffset: 15)
        bioInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        bioInputView.autoSetDimension(.Height, toSize: 80)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: bioInputView, withOffset: 10)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        emailIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: lineView, withOffset: 30)
        emailIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        emailIconView.autoSetDimension(.Width, toSize: 20)

        emailInputView.autoPinEdge(.Top, toEdge: .Top, ofView: emailIconView, withOffset: 0)
        emailInputView.autoPinEdge(.Left, toEdge: .Right, ofView: emailIconView, withOffset: 15)
        emailInputView.autoPinEdge(.Right, toEdge: .Right, ofView: nameInputView)
        
        passwordIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailInputView, withOffset: 30)
        passwordIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        passwordIconView.autoSetDimension(.Width, toSize: 20)

        passwordButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: passwordIconView, withOffset: -4)
        passwordButtonView.autoPinEdge(.Left, toEdge: .Right, ofView: passwordIconView, withOffset: 15)
        passwordButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: nameInputView)
        
        debugIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordButtonView, withOffset: 30)
        debugIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        debugIconView.autoSetDimension(.Width, toSize: 20)
        
        debugLabelView.autoPinEdge(.Top, toEdge: .Top, ofView: debugIconView, withOffset: -1)
        debugLabelView.autoPinEdge(.Left, toEdge: .Right, ofView: debugIconView, withOffset: 15)
        debugLabelView.autoPinEdge(.Right, toEdge: .Right, ofView: nameInputView)
        
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