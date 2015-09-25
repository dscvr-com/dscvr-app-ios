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
    
    // TODO remove
    var firstWord: String? {
        return componentsSeparatedByString(" ").first
    }
    
    func stringByAppendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.stringByAppendingPathComponent(path)
    }
    
    func subString(startIndex: Int, length: Int) -> String {
        let start = self.startIndex.advancedBy(startIndex)
        let end = self.endIndex.advancedBy(startIndex + length)
        return self.substringWithRange(Range<String.Index>(start: start, end: end))
    }
}