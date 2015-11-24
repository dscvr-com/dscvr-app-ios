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

protocol NewCommentTableViewDelegate: class {
    func newCommentAdded(comment: Comment)
}

class NewCommentTableViewCell: UITableViewCell {
    
    private var viewModel: NewCommentViewModel!
    
    weak var delegate: NewCommentTableViewDelegate?
    weak var navigationController: NavigationController?
    
    // subviews
    private let textInputView = LineTextField()
    private let commentsIconView = UILabel()
    private let commentsCountView = UILabel()
    private let sendButtonView = UIButton()
    private var sendButtonConstraint = NSLayoutConstraint()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        textInputView.size = .Small
        textInputView.color = .Light
        textInputView.placeholder = "Write a comment"
        textInputView.delegate = self
        textInputView.returnKeyType = .Send
        contentView.addSubview(textInputView)
        
        commentsIconView.font = UIFont.iconOfSize(17)
        commentsIconView.text = String.iconWithName(.Comment)
        commentsIconView.textColor = .whiteColor()
        contentView.addSubview(commentsIconView)
        
        commentsCountView.font = UIFont.textOfSize(13, withType: .Regular)
        commentsCountView.textColor = .whiteColor()
        contentView.addSubview(commentsCountView)
        
        sendButtonView.titleLabel?.font = UIFont.iconOfSize(24)
        sendButtonView.contentHorizontalAlignment = .Right
        sendButtonView.setTitle(String.iconWithName(.Send), forState: .Normal)
        sendButtonView.setTitleColor(.Accent, forState: .Normal)
        sendButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "postComment"))
        contentView.addSubview(sendButtonView)
        
        contentView.setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        commentsIconView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 13)
        commentsIconView.autoPinEdge(.Right, toEdge: .Left, ofView: commentsCountView, withOffset: -8)
        
        commentsCountView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 14)
        commentsCountView.autoPinEdge(.Right, toEdge: .Left, ofView: contentView, withOffset: 60)
        
        textInputView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 11)
        textInputView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 80)
        sendButtonConstraint = textInputView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        
        sendButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 8)
        sendButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        
        super.updateConstraints()
    }
    
    func bindViewModel(optographID: UUID, commentsCount: Int) {
        viewModel = NewCommentViewModel(optographID: optographID, commentsCount: commentsCount)
        
        textInputView.rac_text <~ viewModel.text
        textInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.text.value = $0 as! String }
        textInputView.rac_userInteractionEnabled <~ viewModel.isPosting.producer.map(negate)
        textInputView.rac_alpha <~ viewModel.isPosting.producer.map { $0 ? 0.5 : 1 }
        
        commentsCountView.rac_text <~ viewModel.commentsCount.producer.map { "\($0)" }
        
        sendButtonView.rac_hidden <~ viewModel.postingEnabled.producer.map(negate)
        viewModel.postingEnabled.producer.startWithNext { self.sendButtonConstraint.constant = $0 ? -60 : -20 }
    }
    
    func postComment() {
        viewModel.postComment()
            .on(
                next: self.delegate?.newCommentAdded,
                completed: {
                    self.contentView.endEditing(true)
                }
            )
            .start()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}

// MARK: - UITextFieldDelegate
extension NewCommentTableViewCell: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if !SessionService.isLoggedIn {
            let alert = UIAlertController(title: "Please login first", message: "In order to write a comment you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Sign in", style: .Cancel, handler: { [weak self] _ in
                self?.navigationController?.presentViewController(LoginViewController(), animated: false, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Later", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            return false
        }
        
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        endEditing(true)
        postComment()
        return true
    }
    
}