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
    
    static let allValues = [Regular, Medium, Light, Black, Bold]
}

public extension UIFont {
    
    public class func robotoOfSize(fontSize: CGFloat, withType type: FontType) -> UIFont {
        
        switch type {
        case .Regular: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightRegular)
        case .Medium: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightMedium)
        case .Light: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightLight)
        case .Black: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightBlack)
        case .Bold: return UIFont.systemFontOfSize(fontSize, weight: UIFontWeightBold)
        }
    }
    
    public enum TextFontType: String {
        case Regular = "Regular"
        case Semibold = "Semibold"
        
        static let allValues = [Regular, Semibold]
    }
    
    public class func textOfSize(fontSize: CGFloat, withType type: TextFontType) -> UIFont {
        struct Static {
            static var onceTokens = toDictionary(TextFontType.allValues) { ($0, 0 as dispatch_once_t) }
        }

        let fileName = "SF-UI-Text-\(type.rawValue)"
        let fontName = "SFUIText-\(type.rawValue)"
        if (UIFont.fontNamesForFamilyName(fontName).count == 0) {
            dispatch_once(&Static.onceTokens[type]!) {
                FontLoader.loadFont(fileName)
            }
        }

        return UIFont(name: fontName, size: fontSize)!
    }
    
    public enum DisplayFontType: String {
        case Regular = "Regular"
//        case UltraLight = "Ultralight"
        case Semibold = "Semibold"
//        case Light = "Light"
        case Thin = "Thin"
        case Light = "Light"
        
        static let allValues = [Regular, Semibold, Thin, Light]
    }
    
    public class func displayOfSize(fontSize: CGFloat, withType type: DisplayFontType) -> UIFont {
        struct Static {
            static var onceTokens = toDictionary(DisplayFontType.allValues) { ($0, 0 as dispatch_once_t) }
        }

        let fileName = "SF-UI-Display-\(type.rawValue)"
        let fontName = "SFUIDisplay-\(type.rawValue)"
//        let fileName = "Avenir-Book_0"
//        let fontName = "Avenir-Book_0"
        if (UIFont.fontNamesForFamilyName(fontName).count == 0) {
            dispatch_once(&Static.onceTokens[type]!) {
                FontLoader.loadFont(fileName)
            }
        }

        return UIFont(name: fontName, size: fontSize)!
    }
    
}

private class FontLoader {
    class func loadFont(name: String) {
        let bundle = NSBundle(forClass: FontLoader.self)
        let fontURL = bundle.URLForResource(name, withExtension: "otf")!
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
