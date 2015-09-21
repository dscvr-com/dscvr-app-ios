//
//  OnboardingHashtagViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class OnboardingHashtagHeaderView: UICollectionReusableView {
    
    private let headlineView = UILabel()
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        
        headlineView.text = "PICK AT LEAST 3 HASHTAGS"
        headlineView.textColor = .Accent
        headlineView.textAlignment = .Center
        headlineView.font = UIFont.robotoOfSize(16, withType: .Bold)
        addSubview(headlineView)
        
        setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        headlineView.autoAlignAxis(.Vertical, toSameAxisOfView: self)
        headlineView.autoAlignAxis(.Horizontal, toSameAxisOfView: self, withMultiplier: 1.2)
        
        super.updateConstraints()
    }
    
}

class OnboardingHashtagViewController: UIViewController {
    
    // subviews
    private let collectionView = UICollectionView(frame: CGRectNull, collectionViewLayout: UICollectionViewFlowLayout())
    private let nextButtonView = HatchedButton()
    private let gradientLayer = CAGradientLayer()
    private let dotProgressView = DotProgressView()
    
    private let viewModel = OnboardingHashtagsViewModel()
    private var items: [Hashtag] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(OnboardingHashtagCell.self, forCellWithReuseIdentifier: "hashtag-cell")
        collectionView.registerClass(OnboardingHashtagHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "hashtag-header")
        
        collectionView.backgroundColor = .whiteColor()
        view.addSubview(collectionView)
        
        viewModel.results.producer.startWithNext { items in
            self.items = items
            self.collectionView.reloadData()
        }
        
        gradientLayer.colors = [UIColor(white: 1, alpha: 0).CGColor, UIColor(white: 1, alpha: 0.98).CGColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0.45)
        view.layer.addSublayer(gradientLayer)
        
        viewModel.nextHidden.producer.startWithNext { hidden in
            let height: CGFloat = hidden ? 90 : 240
            self.gradientLayer.frame = CGRect(x: 0, y: self.view.frame.height - height, width: self.view.frame.width, height: height)
            self.collectionView.setNeedsLayout()
        }
        
        nextButtonView.setTitle("GO TO FEED", forState: .Normal)
        nextButtonView.rac_hidden <~ viewModel.nextHidden
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showFeed"))
        view.addSubview(nextButtonView)
        
        dotProgressView.numberOfDots = 3
        dotProgressView.activeIndex = 2
        view.addSubview(dotProgressView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        collectionView.autoPinEdgesToSuperviewEdges()
        
        nextButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        nextButtonView.autoPinEdge(.Bottom, toEdge: .Top, ofView: dotProgressView, withOffset: -20)
        nextButtonView.autoSetDimension(.Height, toSize: 50)
        nextButtonView.autoSetDimension(.Width, toSize: 230)
        
        dotProgressView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        dotProgressView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -30)
        dotProgressView.autoSetDimension(.Height, toSize: 6)
        dotProgressView.autoSetDimension(.Width, toSize: 230)
        
        super.updateViewConstraints()
    }
    
    func showFeed() {
        presentViewController(TabBarViewController(), animated: false, completion: nil)
    }
    
}

extension OnboardingHashtagViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width - 10, height: 80)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let bottom: CGFloat = viewModel.nextHidden.value ? 60 : 160
        return UIEdgeInsets(top: 0, left: 5, bottom: bottom, right: 5)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: view.frame.width / 2 - 5, height: view.frame.width / 2 - 5)
    }
    
}

extension OnboardingHashtagViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("hashtag-cell", forIndexPath: indexPath) as! OnboardingHashtagCell
        cell.setHashtag(items[indexPath.row])
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "hashtag-header", forIndexPath: indexPath) as! OnboardingHashtagHeaderView
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        viewModel.results.value[indexPath.row].isFollowed = !viewModel.results.value[indexPath.row].isFollowed
    }
    
}