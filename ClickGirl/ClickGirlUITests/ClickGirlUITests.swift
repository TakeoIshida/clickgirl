//
//  ClickGirlUITests.swift
//  ClickGirlUITests
//
//  Created by 石田健雄 on 2026/03/08.
//

import XCTest

final class ClickGirlUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTitleToMainSceneSmoke() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        let start = app.buttons["startBtn"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        XCTAssertTrue(app.buttons["mainChar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["shopBtn"].exists)
        XCTAssertTrue(app.buttons["gachaBtn"].exists)
        XCTAssertTrue(app.buttons["officeBtn"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Main scene after title"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testMainMenusReturnToGame() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()

        XCTAssertTrue(app.buttons["startBtn"].waitForExistence(timeout: 5))
        app.buttons["startBtn"].tap()
        XCTAssertTrue(app.buttons["shopBtn"].waitForExistence(timeout: 5))

        app.buttons["shopBtn"].tap()
        XCTAssertTrue(app.buttons["backBtn"].waitForExistence(timeout: 5))
        app.buttons["backBtn"].tap()
        XCTAssertTrue(app.buttons["mainChar"].waitForExistence(timeout: 5))

        app.buttons["charSelectBtn"].tap()
        XCTAssertTrue(app.buttons["backBtn"].waitForExistence(timeout: 5))
        app.buttons["backBtn"].tap()
        XCTAssertTrue(app.buttons["mainChar"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
