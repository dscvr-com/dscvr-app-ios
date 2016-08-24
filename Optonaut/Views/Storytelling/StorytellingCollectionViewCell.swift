//
//  StorytellingCollectionViewCell.swift
//  DSCVR
//
//  Created by Thadz on 10/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import SpriteKit
import ReactiveCocoa
import SceneKit
import Kingfisher

class StorytellingCollectionViewCell: UICollectionViewCell, UINavigationControllerDelegate {

    private let iconView = UILabel()
    
    private let loadingView = UIActivityIndicatorView()
    private let imageView = PlaceholderImageView()
    
    private let viewModel = ProfileTileCollectionViewModel()
    
    private let uploadButton = UIButton()
    
    private let whiteBackground = UIView()
    private let deleteButton = UIButton()
    weak var navigationController: NavigationController?
//    weak var uploaderLabel = UILabel()
    
    var refreshNotification = NotificationSignal<Void>()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        let whiteBG = UIView(frame: CGRect(x: 0, y: frame.height - 20.0, width: frame.width, height: frame.height))
        whiteBG.backgroundColor = UIColor.whiteColor()
        
//        uploaderLabel?.text = "sampleUser"
//        uploaderLabel?.sizeToFit()
//        uploaderLabel?.center = whiteBG.center
//        
//        whiteBG.addSubview(uploaderLabel!)
        
        imageView.frame = CGRect(origin: CGPointZero, size: frame.size)
        
        imageView.layer.cornerRadius = 25.0;
        imageView.layer.borderColor = UIColor.clearColor().CGColor
        imageView.layer.masksToBounds = true;

        imageView.backgroundColor = UIColor.blackColor()
        
        imageView.rac_hidden <~ viewModel.isStitched.producer.map(negate)
        viewModel.uploadStatus.producer.equalsTo(.Uploaded)
            .combineLatestWith(viewModel.optographID.producer)
            .delayLatestUntil(viewModel.isStitched.producer)
            .skipRepeats { $0.0 == $1.0 && $0.1 == $1.1 }
            .startWithNext { [weak self] (isUploaded, optographID) in
                if isUploaded {
                    let url = TextureURL(optographID, side: .Left, size: frame.width, face: 0, x: 0, y: 0, d: 1)
                    print("cell",url)
                    self?.imageView.kf_setImageWithURL(NSURL(string: url)!)
                } else {
                    let url = TextureURL(optographID, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
                    print("cell1",url)
                    if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.imageView.image = originalImage.resized(.Width, value: frame.width)
                        }
                    }
                }
        }
        contentView.addSubview(imageView)
        
        iconView.frame = CGRect(x: frame.width - 32, y: 14, width: 18, height: 18)
        iconView.textColor = .whiteColor()
        iconView.font = UIFont.iconOfSize(18)
        iconView.rac_hidden <~ viewModel.isStitched.producer.map(negate)
        
        contentView.addSubview(iconView)
        
        loadingView.frame = CGRect(origin: CGPointZero, size: frame.size)
        loadingView.backgroundColor = UIColor.blackColor().alpha(0.7)
        loadingView.hidesWhenStopped = true
        loadingView.rac_animating <~ viewModel.isStitched.producer.map(negate)
        contentView.addSubview(loadingView)
        
        contentView.backgroundColor = UIColor(0xcacaca)
        
        
        
        viewModel.isPrivate.producer
            .skipRepeats()
            .combineLatestWith(viewModel.uploadStatus.producer.skipRepeats())
            .startWithNext{ isPrivate, uploadStatus in
                if isPrivate {
                    return self.iconView.text = String.iconWithName(.Safe)
                } else if uploadStatus == .Uploading {
                    //self.uploadButton.hidden = true
                    return self.iconView.text = String.iconWithName(.Loading)
                } else if uploadStatus == .Offline {
                    //return self.uploadButton.hidden = false
                } else if uploadStatus == .Uploaded {
                    //return self.uploadButton.hidden = true
                } else {
                    return
                }
        }
        
        contentView.addSubview(whiteBG)
        
        //deleteButton.rac_hidden <~ viewModel.userId.producer.map(negate)
    }
    func deleteOpto() {
        
        let alert = UIAlertController(title:"Are you sure?", message: "Do you really want to delete this Optograph? You cannot undo this.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { _ in
            self.viewModel.deleteOpto()
            self.refreshNotification.notify(())
            
            let alert = UIAlertController(title:"", message: "Will be deleted after next app restart.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        self.navigationController!.presentViewController(alert, animated: true, completion: nil)
    }
    
    func upload() {
        viewModel.goUpload()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func bind(optographID: UUID) {
        viewModel.bind(optographID)
    }
    
}
