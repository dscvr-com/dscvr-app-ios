//
//  OptographTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import HexColor
import ActiveLabel

class OptographTableViewCell: UITableViewCell {
    
    weak var navigationController: NavigationController?
    var viewModel: OptographTableViewCellModel!
    
    // subviews
    private let previewImageView = PlaceholderImageView()
    private let infoView = OptographInfoView()
//    private let bottomBackgroundView = BackgroundView()
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .whiteColor()
        
//        previewImageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        contentView.addSubview(previewImageView)
        
//        blurView.alpha = 0.9
        previewImageView.addSubview(blurView)
        
        contentView.addSubview(infoView)
        
//        contentView.addSubview(bottomBackgroundView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoSetDimension(.Height, toSize: contentView.frame.width * 5 / 4 + 78)
        
        blurView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)
        blurView.autoSetDimension(.Height, toSize: 78)
        
        infoView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView)
        infoView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView)
        infoView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView)
        infoView.autoSetDimension(.Height, toSize: 78)
        
//        bottomBackgroundView.autoPinEdge(.Top, toEdge: .Bottom, ofView: infoView)
//        bottomBackgroundView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)
        
        super.updateConstraints()
    }
    
    func bindViewModel(optograph: Optograph) {
        viewModel = OptographTableViewCellModel(optograph: optograph)
        
        previewImageView.rac_url <~ viewModel.previewImageUrl
        
        infoView.bindViewModel(optograph)
        infoView.navigationController = navigationController
    }
    
    func pushDetails() {
        navigationController?.pushViewController(DetailsTableViewController(optographId: viewModel.optograph.id), animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}