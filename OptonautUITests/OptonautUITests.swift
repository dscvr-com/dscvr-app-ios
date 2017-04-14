//
//  OptonautUITests.swift
//  OptonautUITests
//
//  Created by Johannes Schickling on 27/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import XCTest
import UIKit

class OptonautUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let app = XCUIApplication()
        
        setLanguage(app)
        
        app.launch()
        
        snapshot("5-login")
        
        
        app.staticTexts["Try app without login"].tap()
        
        snapshot("1-feed")
        
        
//        let img = app.tables.cells.elementBoundByIndex(1).images["preview-image"]
//        
//        waitForElementToAppear(img)
//        
//        img.tap()
        
//        print(img.frame)
//        
//        let a = app.tables.cells.elementBoundByIndex(0).coordinateWithNormalizedOffset(CGVector(dx: 0, dy: 0))
//        let b = img.coordinateWithNormalizedOffset(CGVector(dx: 0.5, dy: 0.01))
//        
//        b.tap()
//        
//        print(b.screenPoint)
        
        
//        a.pressForDuration(0, thenDragToCoordinate: b)
        
//        img.tap()
        
//        let app = XCUIApplication()
//        app.staticTexts["Try app without login"].tap()
        
        
//        let q = app.tables.descendantsMatchingType(.Any).matchingIdentifier("info")
        
//        print(q.count)
        
//        let q = q2.elementBoundByIndex(0)
        
//        print(q2.count)
        
//        let q = app.tables.cells.containingType(.StaticText, identifier: "location").elementBoundByIndex(0)
        
//        print(q.debugDescription)
//
//
//        let cell = app.tables.cells.elementBoundByIndex(0)
        
//        print(cell.debugDescription)
        
//        let coord = cell.coordinateWithNormalizedOffset(CGVector(dx: 0.5, dy: 0.5))


//        print(coord.debugDescription)
        
//        print(app.windows.element.frame)
        
//        print(XCUIApplication().tables.cells.
        
//        cell.tap()
//        print(app.images.count)
//        print(app.images["preview-image"].frame)

        
        
//        print("1")
        
//        XCUICoordinate().coordinateWithOffset(CGVector(dx: 50, dy: 200))
        
//        XCUICoordinate.
        
//        app.tables.cells.elementBoundByIndex(0).coordinateWithNormalizedOffset(CGVector(dx: 50, dy: -200))
//        app.tables.cells.elementBoundByIndex(0).childrenMatchingType(.Image).element.coordinateWithNormalizedOffset(CGVector(dx: 50, dy: 50)).tap()
        
//        print(app.tables.element.frame)
//        print(app.tables.childrenMatchingType(.Image).element.frame)
        
//        print("2")
        
//        app.tables.cells.elementAtIndex(0).tapAtPosition(CGPoint(x: 10, y: 50))
        
        // Failed to find matching element please file bug (bugreport.apple.com) and provide output from Console.app
//        XCUIApplication().navigationBars["Optonaut.DetailsTableView"].buttons["Back"].tap()
        
        
        // Failed to find matching element please file bug (bugreport.apple.com) and provide output from Console.app
    }
    
    fileprivate func waitForElementToAppear(_ element: XCUIElement, file: String = #file, line: UInt = #line) {
        let existsPredicate = NSPredicate(format: "exists == true")
        expectation(for: existsPredicate, evaluatedWith: element, handler: nil)
        
        waitForExpectations(timeout: 5) { (error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 5 seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: line, expected: true)
            }
        }
    }
    
}

extension XCUIElement {
    func tapAtPosition(_ position: CGPoint) {
        let cooridnate = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: position.x, dy: position.y))
        cooridnate.tap()
    }
}
