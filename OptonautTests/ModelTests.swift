//
//  ModelTests.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import XCTest

struct TestModel: Model {
    var id: Int
    var createdAt: NSDate
}

class ModelTests: XCTestCase {
    
    var ascendingModels: [TestModel]!
    var descendingModels: [TestModel]!
    
    override func setUp() {
        super.setUp()
        
        ascendingModels = [
            TestModel(id: 1, createdAt: date(1)),
            TestModel(id: 2, createdAt: date(2)),
            TestModel(id: 3, createdAt: date(3)),
        ]
        descendingModels = [
            TestModel(id: 3, createdAt: date(3)),
            TestModel(id: 2, createdAt: date(2)),
            TestModel(id: 1, createdAt: date(1)),
        ]
    }

    func testOrderedInsertAscendingAtBeginning() {
        let model = TestModel(id: 0, createdAt: date(0))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[0].id, model.id)
    }

    func testOrderedInsertAscendingAtEnd() {
        let model = TestModel(id: 4, createdAt: date(4))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[3].id, model.id)
    }

    func testOrderedInsertAscendingAtMiddle() {
        ascendingModels.append(TestModel(id: 4, createdAt: date(4)))
        ascendingModels.append(TestModel(id: 6, createdAt: date(6)))
        let model = TestModel(id: 5, createdAt: date(5))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[4].id, model.id)
    }

    func testOrderedInsertDescendingAtBeginning() {
        let model = TestModel(id: 0, createdAt: date(0))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[0].id, model.id)
    }

    func testOrderedInsertDescendingAtEnd() {
        let model = TestModel(id: 4, createdAt: date(4))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[3].id, model.id)
    }

    func testOrderedInsertDescendingAtMiddle() {
        ascendingModels.append(TestModel(id: 4, createdAt: date(4)))
        ascendingModels.append(TestModel(id: 6, createdAt: date(6)))
        let model = TestModel(id: 5, createdAt: date(5))
        ascendingModels.orderedInsert(model, withOrder: .OrderedAscending)
        XCTAssertEqual(ascendingModels[4].id, model.id)
    }
    
    private func date(secondsFromNow: Double) -> NSDate {
        return NSDate(timeIntervalSinceNow: NSTimeInterval(secondsFromNow))
    }

}
