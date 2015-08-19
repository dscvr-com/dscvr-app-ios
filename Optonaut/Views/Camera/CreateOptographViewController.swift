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
    let textInputView = KMPlaceholderTextView()
    let lineView = UIView()
    
    let stitchingSignalProducer: SignalProducer<(left: NSData, right: NSData), NoError>
    
    required init(signalProducer: SignalProducer<(left: NSData, right: NSData), NoError>) {
        stitchingSignalProducer = signalProducer
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        let postButton = UIBarButtonItem()
        postButton.title = "Post"
        postButton.setTitleTextAttributes(attributes, forState: .Normal)
        postButton.target = self
        postButton.action = "post"
        
        navigationItem.title = "New Optograph"
        
        let spinnerView = UIActivityIndicatorView()
        let spinnerButton = UIBarButtonItem(customView: spinnerView)
        
        viewModel.pending.producer
            .start(next: { pending in
                if pending {
                    self.navigationItem.setRightBarButtonItem(spinnerButton, animated: true)
                    spinnerView.startAnimating()
                } else {
                    self.navigationItem.setRightBarButtonItem(postButton, animated: true)
                    spinnerView.stopAnimating()
                }
            })
        
        
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
        
        textInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        textInputView.placeholder = "Enter a description here..."
        textInputView.placeholderColor = UIColor(0xcfcfcf)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.text.value = $0 as! String })
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        view.addSubview(textInputView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(lineView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        stitchingSignalProducer
            .startOn(QueueScheduler(queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)))
            .start(next: { images in
                self.viewModel.saveImages(images)
                self.viewModel.pending.value = false
            })
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 0.45)
        
        locationView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -13)
        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        
        textInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 20)
        textInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        textInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        textInputView.autoSetDimension(.Height, toSize: 100)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textInputView, withOffset: 5)
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
                self.navigationController?.pushViewController(DetailsContainerViewController(optographId: optograph.id), animated: false)
                self.navigationController?.viewControllers.removeAtIndex(1)
            })
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}