//
//  ModelTests.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import XCTest

struct TestModel: Model {
    var id: UUID
    var createdAt: NSDate
    
    init(createdAt: NSDate) {
        self.createdAt = createdAt
        id = NSUUID().UUIDString
    }
}

class ModelTests: XCTestCase {
    
    let now = NSDate()
    
    var ascendingModels: [TestModel]!
    var descendingModels: [TestModel]!
    
    override func setUp() {
        super.setUp()
        
        ascendingModels = [
            TestModel(createdAt: date(1)),
            TestModel(createdAt: date(2)),
            TestModel(createdAt: date(3)),
        ]
        descendingModels = [
            TestModel(createdAt: date(3)),
            TestModel(createdAt: date(2)),
            TestModel(createdAt: date(1)),
        ]
    }

    func testOrderedInsertAscendingAtBeginning() {
        let model = TestModel(createdAt: date(0))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[0].id, model.id)
    }

    func testOrderedInsertAscendingAtEnd() {
        let model = TestModel(createdAt: date(4))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[3].id, model.id)
    }

    func testOrderedInsertAscendingAtMiddle() {
        ascendingModels.append(TestModel(createdAt: date(4)))
        ascendingModels.append(TestModel(createdAt: date(6)))
        let model = TestModel(createdAt: date(5))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[4].id, model.id)
    }

    func testOrderedInsertDescendingAtBeginning() {
        let model = TestModel(createdAt: date(4))
        descendingModels.orderedInsert(model, withOrder: .OrderedDescending)
        XCTAssertEqual(descendingModels[0].id, model.id)
    }

    func testOrderedInsertDescendingAtEnd() {
        let model = TestModel(createdAt: date(0))
        descendingModels.orderedInsert(model, withOrder: .OrderedDescending)
        XCTAssertEqual(descendingModels[3].id, model.id)
    }

    func testOrderedInsertDescendingAtMiddle() {
        descendingModels.insert(TestModel(createdAt: date(6)), atIndex: 0)
        descendingModels.insert(TestModel(createdAt: date(4)), atIndex: 1)
        let model = TestModel(createdAt: date(5))
        descendingModels.orderedInsert(model, withOrder: .OrderedDescending)
        XCTAssertEqual(descendingModels[1].id, model.id)
    }
    
    private func date(secondsFromNow: Double) -> NSDate {
        return now.dateByAddingTimeInterval(NSTimeInterval(secondsFromNow))
    }

}
