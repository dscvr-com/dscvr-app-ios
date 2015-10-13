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
    case OnboardingVr = "\u{e800}"
    case OnboardingInfo = "\u{e801}"
    case Back = "\u{e802}"
    case CameraAdd = "\u{e803}"
    case Send = "\u{e804}"
    case Cardboard = "\u{e805}"
    case Check = "\u{e806}"
    case Comment = "\u{e807}"
    case Cross = "\u{e808}"
    case Edit = "\u{e809}"
    case Feed = "\u{e80a}"
    case HeartFilled = "\u{e80b}"
    case Compass = "\u{e80c}"
    case Location = "\u{e80d}"
    case MoreOptions = "\u{e80e}"
    case Profile = "\u{e80f}"
    case Share = "\u{e810}"
    case Star = "\u{e811}"
    case Redo = "\u{e812}"
    case Logo = "\u{e813}"
    case Heart = "\u{e814}"
    case Settings = "\u{e815}"
    case Search = "\u{e816}"
}