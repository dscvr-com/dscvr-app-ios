//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper
import ReactiveCocoa

typealias ImagePair = (left: NSData, right: NSData)

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
    
    var path: String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! + "/optographs/\(id)"
    }
    
    func saveImages(images: ImagePair) throws {
        let (left, right) = images
        try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        left.writeToFile("\(path)/left.jpg", atomically: true)
        right.writeToFile("\(path)/right.jpg", atomically: true)
    }
    
    func loadImages() -> ImagePair {
        let left = NSData(contentsOfFile: "\(path)/left.jpg")
        let right = NSData(contentsOfFile: "\(path)/right.jpg")
        return (left: left!, right: right!)
    }
    
    mutating func publish() -> SignalProducer<Optograph, NSError> {
        assert(!isPublished)
        
        let parameters = SignalProducer<[String: AnyObject], NSError> { sink, disposable in
            let (left, right) = self.loadImages()
            var parameters = Mapper().toJSON(self)
            
            parameters["left_image"] = left.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
            parameters["right_image"] = right.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
            
            sendNext(sink, parameters)
            sendCompleted(sink)
            
            disposable.addDisposable {}
        }
        
        return parameters.flatMap(.Latest) { Api.post("optographs", parameters: $0) }
            .on(completed: {
                self.isPublished = true
                
                try! DatabaseManager.defaultConnection.run(
                    OptographTable.filter(OptographSchema.id ==- self.id).update(
                        OptographSchema.isPublished <-- self.isPublished
                    )
                )
            })
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