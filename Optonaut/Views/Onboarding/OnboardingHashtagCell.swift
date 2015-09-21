//
//  OnboardingHashtagCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/19/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class OnboardingHashtagCell: UICollectionViewCell {
    
    private let viewModel = OnboardingHashtagViewModel()
    
    // subviews
    private let imageView = PlaceholderImageView()
    private let nameView = UILabel()
    private let checkView = UILabel()
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.rac_url <~ viewModel.imageUrl
        imageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 5
        contentView.addSubview(imageView)
        
        nameView.rac_text <~ viewModel.name.producer.map { "#\($0)" }
        nameView.textAlignment = .Center
        nameView.textColor = .whiteColor()
        nameView.font = UIFont.robotoOfSize(14, withType: .Bold)
        contentView.addSubview(nameView)
        
        checkView.rac_hidden <~ viewModel.isFollowed.producer.map(negate)
        checkView.text = String.icomoonWithName(.LnrCheck)
        checkView.font = UIFont.icomoonOfSize(35)
        checkView.textColor = .Accent
        checkView.textAlignment = .Center
        checkView.backgroundColor = .whiteColor()
        checkView.layer.cornerRadius = 18
        checkView.clipsToBounds = true
        contentView.addSubview(checkView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        imageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 5)
        imageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 5)
        imageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView, withOffset: -10)
        imageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView, withOffset: -10)
        
        nameView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 13)
        nameView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView, withOffset: -13)
        
        checkView.autoAlignAxis(.Vertical, toSameAxisOfView: contentView)
        checkView.autoAlignAxis(.Horizontal, toSameAxisOfView: contentView)
        checkView.autoSetDimension(.Width, toSize: 36)
        checkView.autoSetDimension(.Height, toSize: 36)
        
        super.updateConstraints()
    }
    
    func setHashtag(hashtag: Hashtag) {
        viewModel.setHashtag(hashtag)
    }
    
}