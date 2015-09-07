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
import Crashlytics

class DownloadService: NSObject {
    
    private enum DownloadData {
        case Progress(Float)
        case Contents(NSData)
    }
    
    private static var activeDownloads: [String: SignalProducer<DownloadData, NoError>] = [:]
    
    static func downloadProgress(from url: String, to path: String) -> SignalProducer<Float, NoError> {
        return download(from: url, to: path)
            .map { event -> Float? in
                switch event {
                case .Progress(let progress): return progress
                case .Contents(_): return nil
                }
            }
            .ignoreNil()
    }
    
    static func downloadContents(from url: String, to path: String) -> SignalProducer<NSData, NoError> {
        return download(from: url, to: path)
            .map { event -> NSData? in
                switch event {
                case .Progress(_): return nil
                case .Contents(let data): return data
                }
            }
            .ignoreNil()
    }
    
    private static func download(from url: String, to path: String) -> SignalProducer<DownloadData, NoError> {
        if let signalProducer = activeDownloads[url] {
            return signalProducer
        }
        
        let signalProducer = SignalProducer<DownloadData, NoError> { sink, disposable in
            
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                sendNext(sink, DownloadData.Progress(1))
                sendNext(sink, DownloadData.Contents(NSData(contentsOfFile: path)!))
                sendCompleted(sink)
                return
            }
            
            let request = Alamofire.request(.GET, url)
                .validate(statusCode: 200..<300)
                .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                    let progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    sendNext(sink, DownloadData.Progress(progress))
                }
                .response { _, _, data, error in
                    if let error = error {
                        print(error)
                    } else {
                        data!.writeToFile(path, atomically: true)
                        sendNext(sink, DownloadData.Progress(1))
                        sendNext(sink, DownloadData.Contents(data!))
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