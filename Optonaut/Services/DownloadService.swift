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
    
    private static let sharedInstance = DownloadService()
    
    private static var activeDownloads: [String: Signal<Float, NSError>] = [:]
    
    static func download(from url: String, to path: String) -> Signal<Float, NSError> {
        if let signal = activeDownloads[url] {
            return signal
        }
        
        let signal = Signal<Float, NSError> { sink in
            let destination: Alamofire.Request.DownloadFileDestination = { tmpUrl, _ in
                return NSURL(fileURLWithPath: path) ?? tmpUrl
            }
            
            let request = Alamofire.download(.GET, url, destination: destination)
                .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                    let progress = Float(totalBytesRead) / Float(totalBytesExpectedToRead)
                    sendNext(sink, progress)
                }
                .response { _, _, _, error in
                    if let error = error {
                        print(error)
                        sendError(sink, error)
                    } else {
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