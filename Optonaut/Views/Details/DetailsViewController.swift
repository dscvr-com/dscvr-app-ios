//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import TTTAttributedLabel
import ReactiveCocoa
import WebImage
import CoreMotion

class DetailsViewController: UIViewController {
    
    var viewModel: OptographViewModel
    
    // subviews
    let previewImageView = UIImageView()
    let likeButtonView = UIButton()
    let numberOfLikesView = UILabel()
    let dateView = UILabel()
    let textView = TTTAttributedLabel(forAutoLayout: ())
    
    let motionManager = CMMotionManager()
    
    required init(viewModel: OptographViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        viewModel = OptographViewModel(optograph: Optograph())
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        navigationItem.title = ""
        
        if let detailsUrl = NSURL(string: viewModel.detailsUrl.value) {
            previewImageView.sd_setImageWithURL(detailsUrl, placeholderImage: UIImage(named: "placeholder"))
        }
        view.addSubview(previewImageView)
        
        likeButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        likeButtonView.setTitle(String.icomoonWithName(.Heart), forState: .Normal)
        likeButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleLike()
            return RACSignal.empty()
        })
        viewModel.liked.producer
            |> map { $0 ? baseColor() : .grayColor() }
            |> start(next: { self.likeButtonView.setTitleColor($0, forState: .Normal)})
        view.addSubview(likeButtonView)
        
        numberOfLikesView.font = UIFont.boldSystemFontOfSize(16)
        numberOfLikesView.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
//        numberOfLikesView.rac_text <~ viewModel.numberOfLikes.producer |> map { num in "\(num)" }
        view.addSubview(numberOfLikesView)
        
        dateView.font = UIFont.systemFontOfSize(16)
        dateView.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        dateView.rac_text <~ viewModel.timeSinceCreated
        view.addSubview(dateView)
        
        let description = "\(viewModel.userName.value) \(viewModel.text.value)"
        textView.numberOfLines = 0
        textView.setText(description) { (text: NSMutableAttributedString!) -> NSMutableAttributedString! in
            let range = NSMakeRange(0, count(self.viewModel.userName.value))
            let boldFont = UIFont.boldSystemFontOfSize(17)
            let font = CTFontCreateWithName(boldFont.fontName, boldFont.pointSize, nil)
            
            text.addAttribute(NSFontAttributeName, value: font, range: range)
            text.addAttribute(kCTForegroundColorAttributeName as String, value: baseColor(), range: range)
            
            return text
        }
        view.addSubview(textView)
        
        motionManager.accelerometerUpdateInterval = 0.3
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.presentTransparentNavigationBar()
        
//        navigationController?.navigationBar.translucent = true
//        navigationController?.navigationBar.barTintColor = UIColor.clearColor()
//        navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
    }
    
//    override func viewDidDisappear(animated: Bool) {
//        super.viewDidDisappear(animated)
//        
//        navigationController?.hideTransparentNavigationBar()
//    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: { accelerometerData, error in
            if accelerometerData.acceleration.x >= 0.75 {
                self.motionManager.stopAccelerometerUpdates()
                self.navigationController?.pushViewController(SphereViewController(), animated: false)
            } else if accelerometerData.acceleration.x <= -0.75 {
                self.motionManager.stopAccelerometerUpdates()
                self.navigationController?.pushViewController(SphereViewController(), animated: false)
            }
        })
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            navigationController?.hideTransparentNavigationBar()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.motionManager.stopAccelerometerUpdates()
    }
    
    override func updateViewConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: -44)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 0.84)
        
        likeButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 10)
        likeButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 15)
        
        numberOfLikesView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        numberOfLikesView.autoPinEdge(.Left, toEdge: .Right, ofView: likeButtonView, withOffset: 5)
        
        dateView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        dateView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -15)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 46)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 15)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -15)
        
        super.updateViewConstraints()
    }
    
    func pushViewer() {
        navigationController?.pushViewController(SphereViewController(), animated: true)
    }
    
}
