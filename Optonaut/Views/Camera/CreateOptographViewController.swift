//
//  EditProfileViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class CreateOptographViewController: UIViewController, RedNavbar {
    
    let viewModel = CreateOptographViewModel()
    
    // subviews
    let previewImageView = UIImageView()
    let locationView = InsetLabel()
    let descriptionView = KILabel()
    let descriptionInputView = KMPlaceholderTextView()
    let lineView = UIView()
    
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
        saveButton.title = "Post"
        saveButton.setTitleTextAttributes(attributes, forState: .Normal)
        saveButton.target = self
        saveButton.action = "post"
        navigationItem.setRightBarButtonItem(saveButton, animated: false)
        
        navigationItem.title = "New Optograph"
        
        viewModel.previewUrl.producer
            .start(next: { url in
                if let previewUrl = NSURL(string: url) {
                    self.previewImageView.sd_setImageWithURL(previewUrl, placeholderImage: UIImage(named: "optograph-placeholder"))
                }
            })
        view.addSubview(previewImageView)
        
        locationView.rac_text <~ viewModel.location
        locationView.rac_hidden <~ viewModel.location.producer.map { $0.isEmpty }
        locationView.font = UIFont.robotoOfSize(12, withType: .Regular)
        locationView.textColor = .whiteColor()
        locationView.backgroundColor = UIColor(0x0).alpha(0.4)
        locationView.edgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        view.addSubview(locationView)
        
        descriptionInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        descriptionInputView.placeholder = "Enter a description here..."
        descriptionInputView.placeholderColor = UIColor(0xcfcfcf)
        descriptionInputView.textColor = UIColor(0x4d4d4d)
        descriptionInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.description_.value = $0 as! String })
        descriptionInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        descriptionInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        view.addSubview(descriptionInputView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(lineView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 0.45)
        
        locationView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -13)
        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        
        descriptionInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 20)
        descriptionInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        descriptionInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        descriptionInputView.autoSetDimension(.Height, toSize: 100)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionInputView, withOffset: 5)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
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
    
    func cancel() {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func post() {
        viewModel.post()
            .start(next: { optograph in
                self.navigationController!.pushViewController(DetailsViewController(optographId: optograph.id), animated: false)
                let viewControllersCount = self.navigationController!.viewControllers.count
                self.navigationController!.viewControllers.removeAtIndex(viewControllersCount - 2)
            })
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}