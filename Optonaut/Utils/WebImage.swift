//
//  WebImage.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/11/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import WebImage
import ReactiveCocoa

extension SDWebImageManager {
    
    func downloadImageForURL(url: String) -> SignalProducer<UIImage, NoError> {
        return SignalProducer { sink, disposable in
            SDWebImageManager.sharedManager().downloadImageWithURL(
                NSURL(string: url)!,
                options: [],
                progress: { _ in },
                completed: { (image, _, _, _, _) in
                    if let image = image {
                        sendNext(sink, image)
                    }
                    sendCompleted(sink)
            })
        }
    }
    
    
    func downloadDataForURL(url: String) -> SignalProducer<NSData, NoError> {
        return downloadImageForURL(url).map { UIImageJPEGRepresentation($0, 0.7)! }
    }
}

