//
//  ProfileHeaderCollectionViewCell.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 23/01/2016.
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
    private let buttonFollow = UIButton()
    //private let buttonIconView = UIImageView()
    private let postHeadingView = UILabel()
    private let postHeadingView1 = UILabel()
    private let postHeadingView2 = UILabel()
    private let postHeadingView3 = UILabel()
    
    //private let postCountView = UILabel()
    private let editSubView = UIImageView()
    
    private let dividerDescription = UILabel()
    
    let yellowLine = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        print("reload")
        
        contentView.backgroundColor = UIColor(hex:0xf7f7f7)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.borderColor = UIColor(hex:0xffbc00).CGColor
        avatarImageView.layer.borderWidth = 3.0
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.fontDisplay(20, withType: .Semibold)
        displayNameView.textColor = UIColor(0xffbc00)
        displayNameView.textAlignment = .Center
        contentView.addSubview(displayNameView)
        
        displayNameInputView.placeholder = "Enter your name"
        displayNameInputView.font = UIFont.fontDisplay(20, withType: .Semibold)
        displayNameInputView.textAlignment = .Center
        displayNameInputView.textColor = UIColor(0xffbc00)
        displayNameInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        displayNameInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        displayNameInputView.returnKeyType = .Done
        displayNameInputView.delegate = self
        displayNameInputView.editable = false
        contentView.addSubview(displayNameInputView)
        
        editSubView.image = UIImage(named:"editSubview_btn")
        contentView.addSubview(editSubView)
        
        textView.numberOfLines = 0
        textView.textAlignment = .Center
        textView.font = UIFont.fontDisplay(12, withType: .Regular)
        textView.textColor = UIColor(0x979797)
        contentView.addSubview(textView)
        
        textInputView.placeholder = "Add description"
        textInputView.font = UIFont.fontDisplay(12, withType: .Regular)
        textInputView.textAlignment = .Center
        textInputView.textColor = UIColor(0x979797)
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        textInputView.returnKeyType = .Done
        textInputView.delegate = self
        contentView.addSubview(textInputView)
        
        //        buttonIconView.image = UIImage(named: "")
        //        buttonView.addSubview(buttonIconView)
        
        //        buttonView.backgroundColor = UIColor(0xffbc00)
        //        buttonView.layer.cornerRadius = 5
        //        buttonView.layer.masksToBounds = true
        //        buttonView.setTitleColor(.whiteColor(), forState: .Normal)
        //        buttonView.titleLabel?.font = .fontDisplay(11, withType: .Semibold)
        //        buttonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.tapButton)))
        //        contentView.addSubview(buttonView)
        
        buttonFollow.setBackgroundImage(UIImage(named:"unfollow_button"), forState: .Normal)
        buttonFollow.addTarget(self, action: #selector(self.followUser), forControlEvents:.TouchUpInside)
        contentView.addSubview(buttonFollow)
        
        //        dividerDescription.backgroundColor = UIColor(0xffbc00)
        //        contentView.addSubview(dividerDescription)
        
        postHeadingView.text = "Images"
        postHeadingView.textColor = UIColor.whiteColor()
        postHeadingView.textAlignment = .Center
        postHeadingView.font = UIFont(name: "Avenir-Book", size: 18)
        postHeadingView.backgroundColor = UIColor(hex:0x3E3D3D)
        contentView.addSubview(postHeadingView)
        
        postHeadingView1.text = "Images"
        postHeadingView1.textColor = UIColor(0xffbc00)
        postHeadingView1.textAlignment = .Center
        postHeadingView1.font = UIFont(name: "Avenir-Book", size: 17)
        postHeadingView1.backgroundColor = UIColor(hex:0x3E3D3D)
        postHeadingView1.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.imagePageTabTouched)))
        postHeadingView1.userInteractionEnabled = true
        contentView.addSubview(postHeadingView1)
        
        postHeadingView2.text = "Followers"
        postHeadingView2.textColor = UIColor.whiteColor()
        postHeadingView2.textAlignment = .Center
        postHeadingView2.font = UIFont(name: "Avenir-Book", size: 17)
        postHeadingView2.backgroundColor = UIColor(hex:0x3E3D3D)
        postHeadingView2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.followTabTouched)))
        postHeadingView2.userInteractionEnabled = true
        contentView.addSubview(postHeadingView2)
        
        postHeadingView3.text = "Notifications"
        postHeadingView3.textColor = UIColor.whiteColor()
        postHeadingView3.textAlignment = .Center
        postHeadingView3.font = UIFont(name: "Avenir-Book", size: 17)
        postHeadingView3.backgroundColor = UIColor(hex:0x3E3D3D)
        postHeadingView3.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.notifPageTabTouched)))
        postHeadingView3.userInteractionEnabled = true
        contentView.addSubview(postHeadingView3)
        
        yellowLine.backgroundColor = UIColor(0xffbc00)
        contentView.addSubview(yellowLine)
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.dismissKeyboard)))
    }
    
    func followTabTouched() {
        postHeadingView2.textColor = UIColor(0xffbc00)
        postHeadingView1.textColor = UIColor.whiteColor()
        postHeadingView3.textColor = UIColor.whiteColor()
        yellowLine.anchorInCorner(.BottomRight, xPad: (contentView.frame.width/3), yPad: 0, width: contentView.frame.width/3, height: 2)
        viewModel.followTabTouched.value = true
        viewModel.notifTabTouched.value = false
    }
    func imagePageTabTouched() {
        postHeadingView1.textColor = UIColor(0xffbc00)
        postHeadingView2.textColor = UIColor.whiteColor()
        postHeadingView3.textColor = UIColor.whiteColor()
        yellowLine.anchorInCorner(.BottomLeft, xPad: 0, yPad: 0, width: contentView.frame.width/3, height: 2)
        viewModel.followTabTouched.value = false
        viewModel.notifTabTouched.value = false
    }
    
    func notifPageTabTouched() {
        postHeadingView1.textColor = UIColor.whiteColor()
        postHeadingView2.textColor = UIColor.whiteColor()
        postHeadingView3.textColor = UIColor(0xffbc00)
        yellowLine.anchorInCorner(.BottomLeft, xPad: (contentView.frame.width/3) * 2, yPad: 0, width: contentView.frame.width/3, height: 2)
        viewModel.notifTabTouched.value = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    func followUser() {
        
        if SessionService.isLoggedIn {
            viewModel.toggleFollow()
        } else {
            let alert = UIAlertController(title:"", message: "Please login to follow this user", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = contentView.frame.size
        
        avatarImageView.frame = CGRect(x: size.width / 2 - 50, y: 20, width: 100, height: 100)
        displayNameView.align(.UnderCentered, relativeTo: avatarImageView, padding: 10, width: size.width - 28, height: 30)
        displayNameInputView.align(.UnderCentered, relativeTo: avatarImageView, padding: 10, width: size.width - 28, height: 22)
        editSubView.anchorInCorner(.BottomRight, xPad: 0, yPad: 0, width: editSubView.image!.size.width, height: editSubView.image!.size.width)
        editSubView.frame = CGRect(x: (avatarImageView.frame.origin.x+avatarImageView.frame.width)-editSubView.image!.size.width,y: (avatarImageView.frame.origin.y+avatarImageView.frame.height) - editSubView.image!.size.width,width: editSubView.image!.size.width,height: editSubView.image!.size.width)
        textView.align(.UnderCentered, relativeTo: displayNameInputView, padding: 10, width: size.width - 28, height: calcTextHeight(textView.text!, withWidth: size.width - 28, andFont: textView.font))
        textInputView.align(.UnderCentered, relativeTo: displayNameView, padding: 10, width: size.width - 28, height: calcTextHeight(textView.text!, withWidth: size.width - 28, andFont: textView.font) + 50)
        
        //buttonIconView.anchorToEdge(.Right, padding: 12, width: 12, height: 12)
        
        //buttonView.align(.UnderCentered, relativeTo: displayNameView, padding: 15, width: 100, height: 27)
        //dividerDescription.align(.UnderCentered, relativeTo: buttonView, padding: 15, width: size.width, height: 2)
        
        //let metricWidth = size.width / 3
        //postCountView.anchorInCorner(.BottomLeft, xPad: 0, yPad: 33, width: metricWidth, height: 14)
        
        postHeadingView.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 55)
//        postHeadingView1.anchorInCorner(.BottomLeft, xPad: 0, yPad: 0, width: contentView.frame.width/2, height: 55)
//        postHeadingView2.anchorInCorner(.BottomRight, xPad: 0, yPad: 0, width: contentView.frame.width/2, height: 55)
        
       contentView.groupInCorner(group: .Horizontal, views: [postHeadingView1, postHeadingView2, postHeadingView3], inCorner: .BottomLeft, padding: 0, width: contentView.frame.width/3, height: 55)
        
        yellowLine.anchorInCorner(.BottomLeft, xPad: 0, yPad: 0, width: contentView.frame.width/3, height: 2)
        
        buttonFollow.align(.UnderCentered, relativeTo: textView, padding: 10, width: avatarImageView.frame.width, height: 25)
    }
    
    func bindViewModel(viewModel: ProfileViewModel) {
        if self.viewModel != nil {
            return
        }
        
        self.viewModel = viewModel
        
        isMe = viewModel.isMe
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        
        viewModel.isEditing.producer.startWithNext{ [weak self] val in
            val ? self?.avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.updateImage))) : self?.avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileHeaderCollectionViewCell.tapButton)))
            self?.editSubView.hidden = val ? true : false
        }
        
        viewModel.isFollowed.producer.startWithNext{ [weak self] val in
            val ? self?.buttonFollow.setBackgroundImage(UIImage(named:"follow_button"), forState: .Normal) : self?.buttonFollow.setBackgroundImage(UIImage(named:"unfollow_button"), forState: .Normal)
        }
        
        displayNameView.rac_text <~ viewModel.userName
        displayNameView.rac_hidden <~ viewModel.isEditing
        displayNameInputView.rac_hidden <~ viewModel.isEditing.producer.map(negate)
        displayNameInputView.rac_textSignal().toSignalProducer().skip(1).startWithNext { [weak self] val in
            self?.viewModel.userName.value = val as! String
        }
        
        textView.rac_text <~ viewModel.text
        textView.rac_hidden <~ viewModel.isEditing
        textInputView.rac_hidden <~ viewModel.isEditing.producer.map(negate)
        textInputView.rac_textSignal().toSignalProducer().skip(1).startWithNext { [weak self] val in
            self?.viewModel.text.value = val as! String
        }
        
        viewModel.isEditing.producer.filter(isTrue).startWithNext { [weak self] _ in
            self?.displayNameInputView.text = viewModel.userName.value
            self?.textInputView.text = viewModel.text.value
        }
        
        if isMe {
            print("ako")
            buttonFollow.hidden = true
            editSubView.hidden = false
            postHeadingView.hidden = true
            postHeadingView1.hidden = false
            postHeadingView2.hidden = false
            postHeadingView3.hidden = false
            yellowLine.hidden = false
            postHeadingView1.rac_hidden <~ viewModel.isEditing
            postHeadingView2.rac_hidden <~ viewModel.isEditing
            postHeadingView3.rac_hidden <~ viewModel.isEditing
            yellowLine.rac_hidden <~ viewModel.isEditing
        } else {
            print("hindi ako")
            buttonFollow.hidden = false
            editSubView.hidden = true
            postHeadingView.hidden = false
            postHeadingView1.hidden = true
            postHeadingView2.hidden = true
            postHeadingView3.hidden = true
            yellowLine.hidden = true
        }
    }
    
    dynamic private func tapButton() {
        if isMe {
            viewModel.isEditing.value = true
        }
        //        else if !SessionService.isLoggedIn {
        //            parentViewController!.tabController!.hideUI()
        //
        //            let loginOverlayViewController = LoginOverlayViewController()
        //            parentViewController!.presentViewController(loginOverlayViewController, animated: true, completion: nil)
        //        } else {
        //            viewModel.toggleFollow()
        //        }
        //
    }
    
    dynamic private func dismissKeyboard() {
        contentView.endEditing(true)
    }
    
    dynamic private func updateImage() {
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            
            imagePickerController.navigationBar.translucent = false
            imagePickerController.navigationBar.barTintColor = UIColor(hex:0xffbc00)
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