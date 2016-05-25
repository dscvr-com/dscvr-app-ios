//
//  PhotoThumbnail.swift
//  PhotoViewGallery
//
//  Created by Thadz on 25/05/2016.
//  Copyright © 2016 Brewed Concepts. All rights reserved.
//

import UIKit

class PhotoThumbnail: UICollectionViewCell {

    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        //initialize image view
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        
        super.init(frame: frame)
        
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        contentView.addSubview(imageView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
