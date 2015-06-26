//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ProfileViewController: UIViewController {
    
    var viewModel: ProfileViewModel
    
    // subviews
    let numberOfFollowersView = UILabel()
    let numberOfFollowingsView = UILabel()
    let numberOfOptographsView = UILabel()
    var optographsView: UIView!
    
    required init(userId: Int) {
        viewModel = ProfileViewModel(id: userId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        viewModel = ProfileViewModel(id: 0)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributes = [NSFontAttributeName: UIFont.fontAwesomeOfSize(20)] as Dictionary!
        let signoutButton = UIBarButtonItem()
        signoutButton.setTitleTextAttributes(attributes, forState: .Normal)
        signoutButton.title = String.fontAwesomeIconWithName(.SignOut)
        signoutButton.target = self
        signoutButton.action = "logout"
        navigationItem.setRightBarButtonItem(signoutButton, animated: false)
        navigationItem.rac_title <~ viewModel.userName.producer |> map { "@\($0)" }
        
        let optographTableViewController = OptographTableViewController(source: "users/\(viewModel.id.value)/optographs", navController: navigationController)
        optographsView = optographTableViewController.view
        view.addSubview(optographsView)
        
        numberOfFollowersView.rac_text <~ viewModel.numberOfFollowers.producer |> map { "Follower: \($0)" }
        view.addSubview(numberOfFollowersView)
        
        numberOfFollowingsView.rac_text <~ viewModel.numberOfFollowings.producer |> map { "Following: \($0)" }
        view.addSubview(numberOfFollowingsView)
        
        numberOfOptographsView.rac_text <~ viewModel.numberOfOptographs.producer |> map { "Optographs: \($0)" }
        view.addSubview(numberOfOptographsView)
        
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
    
}
