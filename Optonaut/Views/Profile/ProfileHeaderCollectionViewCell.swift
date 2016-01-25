//
//  ProfileHeaderCollectionViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 23/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SwiftyUserDefaults
import KMPlaceholderTextView

class ProfileHeaderCollectionViewCell: UICollectionViewCell {
    
    weak var navigationController: NavigationController?
    
    private lazy var imagePickerController = UIImagePickerController()
    
    weak var viewModel: ProfileViewModel!
    var isMe = false
    
    // subviews
    private let avatarImageView = PlaceholderImageView()
    private let displayNameView = UILabel()
    private let displayNameInputView = KMPlaceholderTextView()
    private let textView = UILabel()
    private let textInputView = KMPlaceholderTextView()
    private let buttonView = UIButton()
    private let buttonIconView = UILabel()
    private let postHeadingView = UILabel()
    private let postCountView = UILabel()
    private let followersHeadingView = UILabel()
    private let followersCountView = UILabel()
    private let followingHeadingView = UILabel()
    private let followingCountView = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        print("iniiit")
        
        contentView.backgroundColor = .whiteColor()
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.clipsToBounds = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "updateImage"))
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.displayOfSize(15, withType: .Semibold)
        displayNameView.textColor = .Accent
        displayNameView.textAlignment = .Center
        contentView.addSubview(displayNameView)
        
        displayNameInputView.placeholder = "Enter your name"
        displayNameInputView.font = UIFont.displayOfSize(15, withType: .Semibold)
        displayNameInputView.textAlignment = .Center
        displayNameInputView.textColor = .Accent
        displayNameInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        displayNameInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        displayNameInputView.returnKeyType = .Done
        displayNameInputView.delegate = self
        contentView.addSubview(displayNameInputView)
        
        textView.numberOfLines = 0
        textView.textAlignment = .Center
        textView.font = UIFont.displayOfSize(12, withType: .Regular)
        textView.textColor = UIColor(0x979797)
        contentView.addSubview(textView)
        
        textInputView.placeholder = "Add description"
        textInputView.font = UIFont.displayOfSize(12, withType: .Regular)
        textInputView.textAlignment = .Center
        textInputView.textColor = UIColor(0x979797)
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        textInputView.returnKeyType = .Done
        textInputView.delegate = self
        contentView.addSubview(textInputView)
        
        buttonIconView.font = UIFont.iconOfSize(12)
        buttonIconView.textColor = .whiteColor()
        buttonView.addSubview(buttonIconView)
        
        buttonView.backgroundColor = UIColor(0xcacaca)
        buttonView.layer.cornerRadius = 5
        buttonView.layer.masksToBounds = true
        buttonView.setTitleColor(.whiteColor(), forState: .Normal)
        buttonView.titleLabel?.font = .displayOfSize(11, withType: .Semibold)
        buttonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapButton"))
        contentView.addSubview(buttonView)
        
        postHeadingView.text = "Posts"
        postHeadingView.textAlignment = .Center
        postHeadingView.font = .displayOfSize(12, withType: .Semibold)
        postHeadingView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(postHeadingView)
        
        postCountView.font = .displayOfSize(12, withType: .Semibold)
        postCountView.textAlignment = .Center
        postCountView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(postCountView)
        
        followersHeadingView.text = "Followers"
        followersHeadingView.textAlignment = .Center
        followersHeadingView.font = .displayOfSize(12, withType: .Semibold)
        followersHeadingView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(followersHeadingView)
        
        followersCountView.font = .displayOfSize(12, withType: .Semibold)
        followersCountView.textAlignment = .Center
        followersCountView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(followersCountView)
        
        followingHeadingView.text = "Following"
        followingHeadingView.textAlignment = .Center
        followingHeadingView.font = .displayOfSize(12, withType: .Semibold)
        followingHeadingView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(followingHeadingView)
        
        followingCountView.font = .displayOfSize(12, withType: .Semibold)
        followingCountView.textAlignment = .Center
        followingCountView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(followingCountView)
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "hideKeyboard"))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = contentView.frame.size
        
        avatarImageView.frame = CGRect(x: size.width / 2 - 42, y: 20, width: 84, height: 84)
        displayNameView.align(.UnderCentered, relativeTo: avatarImageView, padding: 10, width: size.width - 28, height: 17)
        displayNameInputView.align(.UnderCentered, relativeTo: avatarImageView, padding: 10, width: size.width - 28, height: 17)
        textView.align(.UnderCentered, relativeTo: displayNameView, padding: 10, width: size.width - 28, height: calcTextHeight(textView.text!, withWidth: size.width - 28, andFont: textView.font))
        textInputView.align(.UnderCentered, relativeTo: displayNameView, padding: 10, width: size.width - 28, height: calcTextHeight(textView.text!, withWidth: size.width - 28, andFont: textView.font) + 50)
        buttonView.align(.UnderCentered, relativeTo: textView, padding: 15, width: 180, height: 27)
        buttonIconView.anchorToEdge(.Right, padding: 12, width: 12, height: 12)
        
        let metricWidth = size.width / 3
        postCountView.anchorInCorner(.BottomLeft, xPad: 0, yPad: 33, width: metricWidth, height: 14)
        postHeadingView.anchorInCorner(.BottomLeft, xPad: 0, yPad: 19, width: metricWidth, height: 14)
        followersCountView.anchorToEdge(.Bottom, padding: 33, width: metricWidth, height: 14)
        followersHeadingView.anchorToEdge(.Bottom, padding: 19, width: metricWidth, height: 14)
        followingCountView.anchorInCorner(.BottomRight, xPad: 0, yPad: 33, width: metricWidth, height: 14)
        followingHeadingView.anchorInCorner(.BottomRight, xPad: 0, yPad: 19, width: metricWidth, height: 14)
    }
    
    func bindViewModel(viewModel: ProfileViewModel) {
        // avoid binding multiple times
        if self.viewModel != nil {
            return
        }
        
        print("Biiiind")
        
        self.viewModel = viewModel
        
        isMe = viewModel.isMe
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        avatarImageView.rac_userInteractionEnabled <~ viewModel.isEditing
        
        displayNameView.rac_text <~ viewModel.displayName
        displayNameView.rac_hidden <~ viewModel.isEditing
        displayNameInputView.rac_hidden <~ viewModel.isEditing.producer.map(negate)
        displayNameInputView.rac_textSignal().toSignalProducer().startWithNext { [weak self] val in
            self?.viewModel.displayName.value = val as! String
        }
        
        textView.rac_text <~ viewModel.text
        textView.rac_hidden <~ viewModel.isEditing
        textInputView.rac_hidden <~ viewModel.isEditing.producer.map(negate)
        textInputView.rac_textSignal().toSignalProducer().startWithNext { [weak self] val in
            self?.viewModel.text.value = val as! String
        }
        
        viewModel.isEditing.producer.filter(isTrue).startWithNext { [weak self] _ in
            self?.displayNameInputView.text = viewModel.displayName.value
            self?.textInputView.text = viewModel.text.value
        }
        
        if isMe {
            buttonView.rac_hidden <~ viewModel.isEditing
            buttonView.setTitle("EDIT", forState: .Normal)
            buttonIconView.text = String.iconWithName(.Edit)
        } else {
            buttonView.rac_title <~ viewModel.isFollowed.producer.mapToTuple("FOLLOWING", "FOLLOW")
            buttonIconView.rac_text <~ viewModel.isFollowed.producer.mapToTuple(String.iconWithName(.Check), "")
        }
        
        followersCountView.rac_text <~ viewModel.followersCount.producer.map { "\($0)" }
        followersHeadingView.rac_hidden <~ viewModel.isEditing
        followersCountView.rac_hidden <~ viewModel.isEditing
        postCountView.rac_text <~ viewModel.followersCount.producer.map { "\($0)" }
        postHeadingView.rac_hidden <~ viewModel.isEditing
        postCountView.rac_hidden <~ viewModel.isEditing
        followingCountView.rac_text <~ viewModel.followingCount.producer.map { "\($0)" }
        followingHeadingView.rac_hidden <~ viewModel.isEditing
        followingCountView.rac_hidden <~ viewModel.isEditing
    }
    
    func editProfile() {
        navigationController?.pushViewController(EditProfileViewController(), animated: false)
    }
    
    dynamic private func tapButton() {
        if isMe {
            viewModel.isEditing.value = true
        } else if !SessionService.isLoggedIn {
            let alert = UIAlertController(title: "Please login first", message: "In order to follow \(viewModel.displayName.value) you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Sign in", style: .Cancel, handler: { [weak self] _ in
                self?.window?.rootViewController = LoginViewController()
            }))
            alert.addAction(UIAlertAction(title: "Later", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
//        viewModel.toggleFollow()
    }
    
    dynamic private func hideKeyboard() {
        contentView.endEditing(true)
    }
    
    dynamic private func updateImage() {
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            
            imagePickerController.navigationBar.translucent = false
            imagePickerController.navigationBar.barTintColor = UIColor.Accent
            imagePickerController.navigationBar.titleTextAttributes = [
//                NSFontAttributeName: UIFont.robotoOfSize(17, withType: .Medium),
                NSForegroundColorAttributeName: UIColor.whiteColor(),
            ]
            
            imagePickerController.sourceType = .PhotoLibrary
            imagePickerController.delegate = self
            navigationController!.presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }
    
}

// MARK: - UITextViewDelegate
extension ProfileHeaderCollectionViewCell: UITextViewDelegate {

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            contentView.endEditing(true)
            return false
        }
        return true
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension ProfileHeaderCollectionViewCell: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let fixedImage = image.fixedOrientation().centeredCropWithSize(CGSize(width: 1024, height: 1024))
        avatarImageView.image = fixedImage
//        viewModel.updateAvatar(fixedImage).startWithCompleted {
//            NotificationService.push("Profile image updated", level: .Success)
//        }
    }
    
}