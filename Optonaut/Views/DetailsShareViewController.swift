//
//  SharingViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/12/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Social
import FBSDKShareKit
import MessageUI
import Kingfisher

class DetailsShareViewController: UIViewController ,TabControllerDelegate,MFMailComposeViewControllerDelegate{
    
    let buttonCopyLink = UIButton()
    let buttonFacebook = UIButton()
    //let buttonMessenger = UIButton()
    let buttonTwitter = UIButton()
    let buttonEmail = UIButton()
    let titleText = UILabel()
    var textToShare:String = ""
    var shareUrl:NSURL = NSURL(string: "")!
    var imageToShare: UIImage?
    var placeHolderToShare = UIImageView()
    var urlToShare:String = ""
    var descriptionToShare:String = ""
    var optographId:String = ""
    var tField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeButton = UIButton()
        closeButton.setBackgroundImage(UIImage(named:"close_icn"), forState: .Normal)
        closeButton.anchorInCorner(.TopLeft, xPad: 10, yPad: 20, width: 30 , height: 30)
        closeButton.addTarget(self, action: #selector(closeShare), forControlEvents: .TouchUpInside)
        self.view.addSubview(closeButton)
        
        let shareTitle = UILabel()
        shareTitle.text = "Share"
        shareTitle.textAlignment = .Center
        shareTitle.font = UIFont(name: "Avenir-Book", size: 25)
        self.view.addSubview(shareTitle)
        
        let textwidth = calcTextWidth("Share", withFont: .displayOfSize(25, withType: .Semibold))
        shareTitle.anchorToEdge(.Top, padding: 25, width: textwidth, height: 20)
        
        let lineDivider = UILabel()
        lineDivider.backgroundColor = UIColor.lightGrayColor()
        self.view.addSubview(lineDivider)
        lineDivider.align(.UnderCentered, relativeTo: shareTitle, padding: 10, width: self.view.frame.width , height: 1)
        
        let image: UIImage = UIImage(named: "logo_settings")!
        var bgImage: UIImageView?
        bgImage = UIImageView(image: image)
        self.view.addSubview(bgImage!)
        bgImage!.align(.UnderCentered, relativeTo: lineDivider, padding: 10, width:image.size.width, height: image.size.height)
        
        let placeholderImageViewImage: UIImage = UIImage(named: "logo_settings")!
        var placeholderImageView: UIImageView?
        placeholderImageView = UIImageView(image: placeholderImageViewImage)
        placeholderImageView?.backgroundColor = UIColor.blackColor()
        self.view.addSubview(placeholderImageView!)
        placeholderImageView!.align(.UnderCentered, relativeTo: bgImage!, padding: 15, width:  self.view.frame.width - 56, height: 130)
        
        titleText.text = "Share this 360 image:"
        titleText.textAlignment = .Center
        titleText.font = UIFont(name: "Avenir-Book", size: 25)
        self.view.addSubview(titleText)
        titleText.align(.UnderCentered, relativeTo: placeholderImageView!, padding: 5, width: self.view.frame.width - 40, height: 40)
        
        buttonEmail.setImage(UIImage(named: "sharing_email") , forState: .Normal)
        buttonEmail.addTarget(self, action: #selector(sendEmailButtonTapped), forControlEvents: .TouchUpInside)
        
        buttonCopyLink.setImage(UIImage(named: "sharing_copyLink_btn") , forState: .Normal)
        buttonCopyLink.addTarget(self, action: #selector(copyLink), forControlEvents: .TouchUpInside)
        
        buttonFacebook.setImage(UIImage(named: "sharing_facebook_btn") , forState: .Normal)
        buttonFacebook.addTarget(self, action: #selector(shareFacebook), forControlEvents: .TouchUpInside)
        
        //        buttonMessenger.setImage(UIImage(named: "sharing_messenger_btn") , forState: .Normal)
        //        buttonMessenger.addTarget(self, action: #selector(shareMessenger), forControlEvents: .TouchUpInside)
        
        buttonTwitter.setImage(UIImage(named: "sharing_twitter_btn") , forState: .Normal)
        buttonTwitter.addTarget(self, action: #selector(shareTwitter), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(buttonEmail)
        buttonEmail.align(.UnderCentered, relativeTo: titleText, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.addSubview(buttonCopyLink)
        buttonCopyLink.align(.UnderCentered, relativeTo: buttonEmail, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.addSubview(buttonFacebook)
        buttonFacebook.align(.UnderCentered, relativeTo: buttonCopyLink, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        //        self.view.addSubview(buttonMessenger)
        //        buttonMessenger.align(.UnderCentered, relativeTo: buttonFacebook, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.addSubview(buttonTwitter)
        buttonTwitter.align(.UnderCentered, relativeTo: buttonFacebook, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        if optographId != "" {
            let url = TextureURL2(optographId, side: .Left, size: self.view.frame.width, face: 0, x: 0, y: 0, d: 1)
            //self.urlToShare = "https://resources.staging-iam360.io.s3.amazonaws.com/textures/\(val!)/placeholder.jpg"
            self.urlToShare = "http://bucket.iam360.io/textures/\(optographId)/placeholder.jpg"
            
            placeholderImageView!.kf_setImageWithURL(NSURL(string: url)!)
            
            ImageManager.sharedInstance.downloadImage(
                NSURL(string:self.urlToShare)!, requester: self,
                completionHandler: { (image, error, _, _) in
                    if let error = error where error.code != -999 {
                        print(error)
                    }
                    self.imageToShare = image
            })
            
            let optographBox = Models.optographs[optographId]!
            let optograph = optographBox.model
            let person = Models.persons[optograph.personID]!.model
            
            let baseURL = Env == .Staging ? "share.iam360.io" : "share.iam360.io"
            self.shareUrl = NSURL(string: "http://\(baseURL)/\(optograph.shareAlias)")!
            self.textToShare = "Check out this awesome IAM360 image of \(person.displayName)"
        }
    }
    func closeShare() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func copyLink() {
        UIPasteboard.generalPasteboard().string = "\(self.shareUrl)"
        
        let alert = UIAlertController(title: "", message: "Copied on clipboard.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func shareTwitter() {
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter){
            let twitterSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            twitterSheet.setInitialText(self.textToShare)
            twitterSheet.addURL(self.shareUrl)
            self.presentViewController(twitterSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Accounts", message: "Please login to a Twitter account to share.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func shareFacebook() {
        
        let shareOnFb = FacebookShareViewController()
        shareOnFb.optographId = self.optographId
        shareOnFb.modalPresentationStyle = .OverCurrentContext
        self.presentViewController(shareOnFb, animated: true, completion: nil)
    }
    
    func shareMessenger() {
        //
        //        let content = FBSDKShareLinkContent()
        //        content.imageURL = self.shareUrl
        //        content.contentDescription = self.textToShare!
        //
        //        let shareDialog = FBSDKShareDialog()
        //        shareDialog.fromViewController = self
        //        shareDialog.shareContent = content
        //
        //        if !shareDialog.canShow() {
        //            print("cannot show native share dialog")
        //        }
        //        shareDialog.show()
        
        //        let messengerUrl: String = "fb-messenger://user-thread/" + String(uid)
        //        UIApplication.sharedApplication().openURL(NSURL(string: messengerUrl)!)
        
        
    }
    
    func sendEmailButtonTapped() {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        //mailComposerVC.setToRecipients(["nurdin@gmail.com"])
        mailComposerVC.setSubject("Sharing IAM360 image")
        mailComposerVC.setMessageBody("\(self.textToShare) \n\n \(self.shareUrl)", isHTML: true)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
}
