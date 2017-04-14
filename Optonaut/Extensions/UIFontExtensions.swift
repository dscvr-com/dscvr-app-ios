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
    
    public class func robotoOfSize(_ fontSize: CGFloat, withType type: FontType) -> UIFont {
        
        switch type {
        case .Regular: return UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightRegular)
        case .Medium: return UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightMedium)
        case .Light: return UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightLight)
        case .Black: return UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightBlack)
        case .Bold: return UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightBold)
        }
    }
    
    public enum TextFontType: String {
        case Regular = "Regular"
        case Semibold = "Semibold"
        
        static let allValues = [Regular, Semibold]
    }
    
    public class func textOfSize(_ fontSize: CGFloat, withType type: TextFontType) -> UIFont {
        struct Static {
            static var onceTokens = toDictionary(TextFontType.allValues) { ($0, 0 as Int) }
        }

        let fileName = "SF-UI-Text-\(type.rawValue)"
        let fontName = "SFUIText-\(type.rawValue)"
        if (UIFont.fontNames(forFamilyName: fontName).count == 0) {
            // TODO
            //dispatch_once(&Static.onceTokens[type]!) {
                FontLoader.loadFont(fileName)
            //}
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
    
    public class func displayOfSize(_ fontSize: CGFloat, withType type: DisplayFontType) -> UIFont {
        struct Static {
            static var onceTokens = toDictionary(DisplayFontType.allValues) { ($0, 0 as Int) }
        }

        let fileName = "SF-UI-Display-\(type.rawValue)"
        let fontName = "SFUIDisplay-\(type.rawValue)"
//        let fileName = "Avenir-Book_0"
//        let fontName = "Avenir-Book_0"
        if (UIFont.fontNames(forFamilyName: fontName).count == 0) {
            // TODO
            //dispatch_once(&Static.onceTokens[type]!) {
                FontLoader.loadFont(fileName)
            //}
        }

        return UIFont(name: fontName, size: fontSize)!
    }
    public class func fontDisplay(_ fontSize: CGFloat, withType type: DisplayFontType) -> UIFont {
        
        return UIFont(name: "Avenir-Book", size: fontSize)!
    }
    
}

private class FontLoader {
    class func loadFont(_ name: String) {
        let bundle = Bundle(for: FontLoader.self)
        let fontURL = bundle.url(forResource: name, withExtension: "otf")!
        let data = try! Data(contentsOf: fontURL)

        let provider = CGDataProvider(data: data as CFData)
        let font = CGFont(provider!)

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            let errorDescription: CFString = CFErrorCopyDescription(error!.takeUnretainedValue())
            let nsError = error!.takeUnretainedValue() as AnyObject as! NSError
            NSException(name: NSExceptionName.internalInconsistencyException, reason: errorDescription as String, userInfo: [NSUnderlyingErrorKey: nsError]).raise()
        }
    }
}
