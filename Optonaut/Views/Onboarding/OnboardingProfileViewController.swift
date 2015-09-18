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
    private let fullNameView = UILabel()
    private let fullNameInputView = RoundedTextField()
    private let userNameView = UILabel()
    private let userNameInputView = RoundedTextField()
    private let termsView = UILabel()
    private let nextButtonView = HatchedButton()
    private let dotProgressView = DotProgressView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        headlineView.text = "FIRST CREATE YOUR PROFILE"
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
        
        fullNameView.rac_text <~ viewModel.fullName
        fullNameView.rac_hidden <~ viewModel.fullNameEditing
        fullNameView.textColor = .DarkGrey
        fullNameView.font = UIFont.robotoOfSize(16, withType: .Bold)
        fullNameView.textAlignment = .Center
        fullNameView.userInteractionEnabled = true
        fullNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editFullName"))
        view.addSubview(fullNameView)
        
        fullNameInputView.placeholder = "What's your name?"
        fullNameInputView.returnKeyType = .Next
        fullNameInputView.delegate = self
        fullNameInputView.rac_userInteractionEnabled <~ viewModel.fullNameEnabled
        fullNameInputView.rac_hidden <~ viewModel.fullNameEditing.producer.map(negate)
        fullNameInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.fullName.value = $0 as! String }
        viewModel.fullNameIndicated.producer.startWithNext { self.fullNameInputView.indicated = $0 }
        view.addSubview(fullNameInputView)
        
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
        
        let contentHeight: CGFloat = 400
        let statusBarOffset: CGFloat = 20
        let buttonOffset: CGFloat = 106
        let topOffset = (view.bounds.height - statusBarOffset - buttonOffset - contentHeight) / 2 + statusBarOffset + 5
        
        headlineView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        headlineView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: topOffset)
        
        uploadButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        uploadButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: headlineView, withOffset: 30)
        uploadButtonView.autoSetDimension(.Height, toSize: 180)
        uploadButtonView.autoSetDimension(.Width, toSize: 180)
        
        avatarImageView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        avatarImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: headlineView, withOffset: 40)
        avatarImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: uploadButtonView)
        avatarImageView.autoMatchDimension(.Height, toDimension: .Height, ofView: uploadButtonView)
        
        fullNameInputView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        fullNameInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: uploadButtonView, withOffset: 30)
        fullNameInputView.autoSetDimension(.Width, toSize: 240)
        
        fullNameView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        fullNameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: uploadButtonView, withOffset: 60)
        fullNameView.autoSetDimension(.Width, toSize: 240)
        
        userNameInputView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        userNameInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: fullNameInputView, withOffset: 40)
        userNameInputView.autoSetDimension(.Width, toSize: 240)
        
        userNameView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        userNameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: fullNameView, withOffset: 10)
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
        viewModel.fullNameEditing.value = true
        fullNameInputView.becomeFirstResponder()
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
        if textField == fullNameInputView {
            viewModel.fullNameEditing.value = viewModel.fullName.value.isEmpty
        }
        
        if textField == userNameInputView {
            viewModel.userNameEditing.value = viewModel.userName.value.isEmpty || viewModel.userNameTaken.value
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == fullNameInputView {
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