//
//  Activity.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 6/27/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import ObjectMapper

enum ActivityType: String {
    case Star = "star"
    case Comment = "comment"
    case Views = "views"
    case Follow = "follow"
    case Nil = ""
}

struct Activity: DeletableModel {
    
    var ID: UUID
    var createdAt: NSDate
    var updatedAt: NSDate
    var deletedAt: NSDate?
    var isRead: Bool
    var type: ActivityType
    var activityResourceStar: ActivityResourceStarModel?
    var activityResourceComment: ActivityResourceComment?
    var activityResourceViews: ActivityResourceViews?
    var activityResourceFollow: ActivityResourceFollowModel?
    
    var text: String {
        switch type {
        case .Star: return "liked your photo."//return "\(activityResourceStar!.causingPerson.displayName) liked your Optograph."
        case .Comment: return "\(activityResourceComment!.causingPerson.displayName) commented on your photo: \(activityResourceComment!.comment.text)"
        case .Views: return "Congratulations! Your Optograph just hit \(activityResourceViews!.count) views."
        case .Follow:
            if activityResourceFollow!.causingPerson.isFollowed {
                return "followed you back."
            } else {
                //return "\(activityResourceFollow!.causingPerson.displayName) started following you."
                return "started following you."
            }
        case .Nil: fatalError()
        }
    }
    
    static func newInstance() -> Activity {
        return Activity(
            ID: uuid(),
            createdAt: NSDate(),
            updatedAt: NSDate(),
            deletedAt: nil,
            isRead: false,
            type: .Nil,
            activityResourceStar: nil,
            activityResourceComment: nil,
            activityResourceViews: nil,
            activityResourceFollow: nil
        )
    }
}

extension Activity: Equatable {}

func ==(lhs: Activity, rhs: Activity) -> Bool {
    return lhs.ID == rhs.ID
        //&& lhs.isRead == rhs.isRead
}

extension Activity: Mappable {
    
    init?(_ map: Map){
        self = Activity.newInstance()
    }
    
    mutating func mapping(map: Map) {
        let typeTransform = TransformOf<ActivityType, String>(
            fromJSON: { (value: String?) -> ActivityType? in
                guard let value = value else {
                    return .Nil
                }
                
                switch value {
                case "star": return .Star
                case "comment": return .Comment
                case "views": return .Views
                case "follow": return .Follow
                default: return .Nil
                }
            },
            toJSON: { (value: ActivityType?) -> String? in
                return value?.rawValue ?? ""
            }
        )
        
        ID                          <- map["id"]
        createdAt                   <- (map["created_at"], NSDateTransform())
        updatedAt                   <- (map["updated_at"], NSDateTransform())
        deletedAt                   <- (map["deleted_at"], NSDateTransform())
        isRead                      <- map["is_read"]
        type                        <- (map["type"], typeTransform)
        activityResourceStar        <- map["activity_resource_star"]
        activityResourceComment     <- map["activity_resource_comment"]
        activityResourceViews       <- map["activity_resource_views"]
        activityResourceFollow      <- map["activity_resource_follow"]
    }
    
}

extension Activity: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return ActivitySchema
    }
    
    static func table() -> SQLiteTable {
        return ActivityTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Activity {
        return Activity(
            ID: row[ActivitySchema.ID],
            createdAt: row[ActivitySchema.createdAt],
            updatedAt: row[ActivitySchema.updatedAt],
            deletedAt: row[ActivitySchema.deletedAt],
            isRead: row[ActivitySchema.isRead],
            type: ActivityType(rawValue: row[ActivitySchema.type])!,
            activityResourceStar: nil,
            activityResourceComment: nil,
            activityResourceViews: nil,
            activityResourceFollow: nil
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            ActivitySchema.ID <-- ID,
            ActivitySchema.createdAt <-- createdAt,
            ActivitySchema.updatedAt <-- updatedAt,
            ActivitySchema.deletedAt <-- deletedAt,
            ActivitySchema.isRead <-- isRead,
            ActivitySchema.type <-- type.rawValue,
            ActivitySchema.activityResourceStarID <-- activityResourceStar?.ID,
            ActivitySchema.activityResourceCommentID <-- activityResourceComment?.ID,
            ActivitySchema.activityResourceViewsID <-- activityResourceViews?.ID,
            ActivitySchema.activityResourceFollowID <-- activityResourceFollow?.ID,
        ]
    }
    
}