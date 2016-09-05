//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import SQLite

class ProfileViewModel {
    
    let displayName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let followersCount = MutableProperty<Int>(0)
    let followingCount = MutableProperty<Int>(0)
    let postCount = MutableProperty<Int>(0)
    let isFollowed = MutableProperty<Bool>(false)
    let isEditing = MutableProperty<Bool>(false)
    let avatarImageUrl = MutableProperty<String>("")
    let followTabTouched = MutableProperty<Bool>(false)
    let notifTabTouched = MutableProperty<Bool>(true)
    let isMe: Bool
    let personID: UUID
    let didClickedSave = MutableProperty<Bool>(false)
    let didClickedCancel = MutableProperty<Bool>(false)
    
    //var _userName:String = ""
    
//    var person = Person.newInstance()
    private var personBox: ModelBox<Person>!
    
    init(personID: UUID) {
        personBox = Models.persons[personID]!
        
        self.personID = personID
        isMe = SessionService.personID == personID
        
        SignalProducer<Bool, ApiError>(value: isMe)
            .flatMap(.Latest) { $0 ? ApiService<PersonApiModel>.get("persons/me") : ApiService<PersonApiModel>.get("persons/\(personID)") }
            .startWithNext { [weak self] apiModel in
                self?.personBox.model.mergeApiModel(apiModel)
                //self?._userName = apiModel.userName
                self?.displayName.value = apiModel.displayName
                self?.userName.value = apiModel.userName
                self?.text.value = apiModel.text
                self?.postCount.value = apiModel.optographsCount
                self?.followersCount.value = apiModel.followersCount
                self?.followingCount.value = apiModel.followedCount
                self?.isFollowed.value = apiModel.isFollowed
                self?.avatarImageUrl.value = ImageURL("persons/\(apiModel.ID)/\(apiModel.avatarAssetID).jpg", width: 84, height: 84)
            }
        
        personBox.producer
            .skipRepeats()
            .startWithNext { [weak self] person in
                self?.displayName.value = person.displayName
                self?.userName.value = person.userName
                self?.text.value = person.text
                //self?._userName = person.userName
                self?.postCount.value = person.optographsCount
                self?.followersCount.value = person.followersCount
                self?.followingCount.value = person.followedCount
                self?.isFollowed.value = person.isFollowed
                self?.avatarImageUrl.value = ImageURL("persons/\(person.ID)/\(person.avatarAssetID).jpg", width: 84, height: 84)
            }
    }
    
    func refreshData() {
        personBox.producer
            .skipRepeats()
            .startWithNext { [weak self] person in
                self?.displayName.value = person.displayName
                self?.userName.value = person.userName
                //self?._userName = person.userName
        }
    }
    
    func saveEdit() {
        didClickedSave.value = true
        
        let parameters = [
            "display_name": displayName.value.stringByReplacingOccurrencesOfString("@", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil),
            "user_name": userName.value.stringByReplacingOccurrencesOfString("@", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil),
            "text": text.value,
        ]
        print("parameters",parameters)
        ApiService<PersonApiModel>.put("persons/me", parameters: parameters)
            .startWithCompleted { [weak self] in
                if let strongSelf = self {
                    strongSelf.personBox.insertOrUpdate { box in
                        box.model.displayName = strongSelf.displayName.value
                        box.model.userName = strongSelf.userName.value
                        box.model.text = strongSelf.text.value
                    }
                    strongSelf.isEditing.value = false
                }
            }
    }
    
    func cancelEdit() {
        displayName.value = personBox.model.userName
        userName.value = personBox.model.userName
        text.value = personBox.model.text
        isEditing.value = false
        didClickedCancel.value = true
    }
    
    func updateAvatar(image: UIImage) -> SignalProducer<Void, ApiError> {
        let avatarAssetID = uuid()
        print("persons/me/upload-profile-image",avatarAssetID)
        return ApiService<EmptyResponse>.upload("persons/me/upload-profile-image", multipartFormData: { form in
            form.appendBodyPart(data: avatarAssetID.dataUsingEncoding(NSUTF8StringEncoding)!, name: "avatar_asset_id")
            form.appendBodyPart(data: UIImageJPEGRepresentation(image, 1)!, name: "avatar_asset", fileName: "image.jpg", mimeType: "image/jpeg")
        })
            .on(completed: { [weak self] _ in
                self?.personBox.insertOrUpdate { box in
                    box.model.avatarAssetID = avatarAssetID
                }
            })
    }
    
    func toggleFollow() {
        let person = personBox.model
        let followedBefore = person.isFollowed
        
        SignalProducer<Bool, ApiError>(value: followedBefore)
            .flatMap(.Latest) { followedBefore in
                followedBefore
                    ? ApiService<EmptyResponse>.delete("persons/\(person.ID)/follow")
                    : ApiService<EmptyResponse>.post("persons/\(person.ID)/follow", parameters: nil)
            }
            .on(
                started: { [weak self] in
                    self?.personBox.insertOrUpdate { box in
                        box.model.isFollowed = !followedBefore
                    }
                },
                failed: { [weak self] _ in
                    self?.personBox.insertOrUpdate { box in
                        box.model.isFollowed = followedBefore
                    }
                }
            )
            .start()
    }
    
}
