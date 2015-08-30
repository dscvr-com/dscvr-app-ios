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
    
    private enum Event {
        case Progress(Float)
        case Data(NSData)
    }
    
    private static var activeDownloads: [String: Signal<Event, NoError>] = [:]
    
    static func downloadProgress(from url: String, to path: String) -> Signal<Float, NoError> {
        return download(from: url, to: path)
            .map { event in
                switch event {
                case .Progress(let progress): return progress
                case .Data(_): return -1
                }
            }
            .filter { $0 != -1 }
    }
    
    static func downloadData(from url: String, to path: String) -> Signal<NSData, NoError> {
        return download(from: url, to: path)
            .map { event in
                switch event {
                case .Progress(_): return NSData()
                case .Data(let data): return data
                }
            }
            .filter { $0.length > 0 }
    }
    
    private static func download(from url: String, to path: String) -> Signal<Event, NoError> {
        if let signal = activeDownloads[url] {
            return signal
        }
        
        let signal = Signal<Event, NSError> { sink in
            let destination: Alamofire.Request.DownloadFileDestination = { tmpUrl, _ in
                return NSURL(fileURLWithPath: path) ?? tmpUrl
            }
            
            let request = Alamofire.download(.GET, url, destination: destination)
                .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                    let progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    sendNext(sink, Event.Progress(progress))
                }
                .response { _, _, data, error in
                    if let error = error {
                        print(error)
                    } else {
                        sendNext(sink, Event.Data(data!))
                        sendCompleted(sink)
                    }
                }
            
            return ActionDisposable {
                request.cancel()
            }
        }
        
        activeDownloads[url] = signal
        
        signal.observe(
            completed: {
                activeDownloads.removeValueForKey(url)
            },
            error: { error in
                activeDownloads.removeValueForKey(url)
            }
        )
        
        return signal
    }
}