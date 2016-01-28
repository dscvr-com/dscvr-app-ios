//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct OptographSchemaType: ModelSchema {
    let ID = Expression<UUID>("optograph_id")
    let text = Expression<String>("optograph_text")
    let personID = Expression<UUID>("optograph_person_id")
    let locationID = Expression<UUID?>("optograph_location_id")
    let createdAt = Expression<NSDate>("optograph_created_at")
    let updatedAt = Expression<NSDate>("optograph_updated_at")
    let deletedAt = Expression<NSDate?>("optograph_deleted_at")
    let isStarred = Expression<Bool>("optograph_is_starred")
    let starsCount = Expression<Int>("optograph_stars_count")
    let commentsCount = Expression<Int>("optograph_comments_count")
    let viewsCount = Expression<Int>("optograph_views_count")
    let isPrivate = Expression<Bool>("optograph_is_private")
    let stitcherVersion = Expression<String>("optograph_is_stitcher_version")
    let shareAlias = Expression<String>("optograph_share_alias")
    let isStitched = Expression<Bool>("optograph_is_stitched")
    let isSubmitted = Expression<Bool>("optograph_is_submitted")
    let isOnServer = Expression<Bool>("optograph_is_on_server")
    let isPublished = Expression<Bool>("optograph_is_published")
    let isStaffPick = Expression<Bool>("optograph_is_staff_pick")
    let hashtagString = Expression<String>("optograph_hashtag_string")
    let isInFeed = Expression<Bool>("optograph_is_in_feed")
    let directionPhi = Expression<Double>("optograph_direction_phi")
    let directionTheta = Expression<Double>("optograph_direction_theta")
    let postFacebook = Expression<Bool>("optograph_post_facebook")
    let postTwitter = Expression<Bool>("optograph_post_twitter")
    let postInstagram = Expression<Bool>("optograph_post_instagram")
    let shouldBePublished = Expression<Bool>("optograph_should_be_published")
    let leftCubeTextureStatusUpload = Expression<CubeTextureStatus?>("optograph_left_cube_texture_status_upload")
    let rightCubeTextureStatusUpload = Expression<CubeTextureStatus?>("optograph_right_cube_texture_status_upload")
    let leftCubeTextureStatusSave = Expression<CubeTextureStatus?>("optograph_left_cube_texture_status_save")
    let rightCubeTextureStatusSave = Expression<CubeTextureStatus?>("optograph_right_cube_texture_status_save")
}

let OptographSchema = OptographSchemaType()
let OptographTable = Table("optograph")