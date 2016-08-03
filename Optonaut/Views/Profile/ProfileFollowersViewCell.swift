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
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        tableView.frame = CGRect(origin: CGPointZero, size: frame.size)
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.registerClass(PlaceholderTableViewCell.self, forCellReuseIdentifier: "placeholder-cell")
        tableView.registerClass(FollowersTableViewCell.self, forCellReuseIdentifier: "userFollowers");
        contentView.addSubview(tableView)
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
        if data.isEmpty {
            return contentView.frame.height
        } else {
            return 75
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.isEmpty ? 1 : data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if data.isEmpty {
            let cell = tableView.dequeueReusableCellWithIdentifier("placeholder-cell") as! PlaceholderTableViewCell
            cell.textView.text = "You have no followers yet."
            //cell.iconView.text = String.iconWithName(.Inbox)
            cell.iconView.textColor = .LightGrey
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("userFollowers") as! FollowersTableViewCell
            
            let datas = data[indexPath.item]
            cell.nameLabel.text = datas.userName
            let imageUrl = ImageURL("persons/\(datas.ID)/\(datas.avatarAssetID).jpg", width: 47, height: 47)
            cell.userImage.kf_setImageWithURL(NSURL(string:imageUrl)!)
            cell.bind(datas.ID)
            
            return cell;
        }
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let datas = data[indexPath.item]
        
        let profilepage = ProfileCollectionViewController(personID: datas.ID)
        profilepage.isProfileVisit = true
        navigationController?.pushViewController(profilepage, animated: true)
    }
    func reloadTable() {
        tableView.reloadData()
    }
    
}
