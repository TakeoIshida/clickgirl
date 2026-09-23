import XCTest

final class ShogiGirlsUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUp() { continueAfterFailure = false; app = XCUIApplication(); app.launchArguments = ["--ui-testing"] }
    func tap(_ id: String) {
        let element = app.buttons[id]
        for _ in 0..<8 { if element.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(element.waitForExistence(timeout:5),id); element.tap()
    }
    func square(_ i: Int) { let e = app.buttons["square_\(i)"]; XCTAssertTrue(e.waitForExistence(timeout:5)); e.tap() }
    func testPlayPauseResumeResign() {
        app.launch(); tap("character_koharu"); tap("startMatch")
        square(54); square(45)
        XCTAssertTrue(app.staticTexts["turnStatus"].waitForExistence(timeout:8))
        tap("pause"); tap("resume")
        tap("resign"); app.alerts.buttons["投了する"].tap()
        XCTAssertTrue(app.buttons["resultHome"].waitForExistence(timeout:5))
        tap("resultHome")
        XCTAssertTrue(app.staticTexts["0勝  1敗  0分"].exists)
        XCTAssertFalse(app.buttons["resume"].exists)
    }
    func testMateUnlockAndGallery() {
        app.launchArguments += ["--mate-fixture"]
        app.launch(); tap("character_koharu"); tap("startMatch")
        square(22); square(13); app.alerts.buttons["成らない"].tap()
        XCTAssertTrue(app.staticTexts["あなたの勝ち！"].waitForExistence(timeout:5))
        XCTAssertTrue(app.otherElements["rewardUnlocked"].exists)
        tap("resultGallery"); tap("reward_0")
        XCTAssertTrue(app.staticTexts["小春 / 1勝の思い出"].exists)
    }
    func testResumeAfterRelaunch() {
        app.launch(); tap("character_koharu"); tap("startMatch"); square(54); square(45); tap("pause")
        app.terminate(); app.launchArguments += ["--keep-save"]; app.launch(); tap("resume")
        XCTAssertTrue(app.buttons["square_45"].label.contains("自分の歩"))
    }
    func testHandicapAndHints() {
        app.launch(); tap("character_koharu"); tap("handicap"); app.buttons["十枚落ち"].tap(); tap("startMatch")
        let hint = app.buttons["hint"]
        let ready = NSPredicate(format:"enabled == true")
        expectation(for:ready,evaluatedWith:hint); waitForExpectations(timeout:10)
        tap("hint")
        expectation(for:ready,evaluatedWith:hint); waitForExpectations(timeout:10)
        XCTAssertTrue(app.staticTexts["dialog"].label.contains("おすすめ"))
        XCTAssertTrue(hint.label.contains("2"))
    }
    func testScreenshots() {
        app.launchArguments += ["--all-unlocked"]
        app.launch(); capture("01-home"); tap("character_koharu"); capture("02-setup"); tap("startMatch"); capture("03-battle")
    }
    func testRewardedUndo() {
        app.launch(); tap("character_koharu"); tap("startMatch"); square(54); square(45)
        let undo = app.buttons["undo"]
        expectation(for:NSPredicate(format:"enabled == true"),evaluatedWith:undo); waitForExpectations(timeout:10)
        tap("undo"); app.alerts.buttons["動画を見る"].tap()
        XCTAssertTrue(app.buttons["square_54"].label.contains("自分の歩"))
        XCTAssertFalse(app.buttons["undo"].isEnabled)
    }
    func testBattleSelectionKeepsScrollPosition() {
        app.launch(); tap("character_koharu"); tap("startMatch")
        app.swipeUp()
        let square = app.buttons["square_54"]
        XCTAssertTrue(square.waitForExistence(timeout:5))
        XCTAssertTrue(square.isHittable)
        let before = square.frame.midY
        square.tap()
        let refreshedSquare = app.buttons["square_54"]
        XCTAssertTrue(refreshedSquare.waitForExistence(timeout:5))
        XCTAssertLessThan(abs(refreshedSquare.frame.midY-before),20)
    }
    func testUnavailableAdDoesNotConsumeHints() {
        app.launchArguments += ["--ad-unavailable"]
        app.launch(); tap("character_koharu"); tap("startMatch")
        for _ in 0..<3 {
            tap("hint")
            expectation(for:NSPredicate(format:"enabled == true"),evaluatedWith:app.buttons["hint"]); waitForExpectations(timeout:10)
        }
        tap("hint"); app.alerts.buttons["動画を見る"].tap()
        XCTAssertTrue(app.alerts["動画を読み込めなかったよ"].waitForExistence(timeout:5))
        app.alerts.buttons["閉じる"].tap()
        XCTAssertTrue(app.buttons["hint"].label.contains("0"))
    }
    private func capture(_ name: String) { let a = XCTAttachment(screenshot:app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a) }
}
