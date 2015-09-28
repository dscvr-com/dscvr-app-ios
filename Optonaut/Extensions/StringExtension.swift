//
//  StringExtension.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/2/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

extension String {
    var escaped: String {
       return CFURLCreateStringByAddingPercentEscapes(nil, self, nil, "!*'();:@&=+$,/?%#[]\" ", kCFStringEncodingASCII) as String
    }
    
    func stringByAppendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.stringByAppendingPathComponent(path)
    }
    
    func NSRangeOfString(substring: String) -> NSRange? {
        guard let substringRange = rangeOfString(substring) else {
            return nil
        }
        
        let start = startIndex.distanceTo(substringRange.startIndex)
        let length = substringRange.startIndex.distanceTo(substringRange.endIndex) + 1
        return NSMakeRange(start, length)
    }
}