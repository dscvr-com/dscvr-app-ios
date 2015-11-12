//
//  Activity.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/27/15.
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
    var deletedAt: NSDate?
    var isRead: Bool
    var type: ActivityType
    var activityResourceStar: ActivityResourceStar?
    var activityResourceComment: ActivityResourceComment?
    var activityResourceViews: ActivityResourceViews?
    var activityResourceFollow: ActivityResourceFollow?
    
    var text: String {
        switch type {
        case .Star: return "\(activityResourceStar!.causingPerson.displayName) liked your Optograph."
        case .Comment: return "\(activityResourceComment!.causingPerson.displayName) commented on your Optograph: \(activityResourceComment!.comment.text)"
        case .Views: return "Congratulations! Your Optograph just hit \(activityResourceViews!.count) views."
        case .Follow:
            if activityResourceFollow!.causingPerson.isFollowed {
                return "\(activityResourceFollow!.causingPerson.displayName) followed you back."
            } else {
                return "\(activityResourceFollow!.causingPerson.displayName) started following you."
            }
        case .Nil: fatalError()
        }
    }
    
    static func newInstance() -> Activity {
        return Activity(
            ID: uuid(),
            createdAt: NSDate(),
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

func ==(lhs: Activity, rhs: Activity) -> Bool {
    return lhs.ID == rhs.ID
        && lhs.isRead == rhs.isRead
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