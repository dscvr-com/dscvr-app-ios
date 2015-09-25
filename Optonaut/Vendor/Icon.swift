//
// Icon.swift
//
// This file was automatically created based on the `optonaut-app.svg` font file.
// Make sure to also copy over the `optonaut-app.ttf` font file.
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

        let name = "optonaut-app"
        if (UIFont.fontNamesForFamilyName(name).count == 0) {
            dispatch_once(&Static.onceToken) {
                FontLoader.loadFont(name)
            }
        }

        return UIFont(name: name, size: fontSize)!
    }
}

public extension UIImage {
    public static func iconWithName(name: Icon, textColor: UIColor, size: CGSize) -> UIImage {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = .Center
        let attributedString = NSAttributedString(string: String.iconWithName(name) as String, attributes: [NSFontAttributeName: UIFont.iconOfSize(24.0), NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName:paragraph])
        let size = sizeOfAttributeString(attributedString, maxWidth: size.width)
        UIGraphicsBeginImageContextWithOptions(size, false , 0.0)
        attributedString.drawInRect(CGRectMake(0, 0, size.width, size.height))
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

private func sizeOfAttributeString(str: NSAttributedString, maxWidth: CGFloat) -> CGSize {
    let size = str.boundingRectWithSize(CGSizeMake(maxWidth, 1000), options:(NSStringDrawingOptions.UsesLineFragmentOrigin), context:nil).size
    return size
}

public enum Icon: String {
    case Addphoto = "\u{e000}"
    case Back = "\u{e001}"
    case Comment = "\u{e003}"
    case Edit = "\u{e004}"
    case Heart = "\u{e006}"
    case Share = "\u{e007}"
    case Star = "\u{e008}"
    case Vrglasses = "\u{e009}"
    case User = "\u{e00a}"
    case Moreoptions = "\u{e00b}"
    case Feed = "\u{e005}"
    case Camera = "\u{e002}"
}