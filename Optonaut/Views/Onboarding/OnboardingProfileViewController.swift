//
//  OnboardingProfileViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import HexColor
import ReactiveCocoa
import Async

class OnboardingProfileViewController: UIViewController, UINavigationControllerDelegate {
    
    let imagePickerController = UIImagePickerController()
    
    private let viewModel = OnboardingProfileViewModel()
    
    // subviews
    private let scrollView = UIScrollView()
    private let headlineTextView = UILabel()
    private let uploadButtonView = HatchedButton()
    private let avatarImageView = UIImageView()
    private let displayNameInputView = RoundedTextField()
    private let userNameInputView = RoundedTextField()
    private let termsView = UILabel()
    private let nextButtonView = HatchedButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .Accent
        
    
        viewModel.nextStep.producer
            .map { state in
                switch state {
                case .Avatar: return "Upload your profile picture"
                case .DisplayName: return "How should we call you?"
                case .UserName: return "Pick a username"
                case .Done: return "Looking good!"
                }
            }
            .startWithNext { self.headlineTextView.text = $0 }
        headlineTextView.numberOfLines = 1
        headlineTextView.textAlignment = .Center
        headlineTextView.textColor = .whiteColor()
        headlineTextView.font = UIFont.displayOfSize(25, withType: .Thin)
        view.addSubview(headlineTextView)
        
        uploadButtonView.setTitle(String.icomoonWithName(.LnrCamera), forState: .Normal)
        uploadButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        uploadButtonView.titleLabel?.font = UIFont.icomoonOfSize(35)
        uploadButtonView.defaultBackgroundColor = UIColor.whiteColor().alpha(0.3)
        uploadButtonView.layer.cornerRadius = 52
        uploadButtonView.layer.borderColor = UIColor.whiteColor().CGColor
        uploadButtonView.layer.borderWidth = 1.5
        uploadButtonView.rac_hidden <~ viewModel.avatarUploaded
        uploadButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "uploadImage"))
        view.addSubview(uploadButtonView)
        
        avatarImageView.rac_hidden <~ viewModel.avatarUploaded.producer.map(negate)
        avatarImageView.layer.cornerRadius = 52
        avatarImageView.layer.borderColor = UIColor.whiteColor().CGColor
        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .ScaleAspectFill
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "uploadImage"))
        view.addSubview(avatarImageView)
        
        displayNameInputView.size = .Large
        displayNameInputView.color = .Light
        displayNameInputView.placeholder = "Your name"
        displayNameInputView.returnKeyType = .Next
        displayNameInputView.delegate = self
        displayNameInputView.rac_status <~ viewModel.displayNameStatus
        displayNameInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.displayName.value = $0 as! String }
        view.addSubview(displayNameInputView)
        
        userNameInputView.size = .Large
        userNameInputView.color = .Light
        userNameInputView.placeholder = "Your username"
        userNameInputView.autocorrectionType = .No
        userNameInputView.autocapitalizationType = .None
        userNameInputView.returnKeyType = .Done
        userNameInputView.delegate = self
        userNameInputView.rac_status <~ viewModel.userNameStatus
        userNameInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.userName.value = $0 as! String }
//        viewModel.userNameIndicated.producer.startWithNext { self.userNameInputView.indicated = $0 }
//        viewModel.userNameTaken.producer.startWithNext { userNameTaken in
//            if userNameTaken {
//                self.userNameInputView.message = .Warning("Damn it. This username is already gone.")
//            } else {
//                self.userNameInputView.message = .Nil
//            }
//        }
        view.addSubview(userNameInputView)
        
        let termsTextStr = "By creating your profile you accept\r\nour terms and conditions"
        let normalRange = termsTextStr.NSRangeOfString("By creating your profile you accept")
        let linkRange = termsTextStr.NSRangeOfString("our terms and conditions")
        let attrString = NSMutableAttributedString(string: termsTextStr)
        attrString.addAttribute(NSFontAttributeName, value: UIFont.displayOfSize(12, withType: .Thin), range: normalRange!)
        attrString.addAttribute(NSFontAttributeName, value: UIFont.displayOfSize(12, withType: .Semibold), range: linkRange!)
        termsView.attributedText = attrString
        termsView.textColor = .whiteColor()
        termsView.numberOfLines = 2
        termsView.textAlignment = .Center
        termsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "openTerms"))
        view.addSubview(termsView)
        
        nextButtonView.setTitle("Create profile", forState: .Normal)
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showHashtagOnboarding"))
        view.addSubview(nextButtonView)
        
        viewModel.nextStep.producer
            .startWithNext { state in
                if case .Done = state {
                    self.termsView.alpha = 1
                    self.nextButtonView.alpha = 1
                    self.termsView.userInteractionEnabled = true
                    self.nextButtonView.userInteractionEnabled = true
                } else {
                    self.termsView.alpha = 0.2
                    self.nextButtonView.alpha = 0.2
                    self.termsView.userInteractionEnabled = false
                    self.nextButtonView.userInteractionEnabled = false
                }
            }
        
        imagePickerController.navigationBar.translucent = false
        imagePickerController.navigationBar.tintColor = UIColor.DarkGrey
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        headlineTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        headlineTextView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 75)
        headlineTextView.autoSetDimension(.Width, toSize: 300)
        
        uploadButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        uploadButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: headlineTextView, withOffset: 33)
        uploadButtonView.autoSetDimension(.Height, toSize: 104)
        uploadButtonView.autoSetDimension(.Width, toSize: 104)
        
        avatarImageView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        avatarImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: headlineTextView, withOffset: 33)
        avatarImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: uploadButtonView)
        avatarImageView.autoMatchDimension(.Height, toDimension: .Height, ofView: uploadButtonView)
        
        displayNameInputView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        displayNameInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: uploadButtonView, withOffset: 60)
        displayNameInputView.autoSetDimension(.Width, toSize: 240)
        
        userNameInputView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        userNameInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameInputView, withOffset: 40)
        userNameInputView.autoSetDimension(.Width, toSize: 240)
        
        termsView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        termsView.autoPinEdge(.Bottom, toEdge: .Top, ofView: nextButtonView, withOffset: -15)
        termsView.autoSetDimension(.Width, toSize: 300)
        
        nextButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        nextButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -42)
        nextButtonView.autoSetDimension(.Height, toSize: 60)
        nextButtonView.autoSetDimension(.Width, toSize: 223)
        
        super.updateViewConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        view.frame.origin.y = -keyboardHeight + 120
    }
    
    func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
    
    func uploadImage() {
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            imagePickerController.sourceType = .PhotoLibrary
            imagePickerController.allowsEditing = true
            imagePickerController.delegate = self
            self.presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func openTerms() {
        UIApplication.sharedApplication().openURL(NSURL(string:"http://optonaut.co/terms/")!)
    }
    
    func showHashtagOnboarding() {
        viewModel.updateData().startWithCompleted {
            self.presentViewController(OnboardingHashtagInfoViewController(), animated: false, completion: nil)
        }
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension OnboardingProfileViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        avatarImageView.image = image
        viewModel.updateAvatar(image).start()
    }
    
}

// MARK: - UITextFieldDelegate
extension OnboardingProfileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == displayNameInputView {
            Async.main {
                userNameInputView.becomeFirstResponder()
            }
        }
        
        if textField == userNameInputView {
            view.endEditing(true)
        }
        
        return true
    }
    
}