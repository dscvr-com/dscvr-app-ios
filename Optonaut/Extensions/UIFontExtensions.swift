//
//  Fonts.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/6/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation

public enum FontType: String {
    case Regular = "Regular"
    case Medium = "Medium"
    case Light = "Light"
    case Black = "Black"
    case Bold = "Bold"
    case SemiBold = "SemiBold"
    
    static let allValues = [Regular, Medium, Light, Black, Bold, SemiBold]
}

public extension UIFont {
    
    public class func robotoOfSize(fontSize: CGFloat, withType type: FontType) -> UIFont {
        
        switch type {
        case .Regular: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightRegular)
        case .Medium: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightMedium)
        case .Light: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightLight)
        case .Black: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightBlack)
        case .Bold: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightBold)
        case .SemiBold: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightSemibold)
        }
//
//        struct Static {
//            static var onceTokens = toDictionary(FontType.allValues) { ($0, 0 as dispatch_once_t) }
//        }
//
//        let name = "Roboto-\(type.rawValue)"
//        if (UIFont.fontNamesForFamilyName(name).count == 0) {
//            dispatch_once(&Static.onceTokens[type]!) {
//                FontLoader.loadFont(name)
//            }
//        }
//
//        return UIFont(name: name, size: fontSize)!
    }
    
}

private class FontLoader {
    class func loadFont(name: String) {
        let bundle = NSBundle(forClass: FontLoader.self)
        let fontURL = bundle.URLForResource(name, withExtension: "ttf")!
        let data = NSData(contentsOfURL: fontURL)!

        let provider = CGDataProviderCreateWithCFData(data)
        let font = CGFontCreateWithDataProvider(provider)!

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            let errorDescription: CFStringRef = CFErrorCopyDescription(error!.takeUnretainedValue())
            let nsError = error!.takeUnretainedValue() as AnyObject as! NSError
            NSException(name: NSInternalInconsistencyException, reason: errorDescription as String, userInfo: [NSUnderlyingErrorKey: nsError]).raise()
        }
    }
}

private func toDictionary<E, K, V>(array: [E], transformer: (element: E) -> (key: K, value: V)?) -> Dictionary<K, V> {
    return array.reduce([:]) { (var dict, e) in
        if let (key, value) = transformer(element: e) {
            dict[key] = value
        }
        return dict
    }
}