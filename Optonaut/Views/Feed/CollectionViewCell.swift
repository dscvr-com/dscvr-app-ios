//
//  CollectionViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class CollectionViewCell: UICollectionViewCell {
    
    weak var navigationController: NavigationController?
    var viewModel: CollectionViewCellModel!
//    var deleteCallback: (() -> ())? {
//        didSet {
//            infoView.deleteCallback = deleteCallback
//        }
//    }
    
    // subviews
    private let topElements = UIView()
    private let bottomElements = UIView()
    private let bottomBackground = CALayer()
    private let bottomGradient = CAGradientLayer()
    private let previewImageView = PlaceholderImageView()
    private let avatarImageView = PlaceholderImageView()
    private let personNameView = UILabel()
    private let locationTextView = UILabel()
    private let searchButtonView = UIButton()
    private let optionsButtonView = UIButton()
    private let likeButtonView = UIButton()
    private let likeCountView = UILabel()
    private let dateView = UILabel()
    private let textView = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .blackColor()
        
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.accessibilityIdentifier = "preview-image"
        previewImageView.isAccessibilityElement = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        contentView.addSubview(previewImageView)
        
        topElements.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: 122)
        
        let topGradient = CAGradientLayer()
        topGradient.frame = topElements.frame
        topGradient.colors = [UIColor.blackColor().alpha(0.5).CGColor, UIColor.clearColor().CGColor]
        topElements.layer.addSublayer(topGradient)
        
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.layer.borderColor = UIColor.whiteColor().CGColor
        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.clipsToBounds = true
        topElements.addSubview(avatarImageView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = .whiteColor()
        topElements.addSubview(personNameView)
        
        searchButtonView.titleLabel?.font = UIFont.iconOfSize(28)
        searchButtonView.setTitle(String.iconWithName(.Search), forState: .Normal)
        topElements.addSubview(searchButtonView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(28)
        optionsButtonView.setTitle(String.iconWithName(.More_Vert), forState: .Normal)
        topElements.addSubview(optionsButtonView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = .whiteColor()
        topElements.addSubview(locationTextView)
        
        contentView.addSubview(topElements)
        
        bottomGradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().alpha(0.5).CGColor]
        bottomElements.layer.addSublayer(bottomGradient)
        
        likeButtonView.layer.cornerRadius = 14
        likeButtonView.clipsToBounds = true
        likeButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleLike"))
        likeButtonView.setTitle(String.iconWithName(.HeartFilled), forState: .Normal)
        bottomElements.addSubview(likeButtonView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        bottomElements.addSubview(likeCountView)
        
        dateView.font = UIFont.displayOfSize(11, withType: .Thin)
        dateView.textColor = .whiteColor()
        dateView.textAlignment = .Right
        bottomElements.addSubview(dateView)
        
        textView.font = UIFont.displayOfSize(13, withType: .Light)
        textView.textColor = .whiteColor()
        textView.userInteractionEnabled = true
        textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleText"))
        bottomElements.addSubview(textView)
        
        bottomElements.clipsToBounds = true
        contentView.addSubview(bottomElements)
        
        bottomBackground.frame = CGRect(x: 0, y: contentView.frame.height - 108, width: contentView.frame.width, height: 108)
        bottomBackground.backgroundColor = UIColor.blackColor().alpha(0.5).CGColor
        contentView.layer.addSublayer(bottomBackground)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        previewImageView.fillSuperview()
        avatarImageView.anchorInCorner(.TopLeft, xPad: 16.5, yPad: 28.5, width: 43, height: 43)
        searchButtonView.anchorInCorner(.TopRight, xPad: 52, yPad: 37, width: 24, height: 24)
        optionsButtonView.anchorInCorner(.TopRight, xPad: 14, yPad: 37, width: 24, height: 24)
        dateView.anchorInCorner(.TopRight, xPad: 18, yPad: 17, width: 70, height: 13)
    }
    
    func bindViewModel(optograph: Optograph) {
        viewModel = CollectionViewCellModel(optograph: optograph)
        
        previewImageView.rac_url <~ viewModel.previewImageUrl
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        personNameView.text = optograph.person.displayName
        locationTextView.text = optograph.location?.text
        dateView.text = optograph.createdAt.longDescription
        textView.text = optograph.text
        likeCountView.rac_text <~ viewModel.likeCount.producer.map { "\($0)" }
        
        viewModel.textToggled.producer.startWithNext { [weak self] toggled in
            if let strongSelf = self {
                let textHeight = calcTextHeight(optograph.text, withWidth: strongSelf.contentView.frame.width - 36, andFont: UIFont.displayOfSize(13, withType: .Light))
                let displayedTextHeight = toggled && textHeight > 16 ? textHeight : 15
                let bottomHeight: CGFloat = 50 + (optograph.text.isEmpty ? 0 : displayedTextHeight + 11)
                
                UIView.setAnimationCurve(.EaseInOut)
                UIView.animateWithDuration(0.3) {
                    strongSelf.bottomElements.frame = CGRect(x: 0, y: strongSelf.contentView.frame.height - 108 - bottomHeight, width: strongSelf.contentView.frame.width, height: bottomHeight)
                }
                
                strongSelf.textView.anchorInCorner(.BottomLeft, xPad: 18, yPad: 16, width: strongSelf.contentView.frame.width - 36, height: displayedTextHeight)
                
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.3)
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
                strongSelf.bottomGradient.frame = CGRect(x: 0, y: 0, width: strongSelf.contentView.frame.width, height: bottomHeight)
                CATransaction.commit()
                
                strongSelf.textView.numberOfLines = toggled ? 0 : 1
            }
        }
        
        viewModel.liked.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
                if liked {
                    strongSelf.likeButtonView.anchorInCorner(.TopLeft, xPad: 18, yPad: 10, width: 28, height: 28)
                    strongSelf.likeButtonView.backgroundColor = .Accent
                    strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(12)
                } else {
                    strongSelf.likeButtonView.anchorInCorner(.TopLeft, xPad: 18, yPad: 10, width: 20, height: 28)
                    strongSelf.likeButtonView.backgroundColor = .clearColor()
                    strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(21)
                }
                strongSelf.likeCountView.align(.ToTheRightCentered, relativeTo: strongSelf.likeButtonView, padding: 8, width: 40, height: 13)
            }
        }
        
        if let location = optograph.location {
            locationTextView.text = "\(location.text), \(location.country)"
            personNameView.anchorInCorner(.TopLeft, xPad: 69, yPad: 34, width: 100, height: 18)
            locationTextView.anchorInCorner(.TopLeft, xPad: 69, yPad: 53, width: 200, height: 13)
        } else {
            personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
        }
        
//        infoView.bindViewModel(optograph)
//        infoView.navigationController = navigationController
    }
    
    func toggleText() {
        viewModel.textToggled.value = !viewModel.textToggled.value
    }
    
    func toggleLike() {
        viewModel.toggleLike()
    }
    
    func pushDetails() {
        if viewModel.optograph.isStitched {
            navigationController?.pushViewController(DetailsTableViewController(optographID: viewModel.optograph.ID), animated: true)
        }
    }
    
}