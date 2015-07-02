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
//    let numberOfOptographsView = UILabel()
    let followButtonView = UIButton()
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
        
        view.backgroundColor = .whiteColor()
        
        navigationItem.rac_title <~ viewModel.userName.producer |> map { "@\($0)" }
        
        let optographTableViewController = OptographTableViewController(source: "users/\(viewModel.id.value)/optographs", navController: navigationController)
        optographsView = optographTableViewController.view
        view.addSubview(optographsView)
        
        followButtonView.backgroundColor = baseColor()
        followButtonView.layer.cornerRadius = 5
        followButtonView.layer.masksToBounds = true
        viewModel.isFollowing.producer |>
            start(next: { isFollowing in
                let title = isFollowing ? "Unfollow" : "Follow"
                self.followButtonView.setTitle(title, forState: .Normal)
            })
        followButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleFollow()
            return RACSignal.empty()
        })
        view.addSubview(followButtonView)
        
        numberOfFollowersView.font = .systemFontOfSize(14)
        numberOfFollowersView.rac_text <~ viewModel.numberOfFollowers.producer |> map { "Follower: \($0)" }
        view.addSubview(numberOfFollowersView)
        
        numberOfFollowingsView.font = .systemFontOfSize(14)
        numberOfFollowingsView.rac_text <~ viewModel.numberOfFollowings.producer |> map { "Following: \($0)" }
        view.addSubview(numberOfFollowingsView)
        
//        numberOfOptographsView.font = .systemFontOfSize(14)
//        numberOfOptographsView.rac_text <~ viewModel.numberOfOptographs.producer |> map { "Optographs: \($0)" }
//        view.addSubview(numberOfOptographsView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        followButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 10)
        followButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 10)
        followButtonView.autoSetDimension(.Width, toSize: 150)
        
        numberOfFollowersView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 10)
        numberOfFollowersView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -10)
        
        numberOfFollowingsView.autoPinEdge(.Top, toEdge: .Bottom, ofView: numberOfFollowersView, withOffset: 1)
        numberOfFollowingsView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -10)
        
//        numberOfOptographsView.autoPinEdge(.Top, toEdge: .Bottom, ofView: numberOfFollowingsView, withOffset: 5)
//        numberOfOptographsView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -10)
        
        optographsView.autoPinEdge(.Top, toEdge: .Bottom, ofView: numberOfFollowingsView, withOffset: 10)
        optographsView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view)
        optographsView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        optographsView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        
        super.updateViewConstraints()
    }
    
}
