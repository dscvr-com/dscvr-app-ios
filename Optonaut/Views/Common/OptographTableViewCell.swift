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
    var deleteCallback: (() -> ())? {
        didSet {
            infoView.deleteCallback = deleteCallback
        }
    }
    
    // subviews
    private let previewImageView = PlaceholderImageView()
    private let infoView = OptographInfoView()
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    private let progressView = ProgressView()
    private let progressTextView = UILabel()
    private var blurViewHeightConstraint = NSLayoutConstraint()
    
    private var progressDisposable: Disposable?
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .blackColor()
        
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.accessibilityIdentifier = "preview-image"
        previewImageView.isAccessibilityElement = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        contentView.addSubview(previewImageView)
        
        previewImageView.addSubview(blurView)
        
        progressTextView.text = "Rendering..."
        progressTextView.font = UIFont.displayOfSize(14, withType: .Regular)
        progressTextView.textColor = .whiteColor()
        previewImageView.addSubview(progressTextView)
        
        previewImageView.addSubview(progressView)
        
        infoView.userInteractionEnabled = true
        infoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        infoView.accessibilityIdentifier = "info"
        infoView.isAccessibilityElement = true
        contentView.addSubview(infoView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoSetDimension(.Height, toSize: contentView.frame.width * 5 / 4 + 78)
        
        progressTextView.autoAlignAxis(.Vertical, toSameAxisOfView: contentView)
        progressTextView.autoAlignAxis(.Horizontal, toSameAxisOfView: contentView, withOffset: -20)
        
        progressView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView)
        progressView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView)
        progressView.autoPinEdge(.Bottom, toEdge: .Top, ofView: infoView)
        progressView.autoSetDimension(.Height, toSize: 4)
        
        infoView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView)
        infoView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView)
        infoView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView)
        infoView.autoSetDimension(.Height, toSize: 78)
        
        blurView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)
        blurViewHeightConstraint = blurView.autoSetDimension(.Height, toSize: 78)
        
        super.updateConstraints()
    }
    
    func bindViewModel(optograph: Optograph) {
        viewModel = OptographTableViewCellModel(optograph: optograph)
        
        previewImageView.rac_url <~ viewModel.previewImageUrl
        
        progressDisposable?.dispose()
//        progressDisposable = viewModel.stitchingProgress.producer
//            .observeOnMain()
//            .startWithNext { [unowned self] progress in
//                self.progressView.progress = progress
//                self.progressTextView.hidden = progress == 1
//                if progress == 1 {
//                    self.blurViewHeightConstraint.constant = 78
//                    // TODO update optograph in infoViewModel to reflect stitching status
//                } else {
//                    self.blurViewHeightConstraint.constant = self.contentView.frame.height
//                }
//            }
        
        infoView.bindViewModel(optograph)
        infoView.navigationController = navigationController
    }
    
    func pushDetails() {
        if viewModel.optograph.isStitched {
            navigationController?.pushViewController(DetailsTableViewController(optographID: viewModel.optograph.ID), animated: true)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}