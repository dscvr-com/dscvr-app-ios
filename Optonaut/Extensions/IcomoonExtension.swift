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

public extension UIImage {
    public static func icomoonWithName(name: Icomoon, textColor: UIColor, size: CGSize) -> UIImage {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = .Center
        let attributedString = NSAttributedString(string: String.icomoonWithName(name) as String, attributes: [NSFontAttributeName: UIFont.icomoonOfSize(24.0), NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName:paragraph])
        let size = sizeOfAttributeString(attributedString, maxWidth: size.width)
        UIGraphicsBeginImageContextWithOptions(size, false , 0.0)
        attributedString.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public extension String {
    public static func icomoonWithName(name: Icomoon) -> String {
        return name.rawValue.substringToIndex(name.rawValue.startIndex.advancedBy(1))
    }
}

private func sizeOfAttributeString(str: NSAttributedString, maxWidth: CGFloat) -> CGSize {
    let size = str.boundingRectWithSize(CGSizeMake(maxWidth, 1000), options:(NSStringDrawingOptions.UsesLineFragmentOrigin), context:nil).size
    return size
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
    case Cog = "\u{e60b}"
    case Share = "\u{e60d}"
    case LogoText = "\u{e60e}"
    case Logo = "\u{e60f}"
    case Eye = "\u{e610}"
    case Email = "\u{e611}"
    case InfoWithCircle = "\u{e612}"
    case Lock = "\u{e613}"
    case PaperPlane = "\u{e614}"
    case VCard = "\u{e615}"
    case DotsVertical = "\u{e616}"
    case Bell = "\u{f0a2}"
    case Retry = "\u{f0e2}"
    case CommentOutlined = "\u{f0e5}"
}