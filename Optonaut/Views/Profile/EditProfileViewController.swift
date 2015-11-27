//
//  EditProfileViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import HexColor
import Mixpanel
import SwiftyUserDefaults

class EditProfileViewController: UIViewController, RedNavbar {
    
    let imagePickerController = UIImagePickerController()
    
    let viewModel = EditProfileViewModel()
    
    // subviews
    let avatarImageView = PlaceholderImageView()
    let displayNameIconView = UILabel()
    let displayNameInputView = BottomLineTextField()
    let userNameIconView = UILabel()
    let userNameInputView = BottomLineTextField()
    let userNameTakenView = UILabel()
    let descriptionIconView = UILabel()
    let textInputView = UITextView()
    let privateHeaderView = UILabel()
    let emailIconView = UILabel()
    let emailView = UILabel()
    let emailButtonView = UIButton()
    let passwordIconView = UILabel()
    let passwordView = UILabel()
    let passwordButtonView = UIButton()
    let settingsHeaderView = UILabel()
    let debugIconView = UILabel()
    let debugLabelView = UILabel()
    let debugSwitchView = UISwitch()
//    let newsletterIconView = UILabel()
//    let newsletterLabelView = UILabel()
//    let newsletterSwitchView = UISwitch()
    
    private var confirmAlertAction: UIAlertAction?
    
    deinit {
        logRetain()
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
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "updateImage"))
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        view.addSubview(avatarImageView)
        
        displayNameIconView.font = .icomoonOfSize(20)
        displayNameIconView.text = .icomoonWithName(.VCard)
        displayNameIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(displayNameIconView)
        
        displayNameInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        displayNameInputView.textColor = UIColor(0x4d4d4d)
        displayNameInputView.autocorrectionType = .No
        displayNameInputView.rac_text <~ viewModel.displayName
        displayNameInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.displayName.value = $0 as! String }
        view.addSubview(displayNameInputView)
        
        userNameIconView.font = .icomoonOfSize(20)
        userNameIconView.text = .icomoonWithName(.Email)
        userNameIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(userNameIconView)
        
        userNameInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        userNameInputView.textColor = UIColor(0x4d4d4d)
        userNameInputView.autocorrectionType = .No
        userNameInputView.autocapitalizationType = .None
        userNameInputView.rac_text <~ viewModel.userName
        userNameInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.userName.value = $0 as! String }
        
        view.addSubview(userNameInputView)
        
        userNameTakenView.text = "Username taken"
        userNameTakenView.font = UIFont.robotoOfSize(13, withType: .Regular)
        userNameTakenView.textColor = UIColor.Accent
        userNameTakenView.rac_hidden <~ viewModel.userNameTaken.producer.map(negate)
        
        view.addSubview(userNameTakenView)
        
        descriptionIconView.font = .icomoonOfSize(20)
        descriptionIconView.text = .icomoonWithName(.InfoWithCircle)
        descriptionIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(descriptionIconView)
        
        textInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.rac_text <~ viewModel.text
        textInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.text.value = $0 as! String }
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        view.addSubview(textInputView)
        
        privateHeaderView.text = "PRIVATE INFORMATION"
        privateHeaderView.textColor = UIColor(0xcfcfcf)
        privateHeaderView.font = UIFont.robotoOfSize(15, withType: .Medium)
        view.addSubview(privateHeaderView)
        
        emailIconView.font = .icomoonOfSize(20)
        emailIconView.text = .icomoonWithName(.PaperPlane)
        emailIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(emailIconView)
        
        emailView.font = UIFont.robotoOfSize(15, withType: .Regular)
        emailView.textColor = UIColor(0xcfcfcf)
        emailView.rac_text <~ viewModel.email
        view.addSubview(emailView)
        
        emailButtonView.titleEdgeInsets = UIEdgeInsetsZero
        emailButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Medium)
        emailButtonView.contentHorizontalAlignment = .Left
        emailButtonView.setTitleColor(UIColor(0x4d4d4d), forState: .Normal)
        emailButtonView.setTitle("Change", forState: .Normal)
        emailButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showEmailAlert"))
        view.addSubview(emailButtonView)
        
        passwordIconView.font = .icomoonOfSize(20)
        passwordIconView.text = .icomoonWithName(.Lock)
        passwordIconView.textColor = UIColor(0xe5e5e5)
        view.addSubview(passwordIconView)
        
        passwordView.font = UIFont.robotoOfSize(15, withType: .Regular)
        passwordView.textColor = UIColor(0xcfcfcf)
        passwordView.text = "*********"
        view.addSubview(passwordView)
        
        passwordButtonView.titleEdgeInsets = UIEdgeInsetsZero
        passwordButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Medium)
        passwordButtonView.contentHorizontalAlignment = .Left
        passwordButtonView.setTitleColor(UIColor(0x4d4d4d), forState: .Normal)
        passwordButtonView.setTitle("Change", forState: .Normal)
        passwordButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showPasswordAlert"))
        view.addSubview(passwordButtonView)
        
        settingsHeaderView.text = "SETTINGS"
        settingsHeaderView.textColor = UIColor(0xcfcfcf)
        settingsHeaderView.font = UIFont.robotoOfSize(15, withType: .Medium)
        settingsHeaderView.hidden = true
        view.addSubview(settingsHeaderView)
       
        // since we need debug for developing.
        debugIconView.font = .icomoonOfSize(20)
        debugIconView.text = .icomoonWithName(.Cog)
        debugIconView.textColor = UIColor(0xe5e5e5)
        debugIconView.hidden = true
        view.addSubview(debugIconView)
        
        debugLabelView.text = "Debugging"
        debugLabelView.textColor = UIColor(0x4d4d4d)
        debugLabelView.font = .robotoOfSize(15, withType: .Regular)
        debugLabelView.hidden = true
        view.addSubview(debugLabelView)
        
        debugSwitchView.on = viewModel.debugEnabled.value
        debugSwitchView.addTarget(self, action: "toggleDebug", forControlEvents: .ValueChanged)
        debugSwitchView.hidden = true
        view.addSubview(debugSwitchView)
        
        #if DEBUG
            settingsHeaderView.hidden = false
            debugIconView.hidden = false
            debugLabelView.hidden = false
            debugSwitchView.hidden = false
        #endif
        
