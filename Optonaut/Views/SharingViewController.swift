//
//  SharingViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/12/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class SharingViewController: UIViewController ,TabControllerDelegate{
    
    let buttonCopyLink = UIButton()
    let buttonFacebook = UIButton()
    let buttonMessenger = UIButton()
    let buttonTwitter = UIButton()
    let buttonEmail = UIButton()
    let titleText = UILabel()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        let image: UIImage = UIImage(named: "logo_big")!
        var bgImage: UIImageView?
        bgImage = UIImageView(image: image)
        self.view.addSubview(bgImage!)
        bgImage!.anchorToEdge(.Top, padding: (navigationController?.navigationBar.frame.height)! + 25, width: view.frame.size.width * 0.5, height: view.frame.size.height * 0.13)
        
        let placeholderImageViewImage: UIImage = UIImage(named: "logo_big")!
        var placeholderImageView: UIImageView?
        placeholderImageView = UIImageView(image: placeholderImageViewImage)
        placeholderImageView?.backgroundColor = UIColor.blackColor()
        self.view.addSubview(placeholderImageView!)
        placeholderImageView!.align(.UnderCentered, relativeTo: bgImage!, padding: 15, width: self.view.frame.width - 56, height: 130)
        
        titleText.text = "Share this IAM360 photo:"
        titleText.textAlignment = .Center
        titleText.font = UIFont(name: "Avenir-Book", size: 25)
        self.view.addSubview(titleText)
        titleText.align(.UnderCentered, relativeTo: placeholderImageView!, padding: 5, width: self.view.frame.width - 40, height: 40)
        
        buttonEmail.setImage(UIImage(named: "sharing_email") , forState: .Normal)
        // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        buttonCopyLink.setImage(UIImage(named: "sharing_copyLink_btn") , forState: .Normal)
       // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        buttonFacebook.setImage(UIImage(named: "sharing_facebook_btn") , forState: .Normal)
        // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        buttonMessenger.setImage(UIImage(named: "sharing_messenger_btn") , forState: .Normal)
        // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        buttonTwitter.setImage(UIImage(named: "sharing_twitter_btn") , forState: .Normal)
        // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(buttonEmail)
        buttonEmail.align(.UnderCentered, relativeTo: titleText, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.addSubview(buttonCopyLink)
        buttonCopyLink.align(.UnderCentered, relativeTo: buttonEmail, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.addSubview(buttonFacebook)
        buttonFacebook.align(.UnderCentered, relativeTo: buttonCopyLink, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.addSubview(buttonMessenger)
        buttonMessenger.align(.UnderCentered, relativeTo: buttonFacebook, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.addSubview(buttonTwitter)
        buttonTwitter.align(.UnderCentered, relativeTo: buttonMessenger, padding: 10, width: self.view.frame.width - 40, height: 50)
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        var leftBarImage = UIImage(named: "logo_small")
        leftBarImage = leftBarImage?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: leftBarImage, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.tapRightButton))
        
        tabController!.delegate = self
        
        let optographID:UUID = "a28a5e49-b955-4093-8440-e3e29c61b669"
        let url = TextureURL(optographID, side: .Left, size: self.view.frame.width, face: 0, x: 0, y: 0, d: 1)
        placeholderImageView!.kf_setImageWithURL(NSURL(string: url)!)
    }

    func tapRightButton() {
        tabController!.leftButtonAction()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
