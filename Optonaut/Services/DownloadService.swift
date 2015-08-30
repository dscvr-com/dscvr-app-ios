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
    
    private enum Event {
        case Progress(Float)
        case Data(NSData)
    }
    
    private static var activeDownloads: [String: SignalProducer<Event, NoError>] = [:]
    
    static func downloadProgress(from url: String, to path: String) -> SignalProducer<Float, NoError> {
        return download(from: url, to: path)
            .map { event in
                switch event {
                case .Progress(let progress): return progress
                case .Data(_): return -1
                }
            }
            .filter { $0 != -1 }
    }
    
    static func downloadData(from url: String, to path: String) -> SignalProducer<NSData, NoError> {
        return download(from: url, to: path)
            .map { event in
                switch event {
                case .Progress(_): return NSData()
                case .Data(let data): return data
                }
            }
            .filter { $0.length > 0 }
    }
    
    private static func download(from url: String, to path: String) -> SignalProducer<Event, NoError> {
        if let signalProducer = activeDownloads[url] {
            return signalProducer
        }
        
        let signalProducer = SignalProducer<Event, NoError> { sink, disposable in
            
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                sendNext(sink, Event.Progress(1))
                sendNext(sink, Event.Data(NSData(contentsOfFile: path)!))
                sendCompleted(sink)
                return
            }
            
            let destination: Alamofire.Request.DownloadFileDestination = { tmpUrl, _ in
                return NSURL(fileURLWithPath: path) ?? tmpUrl
            }
            
            let request = Alamofire.download(.GET, url, destination: destination)
                .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                    let progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    sendNext(sink, Event.Progress(progress))
                }
                .response { _, _, _, error in
                    if let error = error {
                        print(error)
                    } else {
                        sendNext(sink, Event.Data(NSData(contentsOfFile: path)!))
                        sendCompleted(sink)
                    }
                }
            
            disposable.addDisposable {
                request.cancel()
            }
        }
        
        activeDownloads[url] = signalProducer
        
        return signalProducer.on(
            completed: {
                activeDownloads.removeValueForKey(url)
            },
            error: { error in
                activeDownloads.removeValueForKey(url)
            }
        )
    }
}