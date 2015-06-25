//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import RealmSwift

class ProfileViewController: UIViewController {
    
    var userId = 0
    var user = Realm().objects(User).first ?? User()
    
    // subviews
    let numberOfFollowersView = UILabel()
    let numberOfFollowingsView = UILabel()
    let numberOfOptographsView = UILabel()
    var optographsView: UIView!
    
    required init(userId: Int) {
        super.init(nibName: nil, bundle: nil)
        self.userId = userId
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        updateView()
        
        let attributes = [NSFontAttributeName: UIFont.fontAwesomeOfSize(20)] as Dictionary!
        let cameraButton = UIBarButtonItem()
        cameraButton.setTitleTextAttributes(attributes, forState: .Normal)
        cameraButton.title = String.fontAwesomeIconWithName(.SignOut)
        cameraButton.target = self
        cameraButton.action = "logout"
        navigationItem.setRightBarButtonItem(cameraButton, animated: false)
        
        let optographTableViewController = OptographTableViewController(source: "optographs", navController: navigationController)
        optographsView = optographTableViewController.view
        
        view.addSubview(optographsView)
        view.addSubview(numberOfFollowersView)
        view.addSubview(numberOfFollowingsView)
        view.addSubview(numberOfOptographsView)
        
        fetchData()
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        numberOfFollowersView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 20)
        numberOfFollowersView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        
        numberOfFollowingsView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 20)
        numberOfFollowingsView.autoPinEdge(.Right, toEdge: .Left, ofView: numberOfFollowersView, withOffset: -20)
        
        numberOfOptographsView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 20)
        numberOfOptographsView.autoPinEdge(.Right, toEdge: .Left, ofView: numberOfFollowingsView, withOffset: -20)
        
        optographsView.autoPinEdge(.Top, toEdge: .Bottom, ofView: numberOfOptographsView, withOffset: 20)
        optographsView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view)
        optographsView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        optographsView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        
        super.updateViewConstraints()
    }
    
    func logout() {
        let refreshAlert = UIAlertController(title: "You're about to log out...", message: "Really? Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Sign out", style: .Default, handler: { (action: UIAlertAction!) in
            NSUserDefaults.standardUserDefaults().setObject("", forKey: UserDefaultsKeys.USER_TOKEN.rawValue)
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: UserDefaultsKeys.USER_IS_LOGGED_IN.rawValue)
            self.presentViewController(LoginViewController(), animated: false, completion: nil)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { _ in return }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
    func updateView() {
        if user.id == 0 { return }
        
        navigationItem.title = "@\(user.userName)"
        
        numberOfFollowersView.text = "Follower: \(user.numberOfFollowers)"
        numberOfFollowingsView.text = "Following: \(user.numberOfFollowings)"
        numberOfOptographsView.text = "Optographs: \(user.numberOfOptographs)"
    }
    
    func fetchData() {
//        Api().get("users/\(userId)", authorized: true,
//            success: { json in
//                let realm = Realm()
//                
//                realm.write {
//                    self.user.id = json!["id"].intValue
//                    self.user.email = json!["email"].stringValue
//                    self.user.userName = json!["user_name"].stringValue
//                    self.user.numberOfFollowers = json!["number_of_followers"].intValue
//                    self.user.numberOfFollowings = json!["number_of_followings"].intValue
//                    self.user.numberOfOptographs = json!["number_of_optographs"].intValue
//                    realm.add(self.user, update: true)
//                    
//                    self.updateView()
//                }
//            },
//            fail: { error in
//                println(error)
//            }
//        )
    }
    
}