//        newsletterIconView.font = .icomoonOfSize(20)
//        newsletterIconView.text = .icomoonWithName(.Cog)
//        newsletterIconView.textColor = UIColor(0xe5e5e5)
//        view.addSubview(newsletterIconView)
//        
//        newsletterLabelView.text = "Newsletter"
//        newsletterLabelView.textColor = UIColor(0x4d4d4d)
//        newsletterLabelView.font = .robotoOfSize(15, withType: .Regular)
//        view.addSubview(newsletterLabelView)
//        
//        newsletterSwitchView.on = viewModel.wantsNewsletter.value
//        newsletterSwitchView.addTarget(self, action: "toggleNewsletter", forControlEvents: .ValueChanged)
//        view.addSubview(newsletterSwitchView)
        
        imagePickerController.navigationBar.translucent = false
        imagePickerController.navigationBar.barTintColor = UIColor.Accent
        imagePickerController.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.robotoOfSize(17, withType: .Medium),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 25)
        avatarImageView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 60, height: 60))
        
        displayNameIconView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: 5)
        displayNameIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        displayNameIconView.autoSetDimension(.Width, toSize: 20)
        
        displayNameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: displayNameIconView)
        displayNameInputView.autoPinEdge(.Left, toEdge: .Right, ofView: displayNameIconView, withOffset: 15)
        displayNameInputView.autoPinEdge(.Right, toEdge: .Left, ofView: avatarImageView, withOffset: -20)
        
        userNameIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameInputView, withOffset: 30)
        userNameIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        userNameIconView.autoSetDimension(.Width, toSize: 20)
        
        userNameInputView.autoPinEdge(.Top, toEdge: .Top, ofView: userNameIconView)
        userNameInputView.autoPinEdge(.Left, toEdge: .Right, ofView: userNameIconView, withOffset: 15)
        userNameInputView.autoPinEdge(.Right, toEdge: .Right, ofView: displayNameInputView)
        
        userNameTakenView.autoPinEdge(.Top, toEdge: .Top, ofView: userNameIconView, withOffset: 2)
        userNameTakenView.autoPinEdge(.Right, toEdge: .Right, ofView: userNameInputView)
        
        descriptionIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: userNameInputView, withOffset: 30)
        descriptionIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        descriptionIconView.autoSetDimension(.Width, toSize: 20)
        
        textInputView.autoPinEdge(.Top, toEdge: .Top, ofView: descriptionIconView)
        textInputView.autoPinEdge(.Left, toEdge: .Right, ofView: descriptionIconView, withOffset: 15)
        textInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        textInputView.autoSetDimension(.Height, toSize: 80)
        
        privateHeaderView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textInputView, withOffset: 10)
        privateHeaderView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        
        emailIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: privateHeaderView, withOffset: 30)
        emailIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        emailIconView.autoSetDimension(.Width, toSize: 20)

        emailView.autoPinEdge(.Top, toEdge: .Top, ofView: emailIconView)
        emailView.autoPinEdge(.Left, toEdge: .Right, ofView: emailIconView, withOffset: 15)
        
        emailButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: emailIconView, withOffset: -4)
        emailButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
        passwordIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: emailView, withOffset: 30)
        passwordIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        passwordIconView.autoSetDimension(.Width, toSize: 20)

        passwordView.autoPinEdge(.Top, toEdge: .Top, ofView: passwordIconView)
        passwordView.autoPinEdge(.Left, toEdge: .Right, ofView: passwordIconView, withOffset: 15)

        passwordButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: passwordIconView, withOffset: -4)
        passwordButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
        settingsHeaderView.autoPinEdge(.Top, toEdge: .Bottom, ofView: passwordButtonView, withOffset: 10)
        settingsHeaderView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        
        debugIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: settingsHeaderView, withOffset: 20)
        debugIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        debugIconView.autoSetDimension(.Width, toSize: 20)
        
        debugLabelView.autoPinEdge(.Top, toEdge: .Top, ofView: debugIconView, withOffset: -1)
        debugLabelView.autoPinEdge(.Left, toEdge: .Right, ofView: debugIconView, withOffset: 15)
        debugLabelView.autoPinEdge(.Right, toEdge: .Right, ofView: displayNameInputView)
        
        debugSwitchView.autoPinEdge(.Top, toEdge: .Top, ofView: debugIconView, withOffset: -4)
        debugSwitchView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
