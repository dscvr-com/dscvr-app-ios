//
// Icon.swift
//
// This file was automatically created based on the `icons.svg` font file.
// Make sure to also copy over the `icons.ttf` font file.
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
    public class func iconOfSize(fontSize: CGFloat) -> UIFont {
        struct Static {
            static var onceToken : dispatch_once_t = 0
        }

        let name = "icons"
        if (UIFont.fontNamesForFamilyName(name).count == 0) {
            dispatch_once(&Static.onceToken) {
                FontLoader.loadFont(name)
            }
        }

        return UIFont(name: name, size: fontSize)!
    }
}

public extension UIImage {
    public static func iconWithName(name: Icon, textColor: UIColor, fontSize: CGFloat, offset: CGSize = CGSizeZero) -> UIImage {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .ByWordWrapping
        paragraph.alignment = .Center
        let attributes = [
            NSFontAttributeName: UIFont.iconOfSize(fontSize),
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: paragraph
        ]
        let attributedString = NSAttributedString(string: String.iconWithName(name) as String, attributes: attributes)
        let stringSize = sizeOfAttributeString(attributedString)
        let size = CGSize(width: stringSize.width + offset.width, height: stringSize.height + offset.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        attributedString.drawInRect(CGRect(origin: CGPointZero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public extension String {
    public static func iconWithName(name: Icon) -> String {
        return name.rawValue.substringToIndex(name.rawValue.startIndex.advancedBy(1))
    }
}

private func sizeOfAttributeString(str: NSAttributedString) -> CGSize {
    return str.boundingRectWithSize(CGSizeMake(10000, 10000), options:(NSStringDrawingOptions.UsesLineFragmentOrigin), context:nil).size
}

public enum Icon: String {
    case OnboardingInfo = "\u{e900}"
    case OnboardingVr = "\u{e901}"
    case Back = "\u{e902}"
    case Bell = "\u{e903}"
    case CameraAdd = "\u{e904}"
    case Cardboard = "\u{e905}"
    case Check = "\u{e906}"
    case Comment = "\u{e907}"
    case Compass = "\u{e908}"
    case Cross = "\u{e909}"
    case Rocket = "\u{e90a}"
    case Feed = "\u{e90b}"
    case HeartFilled = "\u{e90c}"
    case Heart = "\u{e90d}"
    case Location = "\u{e90e}"
    case Logo = "\u{e90f}"
    case MoreOptions = "\u{e910}"
    case Profile = "\u{e911}"
    case Qrcode = "\u{e912}"
    case Redo = "\u{e913}"
    case Search = "\u{e914}"
    case Send = "\u{e915}"
    case Settings = "\u{e916}"
    case Share = "\u{e917}"
    case LogoText = "\u{e918}"
    case Plus = "\u{e919}"
}