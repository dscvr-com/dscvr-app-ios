//
//  BTList.swift
//  DSCVR
//
//  Created by robert john alkuino on 11/15/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//


import UIKit

class BTList: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    
    var tableView =  UITableView()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.frame = CGRect(x: 0,y: 60,width: view.width,height: view.height - 60)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let navView = UIView()
        navView.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(navView)
        navView.anchorAndFillEdge(.Top, xPad: 0, yPad: 0, otherSize: 50)
        
        let closeButton = UIButton()
        closeButton.setBackgroundImage(UIImage(named:"close_icn"), forState: .Normal)
        closeButton.anchorInCorner(.TopLeft, xPad: 10, yPad: 10, width: 40 , height: 40)
        closeButton.addTarget(self, action: #selector(closeBT), forControlEvents: .TouchUpInside)
        navView.addSubview(closeButton)
    }
    
    func closeBT() {
        dismissViewControllerAnimated(false, completion: nil)
    }
    //UITableView methods
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        
        let peripheralName = btDiscoverySharedInstance.devicesNameList()[indexPath.row]
        cell.textLabel?.text = peripheralName.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return btDiscoverySharedInstance.devicesNameList().count
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        btDiscoverySharedInstance.connectToPeripheral(btDiscoverySharedInstance.devicesNameList()[indexPath.row])
        dismissViewControllerAnimated(false, completion: nil)
    }
}