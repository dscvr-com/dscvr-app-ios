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
       return CFURLCreateStringByAddingPercentEscapes(nil, self as CFString, nil, "!*'();:@&=+$,/?%#[]\" " as CFString, kCFStringEncodingASCII) as String
    }
    
    func stringByAppendingPathComponent(_ path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
    
    func NSRangeOfString(_ substring: String) -> NSRange? {
        guard let substringRange = range(of: substring) else {
            return nil
        }
        
        let start = characters.distance(from: startIndex, to: substringRange.lowerBound)
        let length = characters.distance(from: substringRange.lowerBound, to: substringRange.upperBound) + 1
        return NSMakeRange(start, length)
    }
}

extension Array {
    
    func first(_ predicate: (Element) -> Bool) -> Element? {
        for item in self {
            if predicate(item) {
                return item
            }
        }
        return nil
    }
}

extension Double {
    mutating func roundToPlaces(_ places: Int) -> Double {
        let divisor = pow(10, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension CGPoint {
    func distanceTo(_ otherPoint: CGPoint) -> CGFloat {
        let p1 = self
        let p2 = otherPoint
        let squareX = (p1.x - p2.x) * (p1.x - p2.x)
        let squareY = (p1.y - p2.y) * (p1.y - p2.y)
        return sqrt(squareX + squareY)
    }
}
