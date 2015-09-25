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
    private let headlineView = UILabel()
    private let uploadButtonView = HatchedButton()
    private let avatarImageView = UIImageView()
    private let displayNameView = UILabel()
    private let displayNameInputView = RoundedTextField()
    private let userNameView = UILabel()
    private let userNameInputView = RoundedTextField()
    private let termsView = UILabel()
    private let nextButtonView = HatchedButton()
    private let dotProgressView = DotProgressView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
    
        viewModel.state.producer.startWithNext { state in
            switch state {
            case .Avatar: self.headlineView.text = "FIRST UPLOAD A PICTURE OF YOU"
            case .FullName: self.headlineView.text = "PLEASE ENTER YOUR NAME"
            case .UserName: self.headlineView.text = "NOW CHOOSE YOUR USERNAME"
            case .Done: self.headlineView.text = "WELL DONE"
            }
        }
        headlineView.textColor = UIColor.Accent
        headlineView.textAlignment = .Center
        headlineView.font = UIFont.robotoOfSize(16, withType: .Bold)
        view.addSubview(headlineView)
        
        uploadButtonView.setTitle(String.icomoonWithName(.LnrCamera), forState: .Normal)
        uploadButtonView.titleLabel?.font = UIFont.icomoonOfSize(60)
        uploadButtonView.layer.cornerRadius = 90
        uploadButtonView.rac_hidden <~ viewModel.avatarUploaded
        uploadButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "uploadImage"))
        view.addSubview(uploadButtonView)
        
        avatarImageView.rac_hidden <~ viewModel.avatarUploaded.producer.map(negate)
        avatarImageView.layer.cornerRadius = 90
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .ScaleAspectFill
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "uploadImage"))
        view.addSubview(avatarImageView)
        
        displayNameView.rac_text <~ viewModel.displayName
        displayNameView.rac_hidden <~ viewModel.displayNameEditing
        displayNameView.textColor = .DarkGrey
        displayNameView.font = UIFont.robotoOfSize(16, withType: .Bold)
        displayNameView.textAlignment = .Center
        displayNameView.userInteractionEnabled = true
        displayNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editFullName"))
        view.addSubview(displayNameView)
        
        displayNameInputView.placeholder = "What's your name?"
        displayNameInputView.returnKeyType = .Next
        displayNameInputView.delegate = self
        displayNameInputView.rac_alpha <~ viewModel.displayNameEnabled.producer.map { $0 ? 1 : 0.3 }
        displayNameInputView.rac_userInteractionEnabled <~ viewModel.displayNameEnabled
        displayNameInputView.rac_hidden <~ viewModel.displayNameEditing.producer.map(negate)
        displayNameInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.displayName.value = $0 as! String }
        viewModel.displayNameIndicated.producer.startWithNext { self.displayNameInputView.indicated = $0 }
        view.addSubview(displayNameInputView)
        
        userNameView.rac_text <~ viewModel.userName.producer.map { "@\($0)" }
        userNameView.rac_hidden <~ viewModel.userNameEditing
        userNameView.textColor = .Grey
        userNameView.font = UIFont.robotoOfSize(16, withType: .Regular)
        userNameView.textAlignment = .Center
        userNameView.userInteractionEnabled = true
        userNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editUserName"))
        view.addSubview(userNameView)
        
        userNameInputView.placeholder = "Pick a username"
        userNameInputView.autocorrectionType = .No
        userNameInputView.autocapitalizationType = .None
        userNameInputView.returnKeyType = .Done
        userNameInputView.delegate = self
        userNameInputView.rac_alpha <~ viewModel.userNameEnabled.producer.map { $0 ? 1 : (self.viewModel.displayNameEnabled.value ? 0.3 : 0.2) }
        userNameInputView.rac_userInteractionEnabled <~ viewModel.userNameEnabled
        userNameInputView.rac_hidden <~ viewModel.userNameEditing.producer.map(negate)
        userNameInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.userName.value = $0 as! String }
        viewModel.userNameIndicated.producer.startWithNext { self.userNameInputView.indicated = $0 }
        viewModel.userNameTaken.producer.startWithNext { userNameTaken in
            if userNameTaken {
                self.userNameInputView.message = .Warning("Damn it. This username is already gone.")
            } else {
                self.userNameInputView.message = .Nil
            }
        }
        view.addSubview(userNameInputView)
        
        let attrString = NSMutableAttributedString(string: "By pressing next you agree with our terms")
        attrString.addAttribute(NSForegroundColorAttributeName, value: UIColor.Grey, range: NSRange(location: 0, length: 27))
        attrString.addAttribute(NSForegroundColorAttributeName, value: UIColor.Accent, range: NSRange(location: 27, length: 14))
        termsView.attributedText = attrString
        termsView.font = UIFont.robotoOfSize(14, withType: .Regular)
        termsView.userInteractionEnabled = true
        termsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "openTerms"))
        termsView.rac_hidden <~ viewModel.dataComplete.producer.map(negate)
        view.addSubview(termsView)
        
        nextButtonView.setTitle("NEXT", forState: .Normal)
        nextButtonView.rac_hidden <~ viewModel.dataComplete.producer.map(negate)
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushHashtagOnboarding"))
        view.addSubview(nextButtonView)
        
        dotProgressView.numberOfDots = 3
        dotProgressView.activeIndex = 1
        view.addSubview(dotProgressView)
        
        imagePickerController.navigationBar.translucent = false
        imagePickerController.navigationBar.tintColor = UIColor.DarkGrey
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        let contentHeight: CGFloat = 350
        let statusBarOffset: CGFloat = 80
        let buttonOffset: CGFloat = 106
        let topOffset = (view.bounds.height - statusBarOffset - buttonOffset - contentHeight) / 2 + statusBarOffset + 5
        
        headlineView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        headlineView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: topOffset / 2)
        
        uploadButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        uploadButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: topOffset)
        uploadButtonView.autoSetDimension(.Height, toSize: 180)
        uploadButtonView.autoSetDimension(.Width, toSize: 180)
        
        avatarImageView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: topOffset)
        avatarImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: uploadButtonView)
        avatarImageView.autoMatchDimension(.Height, toDimension: .Height, ofView: uploadButtonView)
        
        displayNameInputView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        displayNameInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: uploadButtonView, withOffset: 30)
        displayNameInputView.autoSetDimension(.Width, toSize: 240)
        
        displayNameView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        displayNameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: uploadButtonView, withOffset: 60)
        displayNameView.autoSetDimension(.Width, toSize: 240)
        
        userNameInputView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        userNameInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameInputView, withOffset: 40)
        userNameInputView.autoSetDimension(.Width, toSize: 240)
        
        userNameView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        userNameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameView, withOffset: 10)
        userNameView.autoSetDimension(.Width, toSize: 240)
        
        termsView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        termsView.autoPinEdge(.Bottom, toEdge: .Top, ofView: nextButtonView, withOffset: -15)
        
        nextButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        nextButtonView.autoPinEdge(.Bottom, toEdge: .Top, ofView: dotProgressView, withOffset: -20)
        nextButtonView.autoSetDimension(.Height, toSize: 50)
        nextButtonView.autoSetDimension(.Width, toSize: 230)
        
        dotProgressView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        dotProgressView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -30)
        dotProgressView.autoSetDimension(.Height, toSize: 6)
        dotProgressView.autoSetDimension(.Width, toSize: 230)
        
        super.updateViewConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: false)
        
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
    
    func editFullName() {
        viewModel.displayNameEditing.value = true
        displayNameInputView.becomeFirstResponder()
    }
    
    func editUserName() {
        viewModel.userNameEditing.value = true
        userNameInputView.becomeFirstResponder()
    }
    
    func openTerms() {
        UIApplication.sharedApplication().openURL(NSURL(string:"http://optonaut.co/terms")!)
    }
    
    func pushHashtagOnboarding() {
        presentViewController(OnboardingHashtagViewController(), animated: false, completion: nil)
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
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == displayNameInputView {
            viewModel.displayNameEditing.value = viewModel.displayName.value.isEmpty
        }
        
        if textField == userNameInputView {
            viewModel.userNameEditing.value = viewModel.userName.value.isEmpty || viewModel.userNameTaken.value
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == displayNameInputView {
            Async.main {
                self.editUserName()
            }
        }
        
        if textField == userNameInputView {
            view.endEditing(true)
        }
        
        return true
    }
    
}