//
//  StoryDetailsTableViewController.swift
//  DSCVR
//
//  Created by Thadz on 24/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import Mixpanel
import Async
import SceneKit
import ReactiveCocoa
import Kingfisher
import SpriteKit
import SwiftyUserDefaults
import MediaPlayer
import AVKit

class StoryDetailsTableViewController: UIViewController, NoNavbar,TabControllerDelegate, CubeRenderDelegateDelegate, FPOptographsCollectionViewControllerDelegate, MPMediaPickerControllerDelegate, UITextFieldDelegate {

    private let viewModel: DetailsViewModel!
    
    private var combinedMotionManager: CombinedMotionManager!
    // subviews
    //private let tableView = TableView()
    
    private var renderDelegate: CubeRenderDelegate!
    private var scnView: SCNView!
    
    private var imageDownloadDisposable: Disposable?
    
    private var rotationAlert: UIAlertController?
    
    private enum LoadingStatus { case Nothing, Preview, Loaded }
    private let loadingStatus = MutableProperty<LoadingStatus>(.Nothing)
    let imageCache: CollectionImageCache
    
    var optographID:UUID = ""
    var cellIndexpath:Int = 0
    
    var mapChild: StorytellingChildren?
    var storyTellingData: mapChildren?
    
    var direction: Direction {
        set(direction) {
            combinedMotionManager.setDirection(direction)
        }
        get {
            return combinedMotionManager.getDirection()
        }
    }
    
    private var touchStart: CGPoint?
    private let whiteBackground = UIView()
    private let avatarImageView = UIImageView()
    private let locationTextView = UILabel()
    private let likeCountView = UILabel()
    private let personNameView = BoundingLabel()
    private let optionsButtonView = BoundingButton()
    private let likeButtonView = BoundingButton()
    
    private let commentButtonView = BoundingButton()
    private let commentCountView = UILabel()
    
    private let hideSelectorButton = UIButton()
    private let littlePlanetButton = UIButton()
    private let gyroButton = UIButton()
    private var isSelectorButtonOpen:Bool = true
    private var isUIHide:Bool = false
    
    var isMe = false
    var labelShown = false
    var transformBegin:CGAffineTransform?
    let deleteButton = UIButton()
    var gyroImageActive = UIImage(named: "details_gyro_active")
    var gyroImageInactive = UIImage(named: "details_gyro_inactive")
    var backButton = UIImage(named: "back_yellow_icn")
    var shareButton = UIButton()
    
    let textButtonContainer = UIView()
    let textButton = UIButton()
    
    let imageButtonContainer = UIView()
    let imageButton = UIButton()
    
    let audioButtonContainer = UIView()
    let audioButton = UIButton()
    
    let markerNameLabel = UILabel()
    
    var sphereColor = UIColor()
    
    var attachmentToggled:Bool = false
    
    var nodeItem = StorytellingObject()
    var nodes = [NSDictionary]()
    var mediaArray = [NSDictionary]()
    
    var playerItem:AVPlayerItem?
    var player:AVPlayer?
    
    var isStorytelling:Bool = false
    var isTextPin:Bool = false
    
    let textFieldContainer = UIView()
    let inputTextField = UITextField()
    let fixedTextLabel = UILabel()
    let clearTextLabel = UIButton()
    let bgmImage = UIButton()
    let removeBgm = UIButton()
    
