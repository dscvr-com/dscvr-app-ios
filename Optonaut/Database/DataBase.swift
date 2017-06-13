//
//  DataBase.swift
//  DSCVR
//
//  Created by Philipp Meyer on 27.04.17.
//  Copyright © 2017 Optonaut. All rights reserved.
//

import Foundation
import SQLite

class DataBase {

    static let sharedInstance = DataBase()

    init() {}

    func createDataBase() {
        let number = Expression<Int64>("number")
        let optograph = Expression<String>("optograph")

        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let optoID = Table("optoID")
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            try db.run(optoID.create(ifNotExists: true) { i in
                i.column(number, primaryKey: .autoincrement)
                i.column(optograph, unique: true)
            })
        } catch {
            print("Error while creating Database")
        }
    }

    
    // func addOptograph(optograph: Optograph)
    func addOptograph(optographID: String) {
        let number = Expression<Int64>("number")
        let optograph = Expression<String>("optograph")
        let optoID = Table("optoID")
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let rowid = try db.run(optoID.insert(optograph <- optographID))
            print("inserted id: \(rowid)")
        } catch {
            print("insertion failed: \(error)")
        }
    }

    func getOptographID(index: Int64) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let number = Expression<Int64>("number")
        let optograph = Expression<String>("optograph")
        let optoID = Table("optoID")
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let query = optoID.select(optograph)
                              .filter(number == index)
            let optographID = try db.prepare(query)
            print("Database Access success")
            for x in optographID {
                let resultAsString = x[optograph]
                return resultAsString
            }
        } catch {
            print("retreiving failed")
        }
        return ""
    }

    // getOptographs() -> [Optographs]
    func getOptographIDsAsArray() -> [String] {
        var resultArray = [String]()
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let number = Expression<Int64>("number")
        let optograph = Expression<String>("optograph")
        let optoID = Table("optoID")
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            let optographID = try db.prepare(optoID.select(optograph))
            print("Database Access success")
            for x in optographID {
                let resultAsString = x[optograph]
                resultArray.append(resultAsString)
            }
            return resultArray
        } catch {
            print("retreiving failed")
        }
        return resultArray
    }

    func deleteOptograph(optographID: String) {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let optoID = Table("optoID")
        let optograph = Expression<String>("optograph")
        let foundOptograph = optoID.filter(optograph == optographID)
        do {
            let db = try Connection("\(path)/optographs.sqlite3")
            if (try db.run(foundOptograph.delete()) == 1) {
                print("Delete Access success")
            } else {
                print ("Delete Access Fail")
            }
        } catch {
            print("retreiving failed")
        }
    }

}
