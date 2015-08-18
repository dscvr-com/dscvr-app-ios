//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper

struct Optograph: Model {
    
    var id: UUID
    var text: String
    var person: Person?
    var createdAt: NSDate
    var isStarred: Bool
    var starsCount: Int
    var commentsCount: Int
    var viewsCount: Int
    var location: Location
    var isPublished: Bool
    
    var downloaded: Bool {
        return NSFileManager.defaultManager().fileExistsAtPath("\(path)/left.jpg") && NSFileManager.defaultManager().fileExistsAtPath("\(path)/right.jpg")
    }
    
    private var path: String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! + "/optographs/\(id)"
    }
    
    func saveImages(leftImage left: NSData, rightImage right: NSData) throws {
        try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        left.writeToFile("\(path)/left.jpg", atomically: true)
        right.writeToFile("\(path)/right.jpg", atomically: true)
    }
    
    func loadImages() -> (left: NSData, right: NSData) {
        let left = NSData(contentsOfFile: "\(path)/left.jpg")
        let right = NSData(contentsOfFile: "\(path)/right.jpg")
        return (left: left!, right: right!)
    }
    
    func downloadImages(forceDownload: Bool = false) throws {
        if downloaded {
            return
        }
        
        try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        for side in ["left", "right"] {
            let url = NSURL(string: "http://optonaut-ios-beta-dev.s3.amazonaws.com/optographs/original/\(id)/\(side).jpg")
            let data = NSData(contentsOfURL: url!)
            data!.writeToFile("\(path)/\(side).jpg", atomically: true)
        }
    }
}

extension Optograph: Mappable {
    
    static func newInstance() -> Mappable {
        return Optograph(
            id: uuid(),
            text: "",
            person: nil,
            createdAt: NSDate(),
            isStarred: false,
            starsCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            location: Location.newInstance() as! Location,
            isPublished: false
        )
    }
    
    mutating func mapping(map: Map) {
        if map.mappingType == .FromJSON {
            isPublished = true
        }
        
        id              <- map["id"]
        text            <- map["text"]
        person          <- map["person"]
        createdAt       <- (map["created_at"], NSDateTransform())
        isStarred       <- map["is_starred"]
        starsCount      <- map["stars_count"]
        commentsCount   <- map["comments_count"]
        viewsCount      <- map["views_count"]
        location        <- map["location"]
    }
    
}