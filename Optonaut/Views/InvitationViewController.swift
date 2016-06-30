//
//  InvitationViewController.swift
//  DSCVR
//
//  Created by robert john alkuino on 6/30/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class InvitationViewController: UIViewController {

    
    var label1 = UILabel()
    var label2 = UILabel()
    var logoImageView = UIImageView()
    var textPutCode = UITextField()
    var textRequestCode = UITextField()
    var buttonPutCode = UIButton()
    var view1 = UIView()
    var orImage = UIImageView()
    var requestButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hex:0x343434)
        
        let logo: UIImage = UIImage(named: "logo_big")!
        logoImageView.image = logo
        view.addSubview(logoImageView)
        
        let dragTextWidth = calcTextWidth("Type Super Secret Code", withFont: .displayOfSize(20, withType: .Semibold))
        label1.text = "Type Super Secret Code"
        label1.font = UIFont(name: "Avenir-Book", size: 20)
        label1.backgroundColor = UIColor.clearColor()
        label1.textColor = UIColor.whiteColor()
        label1.textAlignment = .Center
        view.addSubview(label1)
        
        view1.backgroundColor = UIColor.clearColor()
        view.addSubview(view1)
        
        textPutCode.backgroundColor = UIColor(hex:0xCACACA)
        textPutCode.layer.cornerRadius = 2
        view1.addSubview(textPutCode)
        
        buttonPutCode.setTitle("GO", forState: .Normal)
        buttonPutCode.layer.cornerRadius = 2
        buttonPutCode.titleLabel!.font =  UIFont(name: "Helvetica", size: 12)
        buttonPutCode.backgroundColor = UIColor(hex:0xffbc00)
        buttonPutCode.setTitleColor(UIColor(hex:0x343434), forState: .Normal)
        buttonPutCode.addTarget(self,action: #selector(pushCode),forControlEvents: .TouchUpInside)
        view1.addSubview(buttonPutCode)
        
        let orText: UIImage = UIImage(named: "or_icn")!
        orImage.image = orText
        view.addSubview(orImage)
        
        label2.text = "Request Super Secret Code"
        label2.font = UIFont(name: "Avenir-Book", size: 20)
        label2.backgroundColor = UIColor.clearColor()
        label2.textAlignment = .Center
        label2.textColor = UIColor.whiteColor()
        view.addSubview(label2)
        
        textRequestCode.backgroundColor = UIColor(hex:0xCACACA)
        textRequestCode.layer.cornerRadius = 2
        view.addSubview(textRequestCode)
        
        requestButton.setTitle("REQUEST", forState: .Normal)
        requestButton.layer.cornerRadius = 2
        requestButton.titleLabel!.font =  UIFont(name: "Helvetica", size: 12)
        requestButton.backgroundColor = UIColor(hex:0xffbc00)
        requestButton.setTitleColor(UIColor(hex:0x343434), forState: .Normal)
        requestButton.addTarget(self,action: #selector(pushCode),forControlEvents: .TouchUpInside)
        view.addSubview(requestButton)
        
        logoImageView.anchorToEdge(.Top, padding: 40, width: logo.size.width, height: logo.size.height)
        label1.align(.UnderCentered, relativeTo: logoImageView, padding: 55, width: dragTextWidth, height: 25)
        
        let viewwidth = (view.frame.width-49)/3
        
        textPutCode.anchorInCorner(.TopLeft, xPad: 0, yPad: 0, width: viewwidth * 2, height: 40)
        buttonPutCode.align(.ToTheRightMatchingBottom, relativeTo: textPutCode, padding: 5, width: viewwidth, height: 40)
        view1.align(.UnderCentered, relativeTo: label1, padding: 16, width: view.frame.width-49, height: 40)
        orImage.align(.UnderCentered, relativeTo: view1, padding: 49, width: orText.size.width, height: orText.size.height)
        label2.align(.UnderCentered, relativeTo: orImage, padding: 22, width: view.frame.width-44, height: 50)
        
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    func pushCode() {
    
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
