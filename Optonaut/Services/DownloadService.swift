//
//  DownloadService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/26/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Alamofire

class DownloadService: NSObject {
    
    private static var activeDownloads: [String: SignalProducer<Float, NoError>] = [:]
    
    static func downloadProgress(from url: String, to path: String) -> SignalProducer<Float, NoError> {
        if let signalProducer = activeDownloads[url] {
            return signalProducer
        }
        
        let signalProducer = SignalProducer<Float, NoError> { sink, disposable in
            
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                sendNext(sink, 1)
                sendCompleted(sink)
                return
            }
            
            let request = Alamofire.request(.GET, url)
                .validate(statusCode: 200..<300)
                .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                    let progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    sendNext(sink, progress)
                }
                .response { _, _, data, error in
                    if let error = error {
                        print(error)
                        sendCompleted(sink)
                    } else {
                        data!.writeToFile(path, atomically: true)
                        sendNext(sink, 1)
                        sendCompleted(sink)
                    }
                }
            
            disposable.addDisposable {
                request.cancel()
            }
        }
        
        return signalProducer.on(
            started: {
                activeDownloads[url] = signalProducer
            },
            completed: {
                activeDownloads.removeValueForKey(url)
            },
            error: { error in
                activeDownloads.removeValueForKey(url)
            }
        )
    }
}