//        newsletterIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: debugIconView, withOffset: 20)
//        newsletterIconView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
//        newsletterIconView.autoSetDimension(.Width, toSize: 20)
//
//        newsletterLabelView.autoPinEdge(.Top, toEdge: .Top, ofView: newsletterIconView, withOffset: -1)
//        newsletterLabelView.autoPinEdge(.Left, toEdge: .Right, ofView: newsletterIconView, withOffset: 15)
//        newsletterLabelView.autoPinEdge(.Right, toEdge: .Right, ofView: displayNameInputView)
//
//        newsletterSwitchView.autoPinEdge(.Top, toEdge: .Top, ofView: newsletterIconView, withOffset: -4)
//        newsletterSwitchView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
        super.updateViewConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.EditProfile")
        
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
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.EditProfile")
    }
    
    func toggleDebug() {
        viewModel.toggleDebug()
    }
    
    func toggleNewsletter() {
        viewModel.toggleNewsletter()
    }
    
    func cancel() {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func save() {
        viewModel.updateData()
            .on(
                error: { _ in
                    NotificationService.push("Profile information invalid.", level: .Error)
                },
                completed: {
                    self.navigationController?.popViewControllerAnimated(false)
                    NotificationService.push("Profile information updated.", level: .Success)
                }
            )
            .start()
    }
    
    func showPasswordAlert() {
        let oldPasswordAlert = UIAlertController(title: "Current Password", message: "Please enter your current password.", preferredStyle: .Alert)
        let newPasswordAlert = UIAlertController(title: "New Password", message: "Please enter your new password. (At least 5 characters.)", preferredStyle: .Alert)
        
        oldPasswordAlert.addTextFieldWithConfigurationHandler { textField in
            textField.secureTextEntry = true
            textField.text = ""
        }
        
        oldPasswordAlert.addAction(UIAlertAction(title: "Continue", style: .Default, handler: { _ in
            let oldPasswordtextField = oldPasswordAlert.textFields![0] as UITextField
            if oldPasswordtextField.text == Defaults[.SessionPassword] {
                self.presentViewController(newPasswordAlert, animated: true, completion: nil)
            } else {
                oldPasswordAlert.message = "Your current password was wrong. Please try again."
                oldPasswordtextField.text = ""
                self.presentViewController(oldPasswordAlert, animated: true, completion: nil)
            }
        }))
        
        oldPasswordAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        newPasswordAlert.addTextFieldWithConfigurationHandler { textField in
            textField.secureTextEntry = true
            textField.text = ""
        }
        
        newPasswordAlert.addAction(UIAlertAction(title: "Change Password", style: .Destructive, handler: { _ in
            let oldPasswordtextField = oldPasswordAlert.textFields![0] as UITextField
            let newPasswordtextField = newPasswordAlert.textFields![0] as UITextField
            let oldPassword = oldPasswordtextField.text!
            let newPassword = newPasswordtextField.text!
            self.viewModel.updatePassword(oldPassword, newPassword: newPassword).startWithCompleted {
                NotificationService.push("Password changed successfully.", level: .Success)
            }
        }))
        
        newPasswordAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(oldPasswordAlert, animated: true, completion: nil)
    }
    
    func showEmailAlert() {
        let alert = UIAlertController(title: "New Email Address", message: "Please enter your new email address. We will send you an email to reconfirm it.", preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.text = ""
            textField.keyboardType = .EmailAddress
            textField.placeholder = self.viewModel.email.value
        }
        
        confirmAlertAction = UIAlertAction(title: "Change Email", style: .Destructive, handler: { [weak self] _ in
            let textField = alert.textFields![0] as UITextField
            let email = textField.text!
            self?.viewModel.updateEmail(email)
                .on(
                    error: { _ in
                        NotificationService.push("Email address already taken. Please try another one.", level: .Error)
                    },
                    completed: {
                        NotificationService.push("Please check your inbox and confirm your new address.", level: .Success)
                    }
                )
                .start()
            
            self?.confirmAlertAction = nil
        })
        
        
        let textField = alert.textFields![0] as UITextField
        textField.delegate = self
        
        confirmAlertAction!.enabled = false
        
        alert.addAction(confirmAlertAction!)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateImage() {
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            imagePickerController.sourceType = .PhotoLibrary
            imagePickerController.delegate = self
            self.presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

extension EditProfileViewController: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let email = NSString(string: textField.text!).stringByReplacingCharactersInRange(range, withString: string)
        confirmAlertAction?.enabled = isValidEmail(email)
        
        return true
    }
    
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let fixedImage = image.fixedOrientation().centeredCropWithSize(CGSize(width: 1024, height: 1024))
        avatarImageView.image = fixedImage
        viewModel.updateAvatar(fixedImage).startWithCompleted {
            NotificationService.push("Profile image updated", level: .Success)
        }
    }
    
}