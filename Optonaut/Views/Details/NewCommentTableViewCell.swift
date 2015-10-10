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
    private let textInputView = KMPlaceholderTextView()
    private let sendButtonView = UIButton()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        textInputView.font = UIFont.robotoOfSize(13, withType: .Light)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.placeholder = "Write a comment"
        textInputView.keyboardType = .Twitter
        contentView.addSubview(textInputView)
        
        sendButtonView.setTitle("Send", forState: .Normal)
        sendButtonView.setTitleColor(UIColor.Accent, forState: .Normal)
        sendButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Medium)
        sendButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "postComment"))
        contentView.addSubview(sendButtonView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        sendButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 10)
        sendButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -9)
        
        textInputView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 10)
        textInputView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 9)
        textInputView.autoPinEdge(.Right, toEdge: .Left, ofView: sendButtonView, withOffset: -10)
        textInputView.autoSetDimension(.Height, toSize: 32)
        
        super.updateConstraints()
    }
    
    func bindViewModel(optographId: UUID) {
        viewModel = NewCommentViewModel(optographId: optographId)
        
        textInputView.rac_text <~ viewModel.text
        textInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.text.value = $0 as! String }
        
        sendButtonView.rac_userInteractionEnabled <~ viewModel.isValid.producer.combineLatestWith(viewModel.isPosting.producer).map { $0 && !$1 }
        sendButtonView.rac_alpha <~ viewModel.isValid.producer.map { $0 ? 1 : 0.5 }
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