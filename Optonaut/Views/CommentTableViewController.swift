//
//  CommentTableViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 6/10/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class CommentTableViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {
    
    var viewModel: DetailsViewModel!
    private var tableView = UITableView()
    private let commentField = UIView()
    private let commentTextField = TextField()
    private let postButton = UIButton()
    private let commentView = UIView()
    private let imageView = UIImageView()
    
    let dismissButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.backgroundColor = UIColor(hex:0x595959).alpha(0.70)
        view.opaque = false
        
        commentView.frame = CGRect(x: 5,y: 20,width: view.frame.width - 10,height: view.frame.height - 40)
        commentView.backgroundColor = UIColor.whiteColor()
        commentView.layer.cornerRadius = 8
        commentView.clipsToBounds = true
        view.addSubview(commentView)
        
        self.tableView.frame = CGRect(x: 5,y: 80,width: view.frame.width - 10,height: commentView.frame.height - 160)
        self.tableView.registerClass(CommentTableViewCell.self, forCellReuseIdentifier: "comment-cell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.scrollEnabled = true
        commentView.addSubview(self.tableView)
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor.whiteColor()
        commentView.addSubview(headerView)
        headerView.anchorToEdge(.Top, padding: 0, width: commentView.frame.width, height: 80)
        
        let label = UILabel()
        label.text = "Comments"
        label.font = UIFont.fontDisplay(25, withType: .Regular)
        headerView.addSubview(label)
        label.anchorToEdge(.Top, padding: 25, width: 150, height: 30)
        
        let labelLine = UILabel()
        labelLine.backgroundColor = UIColor.lightGrayColor()
        headerView.addSubview(labelLine)
        labelLine.anchorToEdge(.Bottom, padding: 0, width: commentView.frame.width, height: 1)
        
        dismissButton.setTitle("DONE",forState: .Normal)
        dismissButton.titleLabel!.font = UIFont(name: "Helvetica",size: 15)
        dismissButton.titleLabel!.textAlignment = .Left
        dismissButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
        dismissButton.addTarget(self,action: #selector(CommentTableViewController.commentPageDismiss),forControlEvents: .TouchUpInside)
        headerView.addSubview(dismissButton)
        dismissButton.anchorToEdge(.Right, padding: 15, width: 100, height: 25)
        
        commentView.addSubview(commentField)
        commentField.backgroundColor = UIColor.whiteColor()
        commentField.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 90)
        
        let labelLineComment = UILabel()
        labelLineComment.backgroundColor = UIColor.lightGrayColor()
        labelLineComment.frame = CGRect(x: 0,y: 0,width: commentView.frame.width,height: 1)
        commentField.addSubview(labelLineComment)

        postButton.setTitle("POST",forState: .Normal)
        postButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Bold",size: 16)
        postButton.titleLabel!.textAlignment = .Left
        postButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        postButton.userInteractionEnabled = false
        postButton.addTarget(self,action: #selector(CommentTableViewController.postComment),forControlEvents: .TouchUpInside)
        commentField.addSubview(postButton)
        postButton.anchorToEdge(.Right, padding: 15, width: 100, height: 30)
        
        commentTextField.backgroundColor = UIColor.lightGrayColor()
        commentTextField.delegate = self
        commentTextField.returnKeyType = .Send
        commentTextField.layer.cornerRadius = 5
        commentTextField.clipsToBounds = true
        commentTextField.becomeFirstResponder()
        commentTextField.autocorrectionType = UITextAutocorrectionType.No
        commentTextField.addTarget(self, action: #selector(CommentTableViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        commentField.addSubview(commentTextField)
        commentTextField.align(.ToTheLeftMatchingBottom, relativeTo: postButton, padding: 5 , width: view.frame.width - 100-20-15, height: 40)
        
        let attributes = [
            NSForegroundColorAttributeName: UIColor.darkGrayColor(),
            NSFontAttributeName : UIFont(name: "Helvetica", size: 14)!
        ]
        
        commentTextField.attributedPlaceholder = NSAttributedString(string: "Write a comment...", attributes:attributes)
        
        viewModel.comments.producer.startWithNext { [weak self] _ in
            
            print("comment")
            self?.tableView.reloadData()
            
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CommentTableViewController.dismissKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    func textFieldDidChange(textField: UITextField) {
        if textField.text! == "" || (textField.text?.isEmpty)! {
            postButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
            postButton.userInteractionEnabled = false
        } else {
            postButton.setTitleColor(UIColor(hex:0xFF5E00), forState: .Normal)
            postButton.userInteractionEnabled = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentTableViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentTableViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        
        commentView.frame = CGRect(x: 5,y: 20,width: view.frame.width - 10,height: view.frame.height - keyboardHeight - 40)
        tableView.frame = CGRect(x: 5,y: 80,width: view.frame.width - 10,height: view.frame.height - 160 - keyboardHeight)
        commentField.frame = CGRect(x: 0,y: view.frame.height - keyboardHeight - 80 - 40,width: view.frame.width,height: 80)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        commentView.frame = CGRect(x: 5,y: 20,width: view.frame.width - 10,height: view.frame.height - 40)
        tableView.frame = CGRect(x: 5,y: 80,width: view.frame.width - 10,height: commentView.frame.height - 160)
        commentField.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 80)
    }
    
    func commentPageDismiss() {
    
        self.dismissViewControllerAnimated(true,completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return viewModel.comments.value.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let textWidth = view.frame.width - 40 - 40 - 20 - 30 - 20
        let textHeight = calcTextHeight(viewModel.comments.value[indexPath.row].text, withWidth: textWidth, andFont:  UIFont (name: "Avenir-Heavy", size: 17)!) + 30
        return max(textHeight, 60)
    }
    

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("comment-cell") as! CommentTableViewCell
        cell.navigationController = navigationController as? NavigationController
        cell.bindViewModel(viewModel.comments.value[indexPath.row])
        return cell
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if !SessionService.isLoggedIn {
            let alert = UIAlertController(title: "Please login first", message: "In order to write a comment you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "Later", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            return false
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        postComment()
        return true
    }
    
    func newCommentAdded(comment: Comment) {
        self.viewModel.insertNewComment(comment)
    }
    
    func postComment() {
        
        if commentTextField.text != nil {
            viewModel.commentText = commentTextField.text!
        } else {
            viewModel.commentText = ""
        }
        
        viewModel.postComment()
            .on(
                next: self.newCommentAdded,
                completed: {
                    self.view.endEditing(true)
                    self.commentTextField.text = nil
                    self.postButton.userInteractionEnabled = false
                    self.postButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
                }
            )
            .start()
    }
 

}

