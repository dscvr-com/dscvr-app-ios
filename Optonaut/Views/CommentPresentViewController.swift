//
//  CommentPresentViewController.swift
//  DSCVR
//
//  Created by robert john alkuino on 8/23/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class CommentPresentViewController: UIViewController {

    var optographID:UUID = ""
    
    required init(optographID: UUID) {
        
        self.optographID = optographID
        logInit()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clearColor()
        
        print("awawawaw")
        // Do any additional setup after loading the view.
        let commentPage = CommentTableViewController(optographID: self.optographID)
        commentPage.modalPresentationStyle = .OverCurrentContext
        self.navigationController?.presentViewController(commentPage, animated: true, completion: nil)
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
