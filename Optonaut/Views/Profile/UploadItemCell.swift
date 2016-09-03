//
//  UploadItemCell.swift
//  PhotoViewGallery
//
//  Created by Robert John Alkuino on 08/06/2016.
//  Copyright © 2016 Brewed Concepts. All rights reserved.
//

import UIKit
import Kingfisher
import ReactiveCocoa

class UploadItemCell: UITableViewCell {
    
    var uploadItem: UIImageView!
    var uploadButton = UIButton()
    var uploadFinish = MutableProperty<Bool>(false)
    private let viewModel = ProfileTileCollectionViewModel()
    var uploadProgress:UIProgressView?
    var uploadLabel = UILabel()
    
    weak var navigationController: NavigationController?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let buttonWidth = (self.frame.width/3) + 20
        
        self.uploadItem = UIImageView(frame: CGRect(x: 0, y: 0, width: 85.0, height: 71.0))
        self.uploadItem.center = CGPoint(x: self.uploadItem.frame.size.width/2.0 + 10.0, y: self.contentView.frame.height/2 + 15.0)
        self.uploadItem.backgroundColor = UIColor.lightGrayColor()
        
        self.uploadButton.setTitle("UPLOAD", forState: .Normal)
        self.uploadButton.backgroundColor = UIColor(hex:0xFF5E00)
        self.uploadButton.titleLabel?.font = UIFont.systemFontOfSize(11.0)
        self.uploadButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        self.uploadButton.layer.cornerRadius = 4.0
        self.uploadButton.layer.borderWidth = 1.0
        self.uploadButton.layer.borderColor = UIColor(hex:0xFF5E00).CGColor
        self.uploadButton.addTarget(self, action: #selector(upload), forControlEvents: .TouchUpInside)
        
        self.addSubview(uploadItem)
        self.addSubview(uploadButton)
        
        self.uploadButton.autoAlignAxisToSuperviewAxis(.Horizontal)
        self.uploadButton.autoPinEdge(.Right, toEdge: .Right, ofView: self, withOffset: -10)
        self.uploadButton.autoSetDimensionsToSize(CGSize(width: buttonWidth, height: 25))
        
        self.uploadLabel.backgroundColor = UIColor.blackColor()
        self.uploadLabel.textColor = UIColor.whiteColor()
        self.uploadLabel.text = "Uploading.."
        self.uploadLabel.textAlignment = .Center
        self.uploadLabel.layer.cornerRadius = 4.0
        self.uploadLabel.layer.borderWidth = 1.0
        self.uploadLabel.font = UIFont.systemFontOfSize(11.0)
        self.addSubview(uploadLabel)
        
        self.uploadLabel.autoAlignAxisToSuperviewAxis(.Horizontal)
        self.uploadLabel.autoPinEdge(.Right, toEdge: .Right, ofView: self, withOffset: -10)
        self.uploadLabel.autoSetDimensionsToSize(CGSize(width: buttonWidth, height: 25))
        self.uploadLabel.hidden = true
        
        self.uploadProgress = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
        self.uploadProgress?.progressTintColor = UIColor(hex:0xFF5E00).alpha(0.70)
        self.uploadProgress?.trackTintColor = UIColor.clearColor()
        self.uploadProgress?.layer.cornerRadius = 4.0
        self.uploadProgress?.layer.borderWidth = 1.0
        self.addSubview(uploadProgress!)
        
        self.uploadProgress!.autoAlignAxisToSuperviewAxis(.Horizontal)
        self.uploadProgress!.autoPinEdge(.Right, toEdge: .Right, ofView: self, withOffset: -10)
        self.uploadProgress!.autoSetDimensionsToSize(CGSize(width: buttonWidth, height: 25))
        self.uploadProgress!.hidden = true
        
//        PipelineService.stitchingStatus.producer
//            .observeOnMain()
//            .startWithNext { [weak self] status in
//                switch status {
//                case let .Stitching(progress):
//                    self?.uploadLabel.text = "Stitching.."
//                    self?.uploadProgress!.setProgress(progress, animated: true)
//                default:
//                    print("wala")
//                }
//        }
        
    }
    
    func upload() {
        if Reachability.connectedToNetwork() {
            viewModel.upload()
        } else {
            let alert = UIAlertController(title:"Network Error!", message: "Please Check your Internet Connection.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func bind(optographID: UUID) {
        viewModel.bind(optographID)
        let url = TextureURL(optographID, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
        if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url) {
            dispatch_async(dispatch_get_main_queue()) {
                self.uploadItem.image = originalImage.resized(.Width, value: self.uploadItem.frame.width)
            }
        }
        viewModel.isStitched.producer.startWithNext{ val in
            if val {
                self.uploadButton.userInteractionEnabled = true
            } else {
                self.uploadButton.userInteractionEnabled = false
            }
        }
        
        viewModel.uploadStatus.producer
            .skipRepeats()
            .startWithNext{ uploadStatus in
                if uploadStatus == .Uploading {
                    self.uploadProgress!.hidden = false
                    self.uploadLabel.hidden = false
                } else if uploadStatus == .Offline {
                    self.uploadProgress!.hidden = true
                    self.uploadLabel.hidden = true
                } else if uploadStatus == .Uploaded {
                    self.uploadFinish.value = true
                    self.uploadLabel.hidden = true
                    self.uploadProgress!.hidden = true
                    return
                } else {
                    return 
                }
        }
        
        
        viewModel.uploadPercentStatus.producer.startWithNext{ val in
            self.uploadLabel.text = "Uploading.."
            self.uploadProgress!.setProgress(val, animated: true)
        }
    }
    required init(coder aDecoder: NSCoder){
        //Just Call Super
        super.init(coder: aDecoder)!
    }
}
