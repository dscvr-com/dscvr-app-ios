//
//  SharingViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/12/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class SharingViewController: UIViewController {
    
    let buttonCopyLink = UIButton()
    let buttonFacebook = UIButton()
    let buttonMessenger = UIButton()
    let buttonTwitter = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        let image: UIImage = UIImage(named: "logo_big")!
        var bgImage: UIImageView?
        bgImage = UIImageView(image: image)
        self.view.addSubview(bgImage!)
        bgImage!.anchorToEdge(.Top, padding: 60, width: view.frame.size.width * 0.5, height: view.frame.size.height * 0.13)
        
        buttonCopyLink.setImage(UIImage(named: "sharing_copyLink_btn") , forState: .Normal)
       // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        buttonFacebook.setImage(UIImage(named: "sharing_facebook_btn") , forState: .Normal)
        // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        buttonMessenger.setImage(UIImage(named: "sharing_messenger_btn") , forState: .Normal)
        // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        buttonTwitter.setImage(UIImage(named: "sharing_twitter_btn") , forState: .Normal)
        // buttonCopyLink.addTarget(self, action: #selector(myClass.pressed(_:)), forControlEvents: .TouchUpInside)
        
        
        self.view.addSubview(buttonCopyLink)
        buttonCopyLink.align(.UnderCentered, relativeTo: bgImage!, padding: 40, width: self.view.frame.width - 40, height: 60)
        
        self.view.addSubview(buttonFacebook)
        buttonFacebook.align(.UnderCentered, relativeTo: buttonCopyLink, padding: 15, width: self.view.frame.width - 40, height: 60)
        
        self.view.addSubview(buttonMessenger)
        buttonMessenger.align(.UnderCentered, relativeTo: buttonFacebook, padding: 15, width: self.view.frame.width - 40, height: 60)
        
        self.view.addSubview(buttonTwitter)
        buttonTwitter.align(.UnderCentered, relativeTo: buttonMessenger, padding: 15, width: self.view.frame.width - 40, height: 60)
        
//        self.view.groupAndAlign(group: .Vertical, andAlign: .UnderCentered, views: [buttonCopyLink, buttonFacebook, buttonMessenger,buttonTwitter], relativeTo: bgImage!, padding: 15, width: self.view.frame.width - 40, height: 60)
        
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
