//
//  WebImage.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/11/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Kingfisher
import ReactiveSwift
import Result
import SpriteKit

extension ImageDownloader {
    
    func downloadImageForURL(_ url: String) -> SignalProducer<UIImage, NoError> {
        
        return SignalProducer { sink, disposable in
            let task = self.downloadImage(
                with: URL(string: url)!,
                completionHandler: { (image, error, _, _) in
                    if !disposable.isDisposed {
                        if let image = image {
                            sink.send(value: image)
                        }
                        if let error = error {
                            print("KingfisherManager Download Error")
                            print(error)
                        }
                        sink.sendCompleted()
                    }
            })
            
            disposable.add {
                task?.cancel()
            }
        }
    }
    
    func downloadSKTextureForURL(_ url: String) -> SignalProducer<SKTexture, NoError> {
        return downloadImageForURL(url).map { SKTexture(image: $0) }
    }
    
    func downloadDataForURL(_ url: String) -> SignalProducer<Data, NoError> {
        return downloadImageForURL(url).map { UIImageJPEGRepresentation($0, 0.7)! }
    }
}

