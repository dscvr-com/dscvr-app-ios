//
//  WebImage.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/11/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Kingfisher
import ReactiveCocoa
import SpriteKit

extension ImageDownloader {
    
    func downloadImageForURL(url: String) -> SignalProducer<UIImage, NoError> {
        return SignalProducer { sink, disposable in
            let task = self.downloadImageWithURL(
                NSURL(string: url)!,
                progressBlock: nil,
                completionHandler: { (image, error, _, _) in
                    if !disposable.disposed {
                        if let image = image {
                            sink.sendNext(image)
                        }
                        if let error = error {
                            print("KingfisherManager Download Error")
                            print(error)
                        }
                        sink.sendCompleted()
                    }
            })
            
            disposable.addDisposable {
                task?.cancel()
            }
        }
    }
    
    func downloadSKTextureForURL(url: String) -> SignalProducer<SKTexture, NoError> {
        return downloadImageForURL(url).map { SKTexture(image: $0) }
    }
    
    func downloadDataForURL(url: String) -> SignalProducer<NSData, NoError> {
        return downloadImageForURL(url).map { UIImageJPEGRepresentation($0, 0.7)! }
    }
}

