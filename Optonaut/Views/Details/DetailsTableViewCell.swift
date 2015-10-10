//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ActiveLabel

class DetailsTableViewCell: UITableViewCell {
    
    weak var viewModel: DetailsViewModel!
    weak var navigationController: NavigationController?
    
    // subviews
    private let infoView = OptographInfoView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        contentView.addSubview(infoView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        infoView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        infoView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView)
        infoView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView)
        infoView.autoSetDimension(.Height, toSize: 75)
        
        super.updateConstraints()
    }
    
    func bindViewModel() {
        infoView.bindViewModel(viewModel.optograph)
        infoView.navigationController = navigationController
    }
    
    func toggleStar() {
        viewModel.toggleLike()
    }
    
    func pushProfile() {
        let profileContainerViewController = ProfileTableViewController(personId: viewModel.personId.value)
        navigationController?.pushViewController(profileContainerViewController, animated: true)
    }
    
    func pushViewer() {
        if viewModel.downloadProgress.value == 1 {
            let alert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
}

// MARK: - OptographOptions
extension DetailsTableViewCell: OptographOptions {
    
    func didTapOptions() {
        showOptions(viewModel.optograph)
    }
    
}