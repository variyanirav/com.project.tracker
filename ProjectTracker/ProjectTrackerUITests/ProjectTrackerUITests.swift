//
//  ProjectTrackerUITests.swift
//  ProjectTrackerUITests
//
//  Created by NiravVariya on 17/03/26.
//

import XCTest

final class ProjectTrackerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, *) {
            self.measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
