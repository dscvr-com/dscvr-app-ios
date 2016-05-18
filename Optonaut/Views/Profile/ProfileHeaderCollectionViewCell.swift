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
    weak var parentViewController: UIViewController?
    
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
    //private let buttonIconView = UIImageView()
    private let postHeadingView = UILabel()
    //private let postCountView = UILabel()
   
    private let divider = UILabel()
    private let dividerDescription = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UIColor(hex:0xf7f7f7)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.borderColor = UIColor(hex:0xffbc00).CGColor
        avatarImageView.layer.borderWidth = 3.0
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.clipsToBounds = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.updateImage)))
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.displayOfSize(15, withType: .Semibold)
        displayNameView.textColor = UIColor(0xffbc00)
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
        
//        buttonIconView.image = UIImage(named: "")
//        buttonView.addSubview(buttonIconView)
        
        buttonView.backgroundColor = UIColor(0xffbc00)
        buttonView.layer.cornerRadius = 5
        buttonView.layer.masksToBounds = true
        buttonView.setTitleColor(.whiteColor(), forState: .Normal)
        buttonView.titleLabel?.font = .displayOfSize(11, withType: .Semibold)
        buttonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.tapButton)))
        contentView.addSubview(buttonView)
        
        divider.backgroundColor = UIColor(hex:0x595959)
        contentView.addSubview(divider)
        
//        dividerDescription.backgroundColor = UIColor(0xffbc00)
//        contentView.addSubview(dividerDescription)
        
        //postHeadingView.text = "0 Posts"
        postHeadingView.text = "IAM360 Images"
        postHeadingView.textAlignment = .Center
        postHeadingView.font = UIFont(name: "Avenir LT 45 Book_0", size: 18)
        postHeadingView.backgroundColor = UIColor(hex:0xf7f7f7)
        contentView.addSubview(postHeadingView)
        
//        postCountView.font = .displayOfSize(12, withType: .Semibold)
//        postCountView.textAlignment = .Center
//        postCountView.textColor = UIColor(0xbdbdbd)
//        contentView.addSubview(postCountView)
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.dismissKeyboard)))
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
        
        avatarImageView.frame = CGRect(x: size.width / 2 - 42, y: 20, width: 100, height: 100)
        displayNameView.align(.UnderCentered, relativeTo: avatarImageView, padding: 10, width: size.width - 28, height: 22)
        displayNameInputView.align(.UnderCentered, relativeTo: avatarImageView, padding: 10, width: size.width - 28, height: 17)
        textInputView.align(.UnderCentered, relativeTo: displayNameView, padding: 10, width: size.width - 28, height: calcTextHeight(textView.text!, withWidth: size.width - 28, andFont: textView.font) + 50)
        //buttonIconView.anchorToEdge(.Right, padding: 12, width: 12, height: 12)
        
        buttonView.align(.UnderCentered, relativeTo: displayNameView, padding: 15, width: 100, height: 27)
        //dividerDescription.align(.UnderCentered, relativeTo: buttonView, padding: 15, width: size.width, height: 2)
        textView.align(.UnderCentered, relativeTo: buttonView, padding: 10, width: size.width - 28, height: calcTextHeight(textView.text!, withWidth: size.width - 28, andFont: textView.font))
        divider.align(.UnderCentered, relativeTo: textView, padding: 15, width: size.width, height: 2)
        
        //let metricWidth = size.width / 3
        //postCountView.anchorInCorner(.BottomLeft, xPad: 0, yPad: 33, width: metricWidth, height: 14)
        postHeadingView.align(.UnderCentered, relativeTo: divider, padding: 0, width: size.width , height: 50)
        
    }
    
    func bindViewModel(viewModel: ProfileViewModel) {
        // avoid binding multiple times
        if self.viewModel != nil {
            return
        }
        
        self.viewModel = viewModel
        
        isMe = viewModel.isMe
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        avatarImageView.rac_userInteractionEnabled <~ viewModel.isEditing
        
        displayNameView.rac_text <~ viewModel.displayName
        displayNameView.rac_hidden <~ viewModel.isEditing
        displayNameInputView.rac_hidden <~ viewModel.isEditing.producer.map(negate)
        displayNameInputView.rac_textSignal().toSignalProducer().skip(1).startWithNext { [weak self] val in
            self?.viewModel.displayName.value = val as! String
        }
        
        textView.rac_text <~ viewModel.text
        textView.rac_hidden <~ viewModel.isEditing
        textInputView.rac_hidden <~ viewModel.isEditing.producer.map(negate)
        textInputView.rac_textSignal().toSignalProducer().skip(1).startWithNext { [weak self] val in
            self?.viewModel.text.value = val as! String
        }
        
        viewModel.isEditing.producer.filter(isTrue).startWithNext { [weak self] _ in
            self?.displayNameInputView.text = viewModel.displayName.value
            self?.textInputView.text = viewModel.text.value
        }
        
        if isMe {
            buttonView.rac_hidden <~ viewModel.isEditing
            buttonView.setBackgroundImage(UIImage(named:"edit_btn"), forState: .Normal)
        } else {
//            buttonView.rac_title <~ viewModel.isFollowed.producer.mapToTuple("FOLLOWING", "FOLLOW")
//            buttonView.rac_backgroundColor <~ viewModel.isFollowed.producer.mapToTuple(.Accent, UIColor(0xcacaca))
//            buttonIconView.rac_text <~ viewModel.isFollowed.producer.mapToTuple(String.iconWithName(.Check), "")
        }
        
        //postCountView.rac_text <~ viewModel.postCount.producer.map { "\($0)" }
        
//        viewModel.postCount.producer.startWithNext {
//            self.postHeadingView.text = "\($0) Posts"
//        }
        
        postHeadingView.rac_hidden <~ viewModel.isEditing
        //postCountView.rac_hidden <~ viewModel.isEditing
        
    }
    
    dynamic private func tapButton() {
        if isMe {
            viewModel.isEditing.value = true
        } else if !SessionService.isLoggedIn {
            parentViewController!.tabController!.hideUI()
            
            let loginOverlayViewController = LoginOverlayViewController()
            parentViewController!.presentViewController(loginOverlayViewController, animated: true, completion: nil)
        } else {
            viewModel.toggleFollow()
        }
        
    }
    
    dynamic private func dismissKeyboard() {
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
        viewModel.updateAvatar(fixedImage).startWithCompleted {
            NotificationService.push("Profile image updated", level: .Success)
        }
    }
    
}