//
//  SearchViewController.swift
//  PhotoViewGallery
//
//  Created by Thadz on 06/06/2016.
//  Copyright © 2016 Brewed Concepts. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource , TransparentNavbarWithStatusBar {
    
    lazy var searchBar:UISearchBar = UISearchBar(frame: CGRectZero);
    
    var indicator = UIActivityIndicatorView()
    
    var tableView: UITableView!
    
    var searchActive : Bool = false
    
    private let viewModel = SearchTableModel()
    
    private var person: [Person] = []
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        searchBar.placeholder = "Search Username";
        searchBar.delegate = self;
        searchBar.showsCancelButton = true;
        searchBar.autocapitalizationType = .None
        searchBar.tintColor = UIColor.blackColor();
        self.navigationItem.titleView = searchBar;
    
        tableView = UITableView(frame: self.view.frame);
        tableView.dataSource = self;
        tableView.delegate = self;
        
        tableView.registerClass(UserTableViewCell.self, forCellReuseIdentifier: "userCellIdentifier")
        self.view.addSubview(tableView)
        
        indicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 40, 40))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        indicator.center.x = self.view.center.x
        indicator.center.y = self.view.center.y - 40
        indicator.stopAnimating()
        self.view.addSubview(indicator)
        
        viewModel.results.producer
                .on(
                    next: { people in
                        if people.count > 0 {
                            if people[0].userName != "" && people[0].ID != "" {
                                self.person = people
                                self.progressLoaderStopAnimate()
                                self.tableView.reloadData()
                            }
                        }
                    }
                )
                .start()
    }
    
    func progressLoaderStopAnimate() {
        indicator.stopAnimating()
        indicator.hidesWhenStopped = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBar.barTintColor = UIColor(hex:0xFF5E00)
        self.navigationController?.navigationBar.translucent = false;
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.fontDisplay(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        updateNavbarAppear()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.characters.count > 2 {
            if !indicator.isAnimating() {
                indicator.startAnimating()
                indicator.backgroundColor = UIColor.whiteColor()
            }
        }
        
        if viewModel.searchText.value.isEmpty {
            tableView.reloadData()
        }
        viewModel.searchText.value = searchText
    }
        
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
        searchBar.endEditing(true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return person.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCellIdentifier") as! UserTableViewCell
        let personDetails = person[indexPath.row]
        
        let image = ImageURL("persons/\(personDetails.ID)/\(personDetails.avatarAssetID).jpg", width: 47, height: 47)
        
        cell.userImage.kf_setImageWithURL(NSURL(string:image)!)
        cell.nameLabel.text = personDetails.userName
        cell.nameLabel.sizeToFit()
        cell.locationLabel.text = ""
        cell.locationLabel.sizeToFit()
        
        cell.locationLabel.frame = CGRect(x: cell.nameLabel.frame.origin.x, y: cell.nameLabel.frame.origin.y + cell.nameLabel.frame.size.height, width: 0, height: 0);
        cell.locationLabel.sizeToFit()
        
        return cell;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let personDetails = person[indexPath.row]
        
        let profilepage = ProfileCollectionViewController(personID: personDetails.ID)
        profilepage.isProfileVisit = true
        navigationController?.pushViewController(profilepage, animated: true)
    }
}
