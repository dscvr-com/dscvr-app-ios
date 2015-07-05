//
// Icomoon.swift
//
// This file was automatically created based on the `icomoon.svg` font file.
// Make sure to also copy over the `icomoon.ttf` font file.
//

import UIKit

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

public extension UIFont {
    public class func icomoonOfSize(fontSize: CGFloat) -> UIFont {
        struct Static {
            static var onceToken : dispatch_once_t = 0
        }

        let name = "icomoon"
        if (UIFont.fontNamesForFamilyName(name).count == 0) {
            dispatch_once(&Static.onceToken) {
                FontLoader.loadFont(name)
            }
        }

        return UIFont(name: name, size: fontSize)!
    }
}

public extension String {
    public static func icomoonWithName(name: Icomoon) -> String {
        return name.rawValue.substringToIndex(advance(name.rawValue.startIndex, 1))
    }
}

public enum Icomoon: String {
    case Camera = "\u{e600}"
    case Compass = "\u{e601}"
    case HeartOutlined = "\u{e602}"
    case Heart = "\u{e603}"
    case Infinity = "\u{e604}"
    case Message = "\u{e605}"
    case MagnifyingGlass = "\u{e606}"
    case LocationPin = "\u{e607}"
    case User = "\u{e608}"
    case ResizeFullScreen = "\u{e609}"
    case Cross = "\u{e60a}"
    case Bell = "\u{f0a2}"
}