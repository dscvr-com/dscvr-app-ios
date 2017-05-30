//
//  KingFisherReplacement.swift
//  DSCVR
//
//  Created by Philipp Meyer on 30.05.17.
//  Copyright © 2017 Optonaut. All rights reserved.
//

import Foundation

class SavePhotosInterface {

    static let sharedInstance = SavePhotosInterface()

    init() {}

    func getSaveToUrl(OptographID: String) -> NSURL {
        let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        var photosPath = documentsPath.appendingPathComponent("SavedOptographs")
        photosPath = photosPath.appendingPathComponent(OptographID)
        return photosPath as NSURL
    }

    func createPhotoDirectory() {
        let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let logsPath = documentsPath.appendingPathComponent("SavedOptographs")
        do {
            try FileManager.default.createDirectory(atPath: logsPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
    }
}
