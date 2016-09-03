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
import FBSDKLoginKit

class ShareData {
    class var sharedInstance: ShareData {
        struct Static {
            static var instance: ShareData?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ShareData()
        }
        
        return Static.instance!
    }
    var optographId = MutableProperty<UUID?>(nil)
    var isSharePageOpen = MutableProperty<Bool>(false)
}


class SharingViewController: UIViewController ,TabControllerDelegate,MFMailComposeViewControllerDelegate{
    
    let buttonCopyLink = UIButton()
    let buttonFacebook = UIButton()
    //let buttonMessenger = UIButton()
    let buttonTwitter = UIButton()
    let buttonEmail = UIButton()
    let titleText = UILabel()
    var textToShare:String = ""
    var shareUrl:NSURL = NSURL(string: "")!
    //var imageToShare: UIImage?
    var placeHolderToShare = UIImageView()
    var urlToShare:String = ""
    var descriptionToShare:String = ""
    var optographId:String = ""
    var tField: UITextField!
    var activityIndicator = UIActivityIndicatorView()
    var scrollView: UIScrollView?
    var shareView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: view.bounds)
        view.addSubview(scrollView!)
        
        scrollView!.addSubview(shareView)
        scrollView?.scrollEnabled = true
        
        if view.frame.height != 568.0 {
            scrollView?.scrollEnabled = false
            shareView.fillSuperview()
            print("view height>>>>",view.frame.height)
        } else {
            print("view height>>",view.frame.height)
            shareView.frame = CGRect(x: 0,y: 0,width: view.width,height: view.height + 50)
        }
        
        scrollView!.contentSize = shareView.bounds.size
        
        let image: UIImage = UIImage(named: "logo_share")!
        var bgImage: UIImageView?
        bgImage = UIImageView(image: image)
        shareView.addSubview(bgImage!)
        bgImage!.anchorToEdge(.Top, padding: 10, width: image.size.width, height: image.size.height)
        
        let placeholderImageViewImage: UIImage = UIImage(named: "logo_settings")!
        var placeholderImageView: UIImageView?
        placeholderImageView = UIImageView(image: placeholderImageViewImage)
        placeholderImageView?.backgroundColor = UIColor.blackColor()
        shareView.addSubview(placeholderImageView!)
        placeholderImageView!.align(.UnderCentered, relativeTo: bgImage!, padding: 15, width: self.view.frame.width - 56, height: 130)
        
        titleText.text = "Share this 360 image:"
        titleText.textAlignment = .Center
        titleText.font = UIFont(name: "Avenir-Book", size: 25)
        shareView.addSubview(titleText)
        titleText.align(.UnderCentered, relativeTo: placeholderImageView!, padding: 5, width: self.view.frame.width - 40, height: 40)
        
        
        buttonEmail.setImage(UIImage(named: "sharing_email") , forState: .Normal)
        buttonEmail.addTarget(self, action: #selector(sendEmailButtonTapped), forControlEvents: .TouchUpInside)
        
        buttonCopyLink.setImage(UIImage(named: "sharing_copyLink_btn") , forState: .Normal)
        buttonCopyLink.addTarget(self, action: #selector(copyLink), forControlEvents: .TouchUpInside)
        
        buttonFacebook.setImage(UIImage(named: "sharing_facebook_btn") , forState: .Normal)
        buttonFacebook.addTarget(self, action: #selector(tapFacebookSocialButton), forControlEvents: .TouchUpInside)
        
//        buttonMessenger.setImage(UIImage(named: "sharing_messenger_btn") , forState: .Normal)
//        buttonMessenger.addTarget(self, action: #selector(shareMessenger), forControlEvents: .TouchUpInside)
        
        buttonTwitter.setImage(UIImage(named: "sharing_twitter_btn") , forState: .Normal)
        buttonTwitter.addTarget(self, action: #selector(shareTwitter), forControlEvents: .TouchUpInside)
        
        shareView.addSubview(buttonEmail)
        buttonEmail.align(.UnderCentered, relativeTo: titleText, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        shareView.addSubview(buttonCopyLink)
        buttonCopyLink.align(.UnderCentered, relativeTo: buttonEmail, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        shareView.addSubview(buttonFacebook)
        buttonFacebook.align(.UnderCentered, relativeTo: buttonCopyLink, padding: 10, width: self.view.frame.width - 40, height: 50)
        
//        self.view.addSubview(buttonMessenger)
//        buttonMessenger.align(.UnderCentered, relativeTo: buttonFacebook, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        shareView.addSubview(buttonTwitter)
        buttonTwitter.align(.UnderCentered, relativeTo: buttonFacebook, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.backgroundColor = UIColor.whiteColor()
        
       // var leftBarImage = UIImage(named: "logo_small")
        var leftBarImage = UIImage(named:"iam360_navTitle")
        leftBarImage = leftBarImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: leftBarImage, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.tapRightButton))
        
        tabController!.delegate = self
        
        let shareData = ShareData.sharedInstance
        
        shareData.optographId.producer.startWithNext{ val in
            
            if val != nil {
                let url = TextureURL2(val!, side: .Left, size: self.view.frame.width, face: 0, x: 0, y: 0, d: 1)
                //self.urlToShare = "https://resources.staging-iam360.io.s3.amazonaws.com/textures/\(val!)/placeholder.jpg"
                self.urlToShare = "http://bucket.iam360.io/textures/\(val!)/placeholder.jpg"
                
                self.optographId = val!
                
                placeholderImageView!.kf_setImageWithURL(NSURL(string: url)!)
                
                let optographBox = Models.optographs[val]!
                let optograph = optographBox.model
                let person = Models.persons[optograph.personID]!.model
                
                let baseURL = Env == .Staging ? "wow.dscvr.com" : "wow.dscvr.com"
                self.shareUrl = NSURL(string: "http://\(baseURL)/\(optograph.shareAlias)")!
                self.textToShare = "Check out this awesome IAM360 image of \(person.displayName)"
            }
        }
        
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        
        activityIndicator.center = self.view.center
        
        activityIndicator.stopAnimating()
        
        self.view.addSubview(activityIndicator)
        
//        let result = FBSDKMessengerSharer.messengerPlatformCapabilities().rawValue & FBSDKMessengerPlatformCapability.Image.rawValue
//        if result != 0 {
//            // ok now share
//            if let sharingImage = sharingImage {
//                FBSDKMessengerSharer.shareImage(sharingImage, withOptions: nil)
//            }
//        } else {
//            // not installed then open link. Note simulator doesn't open iTunes store.
//            UIApplication.sharedApplication().openURL(NSURL(string: "itms://itunes.apple.com/us/app/facebook-messenger/id454638411?mt=8")!)
//        }
        
    }
    

    func copyLink() {
        UIPasteboard.generalPasteboard().string = "\(self.shareUrl)"
        
        let alert = UIAlertController(title: "", message: "Copied on clipboard.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func tapRightButton() {
        print("weweww")
        tabController!.leftButtonAction()
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
        shareOnFb.link = "\(self.shareUrl)"
        shareOnFb.modalPresentationStyle = .OverCurrentContext
        self.navigationController?.presentViewController(shareOnFb, animated: true, completion: nil)
    }
    
    
    func tapFacebookSocialButton() {
        let loginManager = FBSDKLoginManager()
        let publishPermissions = ["publish_actions"]
        
        let errorBlock = { [weak self] (message: String) in
            
            let alert = UIAlertController(title: "Facebook Signin unsuccessful", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Try again", style: .Default, handler: { _ in return }))
            self?.presentViewController(alert, animated: true, completion: nil)
        }
        
        let successBlock = { [weak self] (token: FBSDKAccessToken!) in
            let parameters  = [
                "facebook_user_id": token.userID,
                "facebook_token": token.tokenString,
                ]
            ApiService<EmptyResponse>.put("persons/me", parameters: parameters)
                .on(
                    failed: { _ in
                        errorBlock("Something went wrong and we couldn't sign you in. Please try again.")
                    },
                    completed: { [weak self] in
                        self!.shareFacebook()
                    }
                )
                .start()
        }
        
        if let token = FBSDKAccessToken.currentAccessToken() where publishPermissions.reduce(true, combine: { $0 && token.hasGranted($1) }) {
            self.shareFacebook()
            return
        }
        
        loginManager.logInWithPublishPermissions(publishPermissions, fromViewController: self) { [weak self] result, error in
            if error != nil || result.isCancelled {
                loginManager.logOut()
            } else {
                let grantedPermissions = result.grantedPermissions.map( {"\($0)"} )
                let allPermissionsGranted = publishPermissions.reduce(true) { $0 && grantedPermissions.contains($1) }
                if allPermissionsGranted {
                    successBlock(result.token)
                } else {
                    errorBlock("Please allow access to all points in the list. Don't worry, your data will be kept safe.")
                }
            }
        }
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
        
        if UIApplication.sharedApplication().canOpenURL(NSURL(string:"fb-messenger://")!) {
            UIApplication.sharedApplication().openURL(NSURL(string:"fb-messenger://")!)
        } else {
            print("can't send an fb messenger!")
        }
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
        
        //mailComposerVC.setToRecipients(["robert.alkuino@gmail.com"])
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
