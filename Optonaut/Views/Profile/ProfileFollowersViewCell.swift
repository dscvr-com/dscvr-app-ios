//
//  ProfileFollowersViewCell.swift
//  Iam360
//
//  Created by robert john alkuino on 6/22/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import Kingfisher

class ProfileFollowersViewCell: UICollectionViewCell,UITableViewDataSource, UITableViewDelegate{
    
    
    var tableView = UITableView()
    var data:[Person] = []
    
    weak var navigationController: NavigationController?
    let viewNoFollowers = UIView()
    let text = UILabel()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        tableView.frame = CGRect(origin: CGPointZero, size: frame.size)
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.registerClass(FollowersTableViewCell.self, forCellReuseIdentifier: "userFollowers");
        contentView.addSubview(tableView)
        
        viewNoFollowers.frame = CGRect(origin: CGPointZero, size: frame.size)
        viewNoFollowers.backgroundColor = UIColor.whiteColor()
        contentView.addSubview(viewNoFollowers)
        
        text.text = "You have no followers!"
        text.textAlignment = .Center
        text.textColor = UIColor.grayColor()
        viewNoFollowers.addSubview(text)
        text.autoAlignAxis(.Horizontal, toSameAxisOfView: contentView, withOffset: -50)
        text.autoAlignAxisToSuperviewAxis(.Vertical)
    }
    
    func viewIsActive() {
        ApiService<PersonApiModel>.get("persons/followers")
            .on(next: { person in
                Models.persons.touch(person).insertOrUpdate()
            })
            .map(Person.fromApiModel)
            .collect()
            .startWithNext { person in
                self.data = person
                self.reloadTable()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userFollowers") as! FollowersTableViewCell
        
        let datas = data[indexPath.item]
        cell.nameLabel.text = datas.displayName
        let imageUrl = ImageURL("persons/\(datas.ID)/\(datas.avatarAssetID).jpg", width: 47, height: 47)
        cell.userImage.kf_setImageWithURL(NSURL(string:imageUrl)!)
        cell.bind(datas.ID)
        
        return cell;
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let datas = data[indexPath.item]
        
        let profilepage = ProfileCollectionViewController(personID: datas.ID)
        profilepage.isProfileVisit = true
        navigationController?.pushViewController(profilepage, animated: true)
    }
    func reloadTable() {
        tableView.reloadData()
        if data.count != 0 {
            viewNoFollowers.hidden = true
        } else {
            viewNoFollowers.hidden = false
        }
    }
    
}