    required init(optographId:UUID) {
        
        optographID = optographId
        
        viewModel = DetailsViewModel(optographID: optographId)
        let textureSize = getTextureWidth(UIScreen.mainScreen().bounds.width, hfov: HorizontalFieldOfView)
        imageCache = CollectionImageCache(textureSize: textureSize)
        
        logInit()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
//    func receiveStory (){
//        ApiService<StoryObject>.getForGate("story/62f1c6cb-cb90-4ade-810d-c6c1bbeee85a", queries: ["story_person_id": "7753e6e9-23c6-46ec-9942-35a5ea744ece"]).on(next: {
//            story in
//            
//            self.storyTellingData = story.children;
//            self.mapChild = self.storyTellingData!.children![0];
//            
//            //            let cubeImageCache = self.imageCache.getOptocache(self.cellIndexpath, optographID: self.mapChild!.story_object_media_additional_data, side: .Left)
//            //            self.setCubeImageCache(cubeImageCache)
//            
//            let nodeTranslation = SCNVector3Make(Float(self.mapChild!.story_object_position[0])!, Float(self.mapChild!.story_object_position[1])!, Float(self.mapChild!.story_object_position[2])!)
//            
//            let nodeRotation = SCNVector3Make(Float(self.mapChild!.story_object_rotation[0])!, Float(self.mapChild!.story_object_rotation[1])!, Float(self.mapChild!.story_object_rotation[2])!)
//
//            print("node translation: \(nodeTranslation.x)");
//            print("node rotation: \(nodeRotation.x)");
//            
//            self.renderDelegate.addNodeFromServer(nodeTranslation, rotation: nodeRotation)
//            
//            //            for data in story.children!{
//            //                for child in data.children!{
//            //                    print("child id: \(child.story_object_story_id)");
//            //                }
//            //            }
//        }).start();
//    }
    
    func sendOptographData(){
        if fixedTextLabel.text != ""{
            let child : NSDictionary = ["story_object_media_type": "FXTXT",
                                        "story_object_media_face": "no pin",
                                        "story_object_media_description": "fixed text",
                                        "story_object_media_additional_data": fixedTextLabel.text!,
                                        "story_object_position": [0, 0, 0],
                                        "story_object_rotation": [0, 0, 0]]
            
            print("text child: \(child)")
            nodes.append(child);
        }
        
        let parameters : NSDictionary =  ["story_optograph_id": optographID,
                                          "story_person_id": SessionService.personID,
                                          "children":nodes]
        
        print("nodes: \(nodes)")
        
        if nodes.count > 0{
            print("pass data")
            ApiService<StorytellingResponse>.postForGate("story", parameters: parameters as? [String : AnyObject]).on(next: { data in
                print("data story id: \(data)");
                print("user: \(SessionService.personID)")
                
                self.dismissStorytelling()
            }).start();
        }
        else{
            print("nodes count is zero")
        }
        
        
    }
    
    func sendToNewPath(){
        let parameters : NSDictionary =  ["story_optograph_id": optographID,
                                          "story_person_id": SessionService.personID,
                                          "children":nodes]
        
        if nodes.count > 0{
            print("pass data")
            ApiService<ChildResponse>.postForGate("story/v2/part1", parameters: parameters as? [String : AnyObject]).on(next: { data in
                print("data story id: \(data)")
                print("user: \(SessionService.personID)")
                
                let response = StoryMediaObject()
                response.mediaArray = (data.data?.children)!
                response.story_id = (data.data?.story_id)!
                
                print("mediaArray: \(response.mediaArray)")
                print("story_id: \(response.story_id)")
                
                self.sendMultiformData(response)
                
//                self.dismissStorytelling()
            }).start();
        }
        else{
            print("nodes count is zero")
        }
    }
    
    func sendMultiformData(mediaData: StoryMediaObject){
        
        var multiformDictionary = [String : AnyObject]()
        multiformDictionary["story_id"] = mediaData.story_id
        multiformDictionary["story_person_id"] = SessionService.personID
//        multiformDictionary.setValue(mediaData.story_id, forKey: "story_id")
//        multiformDictionary.setValue(SessionService.personID, forKey: "story_person_id")
        
        var counter = 0
        var mediaIDcsv = String()
        for media in mediaData.mediaArray {
            counter += 1
            
            if counter < mediaData.mediaArray.count{
                mediaIDcsv = mediaIDcsv + media.story_object_id + ","
            }
            else{
                mediaIDcsv = mediaIDcsv + media.story_object_id
            }
            
        }
        
        for media in mediaData.mediaArray{
            for fileInfo in mediaArray{
                if media.story_object_media_filename == fileInfo["mediaFilename"] as! String{
                    multiformDictionary[media.story_object_id] = fileInfo["mediaData"]
//                    multiformDictionary.setValue(fileInfo["mediaData"], forKey: media.story_object_id)
                    ApiService<EmptyResponse>.uploadForGate("story/v2/part2", multipartFormData: { form in
                        form.appendBodyPart(data: mediaData.story_id.dataUsingEncoding(NSUTF8StringEncoding)!, name: "story_id")
                        form.appendBodyPart(data: SessionService.personID.dataUsingEncoding(NSUTF8StringEncoding)!, name: "story_person_id")
                        form.appendBodyPart(data: media.story_object_id.dataUsingEncoding(NSUTF8StringEncoding)!, name: "story_object_ids")
                        form.appendBodyPart(data: fileInfo["mediaData"] as! NSData, name: "asset", fileName: fileInfo["mediaFilename"] as! String, mimeType: "audio/mp4")
                        
                    })
                }
            }
        }
        
        
        
        multiformDictionary["story_object_ids"] = mediaIDcsv
//        print("multiformDictionary: \(multiformDictionary)")
        
        ApiService<ChildResponse>.postForGate("story/v2/part2", parameters: multiformDictionary).on(next: { data in
            print("data story id: \(data)")
//            print("user: \(SessionService.personID)")
//            
//            let response = StoryMediaObject()
//            response.mediaArray = (data.data?.children)!
//            response.story_id = (data.data?.story_id)!
//            
//            print("mediaArray: \(response.mediaArray)")
//            print("story_id: \(response.story_id)")
//            
//            self.sendMultiformData(response)
            
            self.dismissStorytelling()
        }).start();
        
        
//        ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset\(uploadModeStr)", multipartFormData: { form in
//            form.appendBodyPart(data: "placeholder".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
//            form.appendBodyPart(data: UIImageJPEGRepresentation(image, 1)!, name: "asset", fileName: "placeholder.jpg", mimeType: "image/jpeg")
//        })
    }
    
    func optographSelected(optographID: String) {
        nodeItem.optographID = optographID;
        
        print("node x: \(nodeItem.objectVector3.x)");
        print("node z: \(nodeItem.objectRotation.z)");
        print("node id: \(nodeItem.optographID)");
        print("node type: \(nodeItem.objectType)");
        
        let translationArray = [nodeItem.objectVector3.x, nodeItem.objectVector3.y, nodeItem.objectVector3.z]
        
        let rotationArray = [nodeItem.objectRotation.x, nodeItem.objectRotation.y, nodeItem.objectRotation.z]
        
        let child : NSDictionary = ["story_object_media_type": nodeItem.objectType,
                                    "story_object_media_face": "pin",
                                    "story_object_media_description": "next optograph",
                                    "story_object_media_additional_data": nodeItem.optographID,
                                    "story_object_position": translationArray,
                                    "story_object_rotation": rotationArray]
        
        nodes.append(child);
        
        let audioFilePath = NSBundle.mainBundle().pathForResource("pop", ofType: "mp3")
        
        player = AVPlayer(URL: NSURL(fileURLWithPath: audioFilePath!))
        player?.rate = 1.0
        player?.volume = 1.0
        player!.play()
        
        print("nodes count: \(nodes.count)")
    }
    
    func addVectorAndRotation(vector: SCNVector3, rotation: SCNVector3){
        print("addVectorAndRotation");
        
        nodeItem.objectVector3 = vector;
        nodeItem.objectRotation = rotation;
        
    }
    
    func isInButtonCamera(inFrustrum: Bool){
        
    }
    
    func didEnterFrustrum(nodeObject: StorytellingObject, inFrustrum: Bool) {
        //        markerNameLabel.hidden = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            dispatch_async(dispatch_get_main_queue()){
                if inFrustrum {
//                    self.markerNameLabel.text = markerName
//                    self.markerNameLabel.sizeToFit()
//                    self.markerNameLabel.center = CGPoint(x: self.view.center.x, y: 70.0)
//                    
//                    self.markerNameLabel.hidden = false
//                    print("markerName: \(self.markerNameLabel.text!)")
                    
                    
                    //                    if (self.markerNameLabel.text! == "Text Item2") {
                    //                        print("resetToBlack")
                    //
                    //                        let cubeImageCache = self.imageCache.getOptocache(self.cellIndexpath, optographID: "8e8fcab1-761e-4ef8-a969-0c1346b39bf3", side: .Left)
                    //                        self.setCubeImageCache(cubeImageCache)
                    //                    }
                    
                    //                    let cubeImageCache = self.imageCache.getOptocache(self.cellIndexpath, optographID: (self.mapChild?.story_object_media_additional_data)!, side: .Left)
                    //                    self.setCubeImageCache(cubeImageCache)
                    
                    //if type is audio
                    /*
                     let url = NSURL(string: "http://jumpserver.mine.nu/albatroz.mp3")
                     playerItem = AVPlayerItem(URL: url!)
                     player=AVPlayer(playerItem: playerItem!)
                     player?.rate = 1.0
                     player?.volume = 1.0
                     player!.play()
                     */
                    
                }
                else{
                    self.markerNameLabel.hidden = true
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let mediaData = StoryMediaObject()
//        self.sendMultiformData(mediaData)
        
        view.backgroundColor = .blackColor()
        
        navigationItem.title = ""
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: self.view.frame, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: self.view.frame)
        }
        
        let hfov: Float = 40
        combinedMotionManager = CombinedMotionManager(sceneSize: scnView.frame.size, hfov: hfov)
        renderDelegate = CubeRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: Double(hfov), cubeFaceCount: 2, autoDispose: true)
        renderDelegate.scnView = scnView
        renderDelegate.delegate = self
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clearColor()
        scnView.hidden = false
        self.view.addSubview(scnView)
        
        self.willDisplay()
        
        ///addd flags to control adding texture
        let cubeImageCache = imageCache.get(cellIndexpath, optographID: optographID, side: .Left)
        self.setCubeImageCache(cubeImageCache)
        ///addd flags to control adding texture
        
        print("optoID: \(optographID)")
        print("indexPath: \(cellIndexpath)")
        
        //// add flag in viewdidload/add to didenterfrustrum
//                let url = NSURL(string: "http://jumpserver.mine.nu/albatroz.mp3")
//                playerItem = AVPlayerItem(URL: url!)
//                player=AVPlayer(playerItem: playerItem!)
//                player?.rate = 1.0
//                player?.volume = 1.0
//                player!.play()
        
        //// add flag in viewdidload/add to didenterfrustrum
        
        //        ApiService<StoryObject>.getForGate("story/248761f4-9a83-4cf3-b2a4-f986fee02ee4", queries: ["story_person_id": "7753e6e9-23c6-46ec-9942-35a5ea744ece"]).on(next: {
        //            story in
        //            print("story object id: \(story.data)");
        //        }).start();
        
