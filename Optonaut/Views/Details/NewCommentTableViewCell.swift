//
//  NewCommentTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import KMPlaceholderTextView

class NewCommentTableViewCell: UITableViewCell {
    
    private var viewModel: NewCommentViewModel!
    
    var postCallback: (Comment -> ())?
    
    // subviews
    private let textInputView = SmallRoundedTextField()
    private let commentsIconView = UILabel()
    private let commentsCountView = UILabel()
    private let sendButtonView = UIButton()
    private var sendButtonConstraint = NSLayoutConstraint()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .blackColor()
        
        textInputView.placeholder = "Write a comment"
        textInputView.keyboardType = .Twitter
        contentView.addSubview(textInputView)
        
        commentsIconView.font = UIFont.iconOfSize(17)
        commentsIconView.text = String.iconWithName(.Comment)
        commentsIconView.textColor = .whiteColor()
        contentView.addSubview(commentsIconView)
        
        commentsCountView.font = UIFont.robotoOfSize(12, withType: .SemiBold)
        commentsCountView.textColor = .whiteColor()
        contentView.addSubview(commentsCountView)
        
        sendButtonView.titleLabel?.font = UIFont.iconOfSize(17)
        sendButtonView.contentHorizontalAlignment = .Right
        sendButtonView.setTitle(String.iconWithName(.Comment), forState: .Normal)
        sendButtonView.setTitleColor(.Accent, forState: .Normal)
        sendButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "postComment"))
        contentView.addSubview(sendButtonView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        commentsIconView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 6)
        commentsIconView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 20)
//        commentsIconView.autoSetDimension(.Width, toSize: 30)
        
        commentsCountView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 8)
        commentsCountView.autoPinEdge(.Left, toEdge: .Right, ofView: commentsIconView, withOffset: 6)
//        commentsCountView.autoSetDimension(.Width, toSize: 30)
        
        textInputView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        textInputView.autoPinEdge(.Left, toEdge: .Right, ofView: commentsCountView, withOffset: 20)
        sendButtonConstraint = textInputView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        
        sendButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 7)
        sendButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        
        super.updateConstraints()
    }
    
    func bindViewModel(optographId: UUID, commentsCount: Int) {
        viewModel = NewCommentViewModel(optographId: optographId, commentsCount: commentsCount)
        
        textInputView.rac_text <~ viewModel.text
        textInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.text.value = $0 as! String }
        textInputView.rac_userInteractionEnabled <~ viewModel.isPosting.producer.map(negate)
        textInputView.rac_alpha <~ viewModel.isPosting.producer.map { $0 ? 0.5 : 1 }
        
        commentsCountView.rac_text <~ viewModel.commentsCount.producer.map { "\($0)" }
        
        sendButtonView.rac_hidden <~ viewModel.postingEnabled.producer.map(negate)
        viewModel.postingEnabled.producer.startWithNext { self.sendButtonConstraint.constant = $0 ? -50 : -20 }
    }
    
    func postComment() {
        viewModel.postComment()
            .on(
                next: self.postCallback,
                completed: {
                    self.contentView.endEditing(true)
                }
            )
            .start()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}