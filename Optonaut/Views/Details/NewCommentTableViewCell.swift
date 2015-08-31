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
    
    var viewModel: NewCommentViewModel!
    
    var postCallback: (Comment -> ())?
    
    // subviews
    let textInputView = KMPlaceholderTextView()
    let sendButtonView = UIButton()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textInputView.font = UIFont.robotoOfSize(13, withType: .Light)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.placeholder = "Write a comment"
        contentView.addSubview(textInputView)
        
        sendButtonView.setTitle("Send", forState: .Normal)
        sendButtonView.setTitleColor(BaseColor, forState: .Normal)
        sendButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Medium)
        sendButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.postComment()
                .start(
                    next: self.postCallback,
                    completed: {
                        self.contentView.endEditing(true)
                    }
                )
            return RACSignal.empty()
        })
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
        textInputView.rac_textSignal().toSignalProducer().start(next: { self.viewModel.text.value = $0 as! String })
        
        sendButtonView.rac_userInteractionEnabled <~ viewModel.isValid
        sendButtonView.rac_alpha <~ viewModel.isValid.producer.map { $0 ? 1 : 0.5 }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}