        ///add flags to check if editing optograph
        /**/
        
        if isStorytelling{
            //            self.prepareStoryTellingHUD();
            self.prepareNewHUD();
        }
        else{
            self.prepareDetailsHUD();
        }
    }
    
    private func pushViewer(orientation: UIInterfaceOrientation) {
        
        //        let viewerViewController = ViewerViewController(orientation: orientation, optograph: Models.optographs[optographID]!.model)
        //        navigationController?.pushViewController(viewerViewController, animated: false)
        //        //        viewModel.increaseViewsCount()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        print("STORY DETAILS VIEW CONTROLLER")
        
        Mixpanel.sharedInstance().timeEvent("View.OptographDetails")
        
        if !isStorytelling{
            tabController!.delegate = self
        }
        
        //viewModel.viewIsActive.value = true
        if let rotationSignal = RotationService.sharedInstance.rotationSignal {
            rotationSignal
                .skipRepeats()
                .filter([.LandscapeLeft, .LandscapeRight])
                //               .takeWhile { [weak self] _ in self?.viewModel.viewIsActive.value ?? false }
                .take(1)
                .observeOn(UIScheduler())
                .observeNext { [weak self] orientation in self?.pushViewer(orientation) }
        }
        
        
        
        //        viewModel.optographReloaded.producer.startWithNext { [weak self] in
        //            if self?.viewModel.optograph.deletedAt != nil {
        //                self?.navigationController?.popViewControllerAnimated(false)
        //            }
        //        }
        
        
    }
    
    func prepareDetailsHUD(){
        whiteBackground.backgroundColor = UIColor.blackColor().alpha(0.60)
        self.view.addSubview(whiteBackground)
        
        avatarImageView.layer.cornerRadius = 23.5
        avatarImageView.layer.borderColor = UIColor(hex:0xffbc00).CGColor
        avatarImageView.layer.borderWidth = 2.0
        avatarImageView.backgroundColor = .whiteColor()
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pushProfile)))
        avatarImageView.kf_setImageWithURL(NSURL(string: ImageURL(viewModel.avatarImageUrl.value, width: 47, height: 47))!)
        whiteBackground.addSubview(avatarImageView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(21)
        optionsButtonView.setImage(UIImage(named:"follow_active"), forState: .Normal)
        optionsButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.followUser)))
        whiteBackground.addSubview(optionsButtonView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = UIColor(0xffbc00)
        personNameView.userInteractionEnabled = true
        personNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.pushProfile)))
        whiteBackground.addSubview(personNameView)
        
        likeButtonView.addTarget(self, action: #selector(self.toggleStar), forControlEvents: [.TouchDown])
        whiteBackground.addSubview(likeButtonView)
        
        
        commentButtonView.setImage(UIImage(named:"comment_icn"), forState: .Normal)
        commentButtonView.addTarget(self, action: #selector(self.toggleComment), forControlEvents: [.TouchDown])
        whiteBackground.addSubview(commentButtonView)
        
        commentCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        commentCountView.textColor = .whiteColor()
        commentCountView.textAlignment = .Right
        whiteBackground.addSubview(commentCountView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = UIColor.whiteColor()
        whiteBackground.addSubview(locationTextView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        likeCountView.textAlignment = .Right
        whiteBackground.addSubview(likeCountView)
        
        whiteBackground.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 66)
        avatarImageView.anchorToEdge(.Left, padding: 20, width: 47, height: 47)
        personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
        likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 21, width: 24, height: 28)
        
        likeCountView.align(.ToTheLeftCentered, relativeTo: likeButtonView, padding: 10, width:20, height: 13)
        /**/
        ///add flags to check if editing optograph
        
        //commentButtonView.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 10, width:24, height: 28)
        //commentCountView.align(.ToTheLeftCentered, relativeTo: commentButtonView, padding: 10, width:20, height: 13)
        
        let followSizeWidth = UIImage(named:"follow_active")!.size.width
        let followSizeHeight = UIImage(named:"follow_active")!.size.height
        
        optionsButtonView.frame = CGRect(x: avatarImageView.frame.origin.x + 2 - (followSizeWidth / 2),y: avatarImageView.frame.origin.y + (avatarImageView.frame.height * 0.75) - (followSizeWidth / 2),width: followSizeWidth,height: followSizeHeight)
        
        personNameView.rac_text <~ viewModel.creator_username
        likeCountView.rac_text <~ viewModel.starsCount.producer.map { "\($0)" }
        //commentCountView.rac_text <~ viewModel.commentsCount.producer.map{ "\($0)" }
        
        viewModel.isStarred.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
                strongSelf.likeButtonView.setImage(liked ? UIImage(named:"liked_button") : UIImage(named:"user_unlike_icn"), forState: .Normal)
            }
        }
        
        let optograph = Models.optographs[optographID]!.model
        
        if let locationID = optograph.locationID {
            let location = Models.locations[locationID]!.model
            locationTextView.text = "\(location.text), \(location.countryShort)"
            self.personNameView.align(.ToTheRightMatchingTop, relativeTo: self.avatarImageView, padding: 15, width: 100, height: 18)
            self.locationTextView.align(.ToTheRightMatchingBottom, relativeTo: self.avatarImageView, padding: 15, width: 100, height: 18)
            locationTextView.text = location.text
        } else {
            personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
            locationTextView.text = ""
        }
        
        
        //hideSelectorButton.setBackgroundImage(UIImage(named:"oval_up"), forState: .Normal)
        //self.view.addSubview(hideSelectorButton)
        
        //self.view.addSubview(littlePlanetButton)
        //self.view.addSubview(gyroButton)
        
        
        //        hideSelectorButton.anchorInCorner(.TopRight, xPad: 10, yPad: 70, width: 40, height: 40)
        //        hideSelectorButton.addTarget(self, action: #selector(self.selectorButton), forControlEvents:.TouchUpInside)
        //
        //        littlePlanetButton.align(.UnderCentered, relativeTo: hideSelectorButton, padding: 10, width: 35, height: 35)
        //        littlePlanetButton.addTarget(self, action: #selector(self.littlePlanetButtonTouched), forControlEvents:.TouchUpInside)
        
        //        gyroButton.align(.UnderCentered, relativeTo: littlePlanetButton, padding: 10, width: 35, height: 35)
        
        //        gyroButton.anchorInCorner(.TopRight, xPad: 20, yPad: 30, width: 40, height: 40)
        //        gyroButton.userInteractionEnabled = true
        //        gyroButton.addTarget(self, action: #selector(self.gyroButtonTouched), forControlEvents:.TouchUpInside)
        
        gyroImageActive = gyroImageActive?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        gyroImageInactive = gyroImageInactive?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        backButton = backButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backButton, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(closeDetailsPage))
        
        if  Defaults[.SessionGyro] {
            self.changeButtonIcon(true)
        } else {
            self.changeButtonIcon(false)
        }
        
        let oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.oneTap(_:)))
        oneTapGestureRecognizer.numberOfTapsRequired = 1
        self.scnView.addGestureRecognizer(oneTapGestureRecognizer)
        
        //        let twoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.twoTap(_:)))
        //        twoTapGestureRecognizer.numberOfTapsRequired = 2
        //        self.view.addGestureRecognizer(twoTapGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(_:)))
        
        scnView.addGestureRecognizer(pinchGestureRecognizer)
        
        
        isMe = viewModel.isMe
        
        if isMe {
            optionsButtonView.hidden = true
        } else {
            optionsButtonView.hidden = false
            viewModel.isFollowed.producer.startWithNext{
                $0 ? self.optionsButtonView.setImage(UIImage(named:"follow_active"), forState: .Normal) : self.optionsButtonView.setImage(UIImage(named:"follow_inactive"), forState: .Normal)
            }
        }
        if isMe {
            deleteButton.setBackgroundImage(UIImage(named: "profile_delete_icn"), forState: .Normal)
            deleteButton.addTarget(self, action: #selector(deleteOpto), forControlEvents: .TouchUpInside)
            whiteBackground.addSubview(deleteButton)
            
            let deleteImageSize = UIImage(named:"profile_delete_icn")?.size
            deleteButton.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 10, width:(deleteImageSize?.width)!, height: (deleteImageSize?.height)!)
            
            shareButton.setBackgroundImage(UIImage(named: "share_white_details"), forState: .Normal)
            shareButton.addTarget(self, action: #selector(share), forControlEvents: .TouchUpInside)
            whiteBackground.addSubview(shareButton)
            
            let shareImageSize = UIImage(named:"share_white_details")?.size
            shareButton.align(.ToTheLeftCentered, relativeTo: deleteButton, padding: 20, width:(shareImageSize?.width)!, height: (shareImageSize?.height)!)
        } else {
            shareButton.setBackgroundImage(UIImage(named: "share_white_details"), forState: .Normal)
            shareButton.addTarget(self, action: #selector(share), forControlEvents: .TouchUpInside)
            whiteBackground.addSubview(shareButton)
            
            let shareImageSize = UIImage(named:"share_white_details")?.size
            shareButton.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 10, width:(shareImageSize?.width)!, height: (shareImageSize?.height)!)
        }
    }
    
    func prepareNewHUD(){
        //        let textPinImage = UIImage(named: "")
        //        let textPin = UIButton(frame: CGRect(x: 0, y: 0, width: (textPinImage?.size.width)!, height: (textPinImage?.size.height)!))
        
        //        let optoPinImage = UIImage(named: "")
        //        let optoPin = UIButton(frame: CGRect(x: 0, y: 0, width: (optoPinImage?.size.width)!, height: (optoPinImage?.size.height)!))
        
        //        let audioPinImage = UIImage(named: "")
        //        let audioPin = UIButton(frame: CGRect(x: 0, y: 0, width: (audioPinImage?.size.width)!, height: (audioPinImage?.size.height)!))
        
        let audioPin = UIButton(frame: CGRect(x: 10.0, y: self.view.frame.size.height - 50.0, width: 40.0, height: 40.0))
//        audioPin.backgroundColor = UIColor.redColor()
        audioPin.addTarget(self, action: #selector(audioButtonDown), forControlEvents: .TouchUpInside)
        audioPin.setImage(UIImage(named: "add_music_icn"), forState: UIControlState.Normal)
        
        let fixedText = UIButton(frame: CGRect(x: audioPin.frame.origin.x + audioPin.frame.size.width + 10.0, y: audioPin.frame.origin.y, width: 40.0, height: 40.0))
        fixedText.setImage(UIImage(named: "add_text_round"), forState: UIControlState.Normal)
        fixedText.addTarget(self, action: #selector(fixedTextDown), forControlEvents: .TouchUpInside)
        
        let optoPin = UIButton(frame: CGRect(x: self.view.frame.size.width - 50.0, y: audioPin.frame.origin.y, width: 40.0, height: 40.0))
//        optoPin.backgroundColor = UIColor.blueColor()
        optoPin.addTarget(self, action: #selector(imageButtonDown), forControlEvents: .TouchUpInside)
        optoPin.setImage(UIImage(named: "add_scene_icn"), forState: UIControlState.Normal)
        
        let textPin = UIButton(frame: CGRect(x: optoPin.frame.origin.x - 50.0, y: audioPin.frame.origin.y, width: 40.0, height: 40.0))
//        textPin.backgroundColor = UIColor.greenColor()
        textPin.addTarget(self, action: #selector(textButtonDown), forControlEvents: .TouchUpInside)
        textPin.setImage(UIImage(named: "add_text_icn"), forState: UIControlState.Normal)
        
        let doneButton = UIButton(frame: CGRect(x: 0, y: 0, width: 87.0, height: 87.0))
        doneButton.layer.cornerRadius = doneButton.bounds.size.width/2.0
        doneButton.center = CGPointMake(self.view.center.x, self.view.frame.height - doneButton.frame.size.height/2 - 10.0)
        doneButton.backgroundColor = UIColor.orangeColor()
        doneButton.addTarget(self, action: #selector(doneStorytelling), forControlEvents: .TouchUpInside)
        doneButton.setImage(UIImage(named: "done_check_icn"), forState: UIControlState.Normal)
        
        let dismissButton = UIButton(frame: CGRect(x: 0, y: 0.0, width: 40.0, height: 40.0))
//        dismissButton.backgroundColor = UIColor.whiteColor()
        dismissButton.addTarget(self, action: #selector(dismissStorytelling), forControlEvents: .TouchUpInside)
        dismissButton.setImage(UIImage(named: "close_icn-1"), forState: UIControlState.Normal)
        
        clearTextLabel.setImage(UIImage(named: "close_icn"), forState: UIControlState.Normal)
        clearTextLabel.addTarget(self, action: #selector(removeFixedText), forControlEvents: .TouchUpInside)
        
        textFieldContainer.frame = CGRect(x: 0, y: self.view.frame.size.height, width: self.view.frame.size.width, height: 50.0)
        textFieldContainer.backgroundColor = UIColor.blackColor().alpha(0.3)
        inputTextField.frame = CGRect(x: 5.0, y: 5.0, width: self.view.frame.size.width - 10.0, height: 40.0)
        inputTextField.returnKeyType = UIReturnKeyType.Done
        inputTextField.textColor = UIColor.whiteColor()
        inputTextField.delegate = self
        textFieldContainer.addSubview(inputTextField)
        
        let rightBarButton = UIBarButtonItem(customView: dismissButton)
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        //let fixedTextLabel = UILabel()
//        let clearTextLabel = UIButton()
        
        fixedTextLabel.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        fixedTextLabel.text = ""
        fixedTextLabel.textColor = UIColor.whiteColor()
        fixedTextLabel.font = UIFont(name: "Avenir-Heavy", size: 22.0)
        fixedTextLabel.sizeToFit()
        fixedTextLabel.center = CGPoint(x: self.view.center.x, y: self.view.frame.height - 200)
        
        let noteImage = UIImage(named: "note_icn")
        bgmImage.setImage(noteImage, forState: UIControlState.Normal)
        bgmImage.addTarget(self, action: #selector(removeBGM), forControlEvents: .TouchUpInside)
        bgmImage.frame = CGRect(x: 0, y: 0, width: (noteImage?.size.width)!, height: (noteImage?.size.height)!)
        bgmImage.center = CGPointMake(20.0 + (noteImage?.size.width)!/2, self.view.frame.height - 200)
        bgmImage.hidden = true
        
        removeBgm.setImage(UIImage(named: "close_icn"), forState: UIControlState.Normal)
        removeBgm.addTarget(self, action: #selector(removeBGM), forControlEvents: .TouchUpInside)
        removeBgm.frame = CGRect(x: bgmImage.frame.origin.x + bgmImage.frame.size.width + 5.0,
                                      y: bgmImage.frame.origin.y - 10.0,
                                      width: 30.0, height: 30.0)
        removeBgm.hidden = true
        
        self.view.addSubview(audioPin)
        self.view.addSubview(fixedText)
        self.view.addSubview(optoPin)
        self.view.addSubview(textPin)
        self.view.addSubview(doneButton)
        self.view.addSubview(textFieldContainer)
        self.view.addSubview(fixedTextLabel)
        self.view.addSubview(clearTextLabel)
        self.view.addSubview(bgmImage)
//        self.view.addSubview(removeBgm)
    }

    
    func prepareStoryTellingHUD(){
        let targetOverlay = UIView(frame: CGRect(x: 0, y: self.view.frame.size.height - 225, width: self.view.frame.size.width, height: 125))
        targetOverlay.backgroundColor = UIColor.blackColor().alpha(0.6)
        
        let pinImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        pinImage.backgroundColor = UIColor(hex:0xffd24e)
        
        let targetLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        targetLabel.text = "PLACE TARGET"
        targetLabel.font = UIFont(name: "Avenir-Heavy", size: 22.0)
        targetLabel.textColor = UIColor.whiteColor()
        targetLabel.sizeToFit()
        targetLabel.center = CGPoint(x: self.view.center.x + 20, y: targetLabel.frame.size.height)
        
        pinImage.center = CGPoint(x: targetLabel.frame.origin.x - 10, y: targetLabel.center.y)
        
        let addMedia = UIButton(frame: CGRect(x: pinImage.frame.origin.x - 30.0, y: pinImage.frame.origin.y + pinImage.frame.size.height + 20, width: 100.0, height: 35.0))
        addMedia.backgroundColor = UIColor(hex:0xffd24e)
        addMedia.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 13.0)
        addMedia.setTitle("ADD MEDIA", forState: UIControlState.Normal)
        addMedia.setTitleColor(UIColor.blackColor().alpha(0.6), forState: UIControlState.Normal)
        addMedia.layer.cornerRadius = 16.0
        addMedia.addTarget(self, action: #selector(toggleAttachmentButtons), forControlEvents: .TouchUpInside)
        
        let doneButton = UIButton(frame: CGRect(x: addMedia.frame.origin.x + addMedia.frame.size.width + 40.0, y: addMedia.frame.origin.y, width: 100.0, height: 35.0))
        doneButton.backgroundColor = UIColor(hex:0xffd24e)
        doneButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 13.0)
        doneButton.setTitle("DONE", forState: UIControlState.Normal)
        doneButton.setTitleColor(UIColor.blackColor().alpha(0.6), forState: UIControlState.Normal)
        doneButton.layer.cornerRadius = 17.0
        doneButton.addTarget(self, action: #selector(doneStorytelling), forControlEvents: .TouchUpInside)
        
        textButtonContainer.frame = CGRect(x: addMedia.frame.origin.x - 20.0, y: targetOverlay.frame.origin.y + targetOverlay.frame.size.height + 20.0, width: 80.0, height: 60.0)
        textButtonContainer.backgroundColor = UIColor.blackColor().alpha(0.6)
        textButtonContainer.layer.cornerRadius = 10.0
        
        textButton.frame = CGRect(x: 0, y: 0, width: 80.0, height: 60.0)
        textButton.backgroundColor = UIColor.clearColor()
        textButton.layer.cornerRadius = 10.0
        textButton.addTarget(self, action: #selector(textButtonDown), forControlEvents: .TouchUpInside)
        
        let textButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        textButtonLabel.text = "TEXT"
        textButtonLabel.font = UIFont(name:"Avenir-Book", size: 12.0)
        textButtonLabel.textColor = UIColor.whiteColor()
        textButtonLabel.sizeToFit()
        textButtonLabel.center = CGPoint(x: textButtonContainer.frame.size.width/2, y: textButtonContainer.frame.size.height - textButtonLabel.frame.size.height + 5)
        
        textButtonContainer.addSubview(textButtonLabel)
        textButtonContainer.addSubview(textButton)
        textButtonContainer.hidden = true
        
        imageButtonContainer.frame = CGRect(x: textButtonContainer.frame.origin.x + textButtonContainer.frame.size.width + 20.0, y: textButtonContainer.frame.origin.y, width: 80.0, height: 60.0)
        imageButtonContainer.backgroundColor = UIColor.blackColor().alpha(0.6)
        imageButtonContainer.layer.cornerRadius = 10.0
        
        imageButton.frame = CGRect(x: 0, y: 0, width: 80.0, height: 60.0)
        imageButton.backgroundColor = UIColor.clearColor()
        imageButton.layer.cornerRadius = 10.0
        imageButton.addTarget(self, action: #selector(imageButtonDown), forControlEvents: .TouchUpInside)
        
        let imageButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        imageButtonLabel.text = "IMAGE"
        imageButtonLabel.font = UIFont(name:"Avenir-Book", size: 12.0)
        imageButtonLabel.textColor = UIColor.whiteColor()
        imageButtonLabel.sizeToFit()
        imageButtonLabel.center = CGPoint(x: imageButtonContainer.frame.size.width/2, y: imageButtonContainer.frame.size.height - imageButtonLabel.frame.size.height + 5)
        
        imageButtonContainer.addSubview(imageButtonLabel)
        imageButtonContainer.addSubview(imageButton)
        imageButtonContainer.hidden = true
        
        audioButtonContainer.frame = CGRect(x: imageButtonContainer.frame.origin.x + imageButtonContainer.frame.size.width + 20.0, y: imageButtonContainer.frame.origin.y, width: 80.0, height: 60.0)
        audioButtonContainer.backgroundColor = UIColor.blackColor().alpha(0.6)
        audioButtonContainer.layer.cornerRadius = 10.0
        
        audioButton.frame = CGRect(x: 0, y: 0, width: 80.0, height: 60.0)
        audioButton.backgroundColor = UIColor.clearColor()
        audioButton.layer.cornerRadius = 10.0
        audioButton.addTarget(self, action: #selector(audioButtonDown), forControlEvents: .TouchUpInside)
        
        let audioButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        audioButtonLabel.text = "AUDIO"
        audioButtonLabel.font = UIFont(name:"Avenir-Book", size: 12.0)
        audioButtonLabel.textColor = UIColor.whiteColor()
        audioButtonLabel.sizeToFit()
        audioButtonLabel.center = CGPoint(x: audioButtonContainer.frame.size.width/2, y: audioButtonContainer.frame.size.height - audioButtonLabel.frame.size.height + 5)
        
        audioButtonContainer.addSubview(audioButtonLabel)
        audioButtonContainer.addSubview(audioButton)
        audioButtonContainer.hidden = true
        
        self.markerNameLabel.frame = audioButtonLabel.frame
        self.markerNameLabel.font = UIFont(name:"Avenir-Book", size: 12.0)
        self.markerNameLabel.backgroundColor = UIColor.whiteColor()
        self.markerNameLabel.textColor = UIColor.blackColor()
        self.markerNameLabel.text = "text"
        self.markerNameLabel.hidden = true
        
        targetOverlay.addSubview(addMedia)
        targetOverlay.addSubview(doneButton)
        targetOverlay.addSubview(pinImage)
        targetOverlay.addSubview(targetLabel)
        
        //add toggling buttons
        
        self.view.addSubview(targetOverlay)
        self.view.addSubview(textButtonContainer)
        self.view.addSubview(imageButtonContainer)
        self.view.addSubview(audioButtonContainer)
        self.view.addSubview(self.markerNameLabel)
    }
    
    func share() {
        let share = DetailsShareViewController()
        share.optographId = optographID
        self.navigationController?.presentViewController(share, animated: true, completion: nil)
    }
    
    func doneStorytelling(){
//        self.sendOptographData();
        self.sendToNewPath();
        //        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func dismissStorytelling(){
        print("func dismissStorytelling()")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func bubblegumPop(){
        
    }
    
    func toggleAttachmentButtons() {
        
        if attachmentToggled{
            textButtonContainer.hidden = true
            imageButtonContainer.hidden = true
            audioButtonContainer.hidden = true
            
            attachmentToggled = false
        }
        else{
            textButtonContainer.hidden = false
            imageButtonContainer.hidden = false
            audioButtonContainer.hidden = false
            
            attachmentToggled = true
        }
        
    }
    
    func keyboardWillHide(notification:NSNotification){
        textFieldContainer.frame = CGRect(x: 0.0, y: self.view.frame.size.height, width: textFieldContainer.frame.size.width, height: textFieldContainer.frame.size.height)
    }
    
    func keyboardWillShow(notification:NSNotification) {
        print("func keyboardWillShow(notification:NSNotification)")
        
        let userInfo:NSDictionary = notification.userInfo!
        let keyboardFrame:NSValue = userInfo.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.CGRectValue()
        let keyboardHeight = keyboardRectangle.height
        
        textFieldContainer.frame = CGRect(x: 0.0, y: self.view.frame.size.height - keyboardHeight - 50.0, width: textFieldContainer.frame.size.width, height: textFieldContainer.frame.size.height)
    }
    
    func fixedTextDown(){
        isTextPin = false
        
        inputTextField.becomeFirstResponder()
    }
    
    func removeFixedText(){
        print("removeFixedText()")
        fixedTextLabel.text = ""
        clearTextLabel.hidden = true
    }
    
    func removeBGM(){
        //"story_object_media_description": "story bgm"
        
//        var nodeIndex = 0
        
//        for node in self.nodes {
//            if node["story_object_media_description"] as! String == "story bgm"{
//                self.nodes.removeAtIndex(nodeIndex)
//            }
//            nodeIndex += 1
//            
//            print("node count: \(self.nodes.count)")
//        }
        
        let predicate = NSPredicate(format: "story_object_media_description != %@", "story bgm")
        let filteredArray = self.nodes.filter { predicate.evaluateWithObject($0) }
        print("filteredArray: \(filteredArray.count)")
        
        self.nodes = filteredArray
        
        bgmImage.hidden = true
        removeBgm.hidden = true
    }
    
    //create a function with button tag switch for color changes
    func textButtonDown(){
        renderDelegate.addMarker(UIColor.redColor(), type:"Text Item")
        nodeItem.objectType = "TXT"
        isTextPin = true
        
//        let storyCollection = StorytellingCollectionViewController(personID: SessionService.personID)
//        
//        let optocollection = FPOptographsCollectionViewController(personID: SessionService.personID)
//        optocollection.delegate = self;
//        
//        let naviCon = UINavigationController()
//        //        naviCon.viewControllers = [optocollection]
//        naviCon.viewControllers = [optocollection]
//        
//        self.presentViewController(naviCon, animated: true, completion: nil)
        
        //add sound to pin placement
        
//        let audioFilePath = NSBundle.mainBundle().pathForResource("pop", ofType: "mp3")
//        
//        player = AVPlayer(URL: NSURL(fileURLWithPath: audioFilePath!))
//        player?.rate = 1.0
//        player?.volume = 1.0
//        player!.play()
        
        inputTextField.becomeFirstResponder()
    }
    
    //text field delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        inputTextField.resignFirstResponder()
        
        if isTextPin == true {
            
            let translationArray = [nodeItem.objectVector3.x, nodeItem.objectVector3.y, nodeItem.objectVector3.z]
            let rotationArray = [nodeItem.objectRotation.x, nodeItem.objectRotation.y, nodeItem.objectRotation.z]
            
            let child : NSDictionary = ["story_object_media_type": nodeItem.objectType,
                                        "story_object_media_face": "pin",
                                        "story_object_media_description": "text pin",
                                        "story_object_media_additional_data": inputTextField.text!,
                                        "story_object_position": translationArray,
                                        "story_object_rotation": rotationArray]
            
            print("text child: \(child)")
            
            nodes.append(child);
            
            let audioFilePath = NSBundle.mainBundle().pathForResource("pop", ofType: "mp3")
            
            player = AVPlayer(URL: NSURL(fileURLWithPath: audioFilePath!))
            player?.rate = 1.0
            player?.volume = 1.0
            player!.play()
        }
        else{
            if inputTextField.text != ""{
                fixedTextLabel.text = inputTextField.text
                fixedTextLabel.sizeToFit()
                fixedTextLabel.center = CGPoint(x: self.view.center.x, y: self.view.frame.height - 200)
                
                clearTextLabel.frame = CGRect(x: fixedTextLabel.frame.origin.x + fixedTextLabel.frame.size.width + 15.0,
                                              y: fixedTextLabel.frame.origin.y - 15.0,
                                              width: 30.0, height: 30.0)
                clearTextLabel.hidden = false
            }
        }
        
        
        return true
    }
    
    func imageButtonDown(){
        renderDelegate.addMarker(UIColor.redColor(), type:"Image Item")
        nodeItem.objectType = "NAV"
        
        let optocollection = FPOptographsCollectionViewController(personID: SessionService.personID)
        optocollection.delegate = self;
        
        let naviCon = UINavigationController()
        naviCon.viewControllers = [optocollection]
        
        self.presentViewController(naviCon, animated: true, completion: nil)
        
        //        playerItem = AVPlayerItem(URL: itemURL)
        //        player=AVPlayer(playerItem: playerItem!)
        //        player?.rate = 1.0
        //        player?.volume = 1.0
        //        player!.play()
        
        
        //        self.receiveStory()
    }
    
    func audioButtonDown(){
        nodeItem.objectType = "MUS"
        //        renderDelegate.addMarker(UIColor.greenColor(), type:"Audio Item")
        //        nodeItem.objectType = "Audio Item"
        //
        //        let optocollection = FPOptographsCollectionViewController(personID: SessionService.personID)
        //        optocollection.delegate = self;
        //
        //        let naviCon = UINavigationController()
        //        naviCon.viewControllers = [optocollection]
        //
        //        self.presentViewController(naviCon, animated: true, completion: nil)
        //        self.sendOptographData();
        
        let mediaPicker = MPMediaPickerController(mediaTypes: MPMediaType.Music)
        mediaPicker.allowsPickingMultipleItems = false
        mediaPicker.delegate = self
        
        self.presentViewController(mediaPicker, animated: true, completion: nil)
        
        print("sessionID: \(SessionService.personID)")
        
    }
    
    func mediaItemToData(selectedItemURL: NSURL){
        let songAsset = AVURLAsset(URL: selectedItemURL)
        let exporter = AVAssetExportSession(asset: songAsset, presetName: AVAssetExportPresetAppleM4A)
        exporter?.outputFileType = "com.apple.m4a-audio"
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        var documentsDirectory = ""
        
        if paths.count > 0{
            documentsDirectory = paths[0]
        }
        
        let seconds = NSDate().timeIntervalSince1970
        let intervalSeconds = NSString(format: "%0.0f", seconds)
        
        let filename = (intervalSeconds as String) + ".m4a"
        let exportFile = documentsDirectory.stringByAppendingPathComponent(filename)
        
        let exportURL = NSURL(fileURLWithPath: exportFile)
        exporter?.outputURL = exportURL
        
        exporter?.exportAsynchronouslyWithCompletionHandler({
            
            switch exporter!.status{
            case  AVAssetExportSessionStatus.Failed:
                print("failed \(exporter!.error)")
                break
            case AVAssetExportSessionStatus.Cancelled:
                print("cancelled \(exporter!.error)")
                break
            case AVAssetExportSessionStatus.Completed:
                print("completed")
                let data = NSData(contentsOfFile: exportFile)
                
                let base64: String = (data?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength))!
                
                //                print("base64string: \(base64)")
                
                let translationArray = ["", "", ""]
                
                let rotationArray = ["", "", ""]
                
                /*
                 "story_object_media_type":            "Image",
                 "story_object_media_face":            "Yo",
                 "story_object_media_description":     "Desc 1",
                 "story_object_media_additional_data": "Data 1",
                 "story_object_position":              [123, 456, 789],
                 "story_object_rotation":              [987, 654, 321],
                 "story_object_media_filename":        "Thousand Minds Logo.png",
                 "story_object_media_base64":          "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABcc */
                
                let child : NSDictionary = ["story_object_media_type": self.nodeItem.objectType,
                    "story_object_media_face": "pin",
                    "story_object_media_description": "story bgm",
                    "story_object_media_additional_data": "audio data",
                    "story_object_position": translationArray,
                    "story_object_rotation": rotationArray,
                    "story_object_media_filename": filename]
//                    ,"story_object_media_base64": base64]
                
                self.nodes.append(child)
                
                let mediaInfo : NSDictionary = ["mediaData": data!, "mediaFilename": filename]
                
                self.mediaArray.append(mediaInfo)
                print("nodes count: \(self.nodes.count)")
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.bgmImage.hidden = false
                    self.removeBgm.hidden = false
                })
                
                break
            default:
                print("complete")
            }
        })
    }
    
    //Media Picker Delegate Methods
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        var itemURL = NSURL()
        let mediaItem = mediaItemCollection.items[0]
        
        itemURL = mediaItem.assetURL!
        
        self.mediaItemToData(itemURL)
        
        //        playerItem = AVPlayerItem(URL: itemURL)
        //        player=AVPlayer(playerItem: playerItem!)
        //        player?.rate = 1.0
        //        player?.volume = 1.0
        //        player!.play()
        
        mediaPicker.dismissViewControllerAnimated(true, completion: nil)
        print("you picked: \(mediaItemCollection)")
        print("URL: \(itemURL.absoluteString)")
    }
    
    func deleteOpto() {
        print("test")
        
        let storyCollection = StorytellingCollectionViewController(personID: SessionService.personID)
        
        let optocollection = FPOptographsCollectionViewController(personID: SessionService.personID)
        storyCollection.startOpto = optographID
        optocollection.delegate = self;
        
        let naviCon = UINavigationController()
        //        naviCon.viewControllers = [optocollection]
        naviCon.viewControllers = [storyCollection]
        
        //        self.presentViewController(naviCon, animated: true, completion: nil)
        //        renderDelegate.addMarker(sphereColor)
        
        navigationController?.pushViewController(storyCollection, animated: true)
        
        
        /*
         
         if SessionService.isLoggedIn {
         let alert = UIAlertController(title:"Are you sure?", message: "Do you really want to delete this 360 image? You cannot undo this.", preferredStyle: .Alert)
         alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { _ in
         self.viewModel.deleteOpto()
         self.closeDetailsPage()
         }))
         alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
         
         self.navigationController!.presentViewController(alert, animated: true, completion: nil)
         } else {
         let alert = UIAlertController(title:"", message: "Please login to delete this 360 image.", preferredStyle: .Alert)
         alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
         self.navigationController!.presentViewController(alert, animated: true, completion: nil)
         }
         
         */
    }
    func closeDetailsPage() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func toggleComment() {
//        let commentPage = CommentTableViewController(optographID: optographID)
//        self.navigationController?.presentViewController(commentPage, animated: true, completion: nil)
    }
    
    func pinchGesture(recognizer:UIPinchGestureRecognizer) {
        
        if let view = recognizer.view {
            if recognizer.state == UIGestureRecognizerState.Began {
                hideUI()
                if transformBegin == nil {
                    transformBegin = CGAffineTransformScale(view.transform,recognizer.scale, recognizer.scale)
                }
            } else if recognizer.state == UIGestureRecognizerState.Changed {
                print(">>",view.transform.a)
                print(recognizer.scale)
                if view.transform.a >= 1.0  {
                    scnView.transform = CGAffineTransformScale(view.transform,recognizer.scale, recognizer.scale)
                    recognizer.scale = 1
                } else {
                    scnView.transform = transformBegin!
                    recognizer.scale = 1
                }
            } else if recognizer.state == UIGestureRecognizerState.Ended {
                if view.transform.a <= 1.0  {
                    scnView.transform = transformBegin!
                    recognizer.scale = 1
                }
            }
        }
    }
    
    func toggleStar() {
        //        if SessionService.isLoggedIn {
        //            viewModel.toggleLike()
        //        } else {
        //
        //            let loginOverlayViewController = LoginOverlayViewController(
        //                title: "Login to like this moment",
        //                successCallback: {
        //                    self.viewModel.toggleLike()
        //                },
        //                cancelCallback: { true },
        //                alwaysCallback: {
        //                    self.parentViewController!.tabController!.unlockUI()
        //                    self.parentViewController!.tabController!.showUI()
        //                }
        //            )
        //            parentViewController!.presentViewController(loginOverlayViewController, animated: true, completion: nil)
        //        }
        
        if SessionService.isLoggedIn {
            viewModel.toggleLike()
        } else {
            let alert = UIAlertController(title:"", message: "Please login to like this moment.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    dynamic private func pushProfile() {
        let profilepage = ProfileCollectionViewController(personID: viewModel.optographBox.model.personID)
        profilepage.isProfileVisit = true
        navigationController?.pushViewController(profilepage, animated: true)
    }
    
    func followUser() {
        
        if SessionService.isLoggedIn {
            viewModel.toggleFollow()
        } else {
            let alert = UIAlertController(title:"", message: "Please login to follow this user", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func hideUI() {
        self.whiteBackground.hidden = true
        self.hideSelectorButton.hidden = true
        //self.gyroButton.hidden = true
        self.littlePlanetButton.hidden = true
        self.isUIHide = true
        self.navigationController?.navigationBarHidden = true
    }
    
    func showUI() {
        self.whiteBackground.hidden = false
        self.hideSelectorButton.hidden = false
        //self.gyroButton.hidden = false
        self.littlePlanetButton.hidden = false
        self.isUIHide = false
        self.navigationController?.navigationBarHidden = false
    }
    
    func oneTap(recognizer:UITapGestureRecognizer) {
        if !isUIHide {
            UIView.animateWithDuration(0.4,delay: 0.3, options: .CurveEaseOut, animations: {
                self.whiteBackground.hidden = true
                self.hideSelectorButton.hidden = true
                //self.gyroButton.hidden = true
                self.littlePlanetButton.hidden = true
                self.isUIHide = true
                },completion: nil)
            self.navigationController?.navigationBarHidden = true
        } else {
            UIView.animateWithDuration(0.4,delay: 0.3, options: .CurveEaseOut, animations: {
                self.whiteBackground.hidden = false
                self.hideSelectorButton.hidden = false
                //self.gyroButton.hidden = false
                self.littlePlanetButton.hidden = false
                self.isUIHide = false
                },completion: nil)
            self.navigationController?.navigationBarHidden = false
        }
    }
    
    func twoTap(recognizer:UITapGestureRecognizer) {
        print("two tap")
        navigationController?.popViewControllerAnimated(true)
    }
    
    func selectorButton() {
        if isSelectorButtonOpen {
            closeSelector()
            isSelectorButtonOpen = false
        } else {
            openSelector()
            isSelectorButtonOpen = true
        }
    }
    
    
    func openSelector() {
        
        self.hideSelectorButton.setBackgroundImage(UIImage(named:"oval_up"), forState: .Normal)
        
        UIView.animateWithDuration(0.4,delay: 0.3, options: .CurveEaseOut, animations: {
            self.littlePlanetButton.hidden = false
            self.littlePlanetButton.align(.UnderCentered, relativeTo: self.hideSelectorButton, padding: 10, width: 35, height: 35)
            },completion: { finished in
                UIView.animateWithDuration(0.4,delay: 0.2, options: .CurveEaseOut, animations: {
                    self.gyroButton.hidden =  false
                    self.gyroButton.align(.UnderCentered, relativeTo: self.littlePlanetButton, padding: 10, width: 35, height: 35)
                    },completion: nil)
        })
        
    }
    func closeSelector() {
        UIView.animateWithDuration(0.4,delay: 0.3, options: .CurveEaseOut, animations: {
            self.gyroButton.frame.origin.y = self.littlePlanetButton.frame.origin.y
            },completion: { finished in
                self.gyroButton.hidden = true
                UIView.animateWithDuration(0.4,delay: 0.2, options: .CurveEaseOut, animations: {
                    self.littlePlanetButton.frame.origin.y = self.hideSelectorButton.frame.origin.y
                    },completion: { completed in
                        self.littlePlanetButton.hidden = true
                        self.hideSelectorButton.setBackgroundImage(UIImage(named:"oval_down"), forState: .Normal)
                })
        })
    }
    
    func littlePlanetButtonTouched() {
        Defaults[.SessionGyro] = false
        self.changeButtonIcon(false)
    }
    
    func gyroButtonTouched() {
        if Defaults[.SessionGyro] {
            Defaults[.SessionGyro] = false
            self.changeButtonIcon(false)
        } else {
            Defaults[.SessionGyro] = true
            self.changeButtonIcon(true)
        }
    }
    
    func changeButtonIcon(isGyro:Bool) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: isGyro ? gyroImageActive : gyroImageInactive, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(gyroButtonTouched))
        
        //        if isGyro {
        //            //littlePlanetButton.setBackgroundImage(UIImage(named:"details_littlePlanet_inactive"), forState: .Normal)
        //            gyroButton.setBackgroundImage(UIImage(named:"details_gyro_active"), forState: .Normal)
        //
        //        } else {
        //            //littlePlanetButton.setBackgroundImage(UIImage(named:"details_littlePlanet_active"), forState: .Normal)
        //            gyroButton.setBackgroundImage(UIImage(named:"details_gyro_inactive"), forState: .Normal)
        //        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        let point = touches.first!.locationInView(scnView)
        touchStart = point
        
        if touches.count == 1 {
            combinedMotionManager.touchStart(point)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        let point = touches.first!.locationInView(scnView)
        combinedMotionManager.touchMove(point)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        _ = touchStart!.distanceTo(touches.first!.locationInView(self.view))
        super.touchesEnded(touches, withEvent: event)
        if touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        if let touches = touches where touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        //Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": viewModel.optograph.ID, "optograph_description" : viewModel.optograph.text])
        Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": "", "optograph_description" : ""])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !isStorytelling{
            tabController!.disableScrollView()
        }
        
        
        CoreMotionRotationSource.Instance.start()
        RotationService.sharedInstance.rotationEnable()
        
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailsTableViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailsTableViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        updateNavbarAppear()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        
        //self.navigationController?.navigationBar.tintColor = UIColor(hex:0xffbc00)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        imageDownloadDisposable?.dispose()
        imageDownloadDisposable = nil
        //        CoreMotionRotationSource.Instance.stop()
        RotationService.sharedInstance.rotationDisable()
        
        if !isStorytelling{
            tabController!.enableScrollView()
        }
        
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //        tableView.contentOffset = CGPoint(x: 0, y: -(tableView.frame.height - 78))
        //        tableView.contentInset = UIEdgeInsets(top: tableView.frame.height - 78, left: 0, bottom: 10, right: 0)
    }
    
    //    func keyboardWillShow(notification: NSNotification) {
    //        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
    //        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    //    }
    //
    //    func keyboardWillHide(notification: NSNotification) {
    //        tableView.contentInset = UIEdgeInsets(top: tableView.frame.height - 78, left: 0, bottom: 10, right: 0)
    //    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    func getVisibleAndAdjacentPlaneIndices(direction: Direction) -> [CubeImageCache.Index] {
        let rotation = phiThetaToRotationMatrix(direction.phi, theta: direction.theta)
        return renderDelegate.getVisibleAndAdjacentPlaneIndicesFromRotationMatrix(rotation)
    }
    
    func setCubeImageCache(cache: CubeImageCache) {
        
        renderDelegate.reset();
        
        renderDelegate.nodeEnterScene = nil
        renderDelegate.nodeLeaveScene = nil
        
        renderDelegate.reset()
        
        renderDelegate.nodeEnterScene = { [weak self] index in
            dispatch_async(queue1) {
                cache.get(index) { [weak self] (texture: SKTexture, index: CubeImageCache.Index) in
                    self?.renderDelegate.setTexture(texture, forIndex: index)
                    Async.main { [weak self] in
                        self?.loadingStatus.value = .Loaded
                    }
                }
            }
        }
        
        renderDelegate.nodeLeaveScene = { index in
            dispatch_async(queue1) {
                cache.forget(index)
            }
        }
        
        
    }
    
    func willDisplay() {
        scnView.playing = true
    }
    
    func didEndDisplay() {
        scnView.playing = false
        combinedMotionManager.reset()
        loadingStatus.value = .Nothing
        renderDelegate.reset()
    }
    
    func forgetTextures() {
        renderDelegate.reset()
    }
    //    private func pushViewer(orientation: UIInterfaceOrientation) {
    //        rotationAlert?.dismissViewControllerAnimated(true, completion: nil)
    //        let viewerViewController = ViewerViewController(orientation: orientation, optograph: viewModel.optograph)
    //        viewerViewController.hidesBottomBarWhenPushed = true
    //        navigationController?.pushViewController(viewerViewController, animated: false)
    //        viewModel.increaseViewsCount()
    //    }
    
    func showRotationAlert() {
        rotationAlert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
        rotationAlert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController?.presentViewController(rotationAlert!, animated: true, completion: nil)
    }
    
}
