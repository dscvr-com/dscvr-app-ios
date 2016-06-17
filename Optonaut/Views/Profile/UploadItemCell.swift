//
//  UploadItemCell.swift
//  PhotoViewGallery
//
//  Created by Thadz on 08/06/2016.
//  Copyright © 2016 Brewed Concepts. All rights reserved.
//

import UIKit
import Kingfisher

class UploadItemCell: UITableViewCell {
    
    var uploadItem: UIImageView!
    var uploadButton: UIButton!
    private let viewModel = ProfileTileCollectionViewModel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.uploadItem = UIImageView(frame: CGRect(x: 0, y: 0, width: 85.0, height: 71.0))
        self.uploadItem.center = CGPoint(x: self.uploadItem.frame.size.width/2.0 + 10.0, y: self.contentView.frame.height/2 + 15.0)
        self.uploadItem.backgroundColor = UIColor.lightGrayColor()
        
        self.uploadButton = UIButton(frame: CGRect(x: 0, y: 0, width: 75.0, height: 25.0))
        self.uploadButton.center = CGPoint(x: self.contentView.frame.size.width, y: self.uploadItem.center.y)
        self.uploadButton.setTitle("UPLOAD", forState: .Normal)
        self.uploadButton.titleLabel?.font = UIFont.systemFontOfSize(11.0)
        self.uploadButton.setTitleColor(UIColor.greenColor(), forState: .Normal)
        self.uploadButton.layer.cornerRadius = 4.0
        self.uploadButton.layer.borderColor = UIColor.greenColor().CGColor
        self.uploadButton.layer.borderWidth = 1.0
        self.uploadButton.addTarget(self, action: #selector(upload), forControlEvents: .TouchUpInside)
        
        self.addSubview(uploadItem)
        self.addSubview(uploadButton)
    }
    func upload() {
        viewModel.goUpload()
    }
    func bind(optographID: UUID) {
        viewModel.bind(optographID)
        let url = TextureURL(optographID, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
        if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url) {
            dispatch_async(dispatch_get_main_queue()) {
                self.uploadItem.image = originalImage.resized(.Width, value: self.uploadItem.frame.width)
            }
        }
    }
    required init(coder aDecoder: NSCoder){
        //Just Call Super
        super.init(coder: aDecoder)!
    }
}
