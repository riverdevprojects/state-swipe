import XCTest

final class StateSwipeUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }
    private func scoreValue() -> String {
        app.descendants(matching: .any).matching(identifier: "total-score").firstMatch.value as? String ?? "missing"
    }
    private func capture(_ name: String) {
        // Let the 0.45-second card flip finish before taking listing screenshots.
        Thread.sleep(forTimeInterval: 0.7)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    private func tap(_ id: String) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing \(id)")
        if !button.isHittable { app.swipeUp() }
        button.tap()
    }
    func testGuidedPracticePreservesGame() {
        tap("hint-1")
        let clue = app.buttons["hint-1"].label
        let score = scoreValue()
        tap("help")
        XCTAssertTrue(app.staticTexts["tutorial-progress"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["tutorial-progress"].label.contains("1 of 6"))
        capture("02-guided-tutorial")
        tap("tutorial-hint-1")
        XCTAssertEqual(app.staticTexts["tutorial-points"].label, "1,000 pts")
        tap("tutorial-hint-2")
        XCTAssertEqual(app.staticTexts["tutorial-points"].label, "910 pts")
        tap("tutorial-input")
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: app.buttons["tutorial-submit"])
        waitForExpectations(timeout: 5)
        tap("tutorial-submit")
        XCTAssertTrue(app.otherElements["tutorial-result"].exists || app.staticTexts["tutorial-result"].exists)
        tap("tutorial-continue")
        tap("tutorial-rounds-3")
        XCTAssertEqual(app.staticTexts["tutorial-rounds"].label, "3 rounds")
        tap("tutorial-back")
        XCTAssertTrue(app.staticTexts["tutorial-progress"].label.contains("5 of 6"))
        tap("tutorial-continue")
        tap("tutorial-finish")
        XCTAssertTrue(app.buttons["help"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["hint-1"].label, clue)
        XCTAssertEqual(scoreValue(), score)
        tap("help")
        XCTAssertTrue(app.staticTexts["tutorial-progress"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["tutorial-progress"].label.contains("1 of 6"))
        tap("tutorial-close")
        XCTAssertTrue(app.buttons["help"].waitForExistence(timeout: 5))
    }
    func testGuessValidationScoringAndResume() throws {
        capture("01-game")
        for i in 1...5 { tap("hint-\(i)") }
        capture("03-revealed-hints")
        let hint = app.buttons["hint-5"].label
        let data = try Data(contentsOf: Bundle(for: Self.self).url(forResource: "states", withExtension: "json")!)
        let states = try JSONSerialization.jsonObject(with: data) as! [[String: String]]
        let answer = try XCTUnwrap(states.first { hint.contains($0["giveaway"]!) }?["name"])
        let input = app.textFields["guess-input"]
        input.tap(); input.typeText("banana")
        tap("submit-guess")
        XCTAssertTrue(app.staticTexts["guess-error"].waitForExistence(timeout: 3))
        XCTAssertEqual(scoreValue(), "0")
        input.tap(); input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6) + answer)
        tap("submit-guess")
        XCTAssertFalse(app.textFields["guess-input"].exists)
        let score = scoreValue()
        XCTAssertNotEqual(score, "0")
        capture("04-correct-answer")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--resume-testing"]
        app.launch()
        XCTAssertEqual(scoreValue(), score)
        XCTAssertFalse(app.textFields["guess-input"].exists)
        XCTAssertTrue(app.staticTexts[answer].exists)
    }
    func testLargeTextTutorial() {
        app.terminate()
        app.launchArguments = ["--ui-testing", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        tap("help")
        XCTAssertTrue(app.staticTexts["tutorial-progress"].waitForExistence(timeout: 5))
        capture("accessibility-tutorial")
        tap("tutorial-hint-1")
        tap("tutorial-close")
        XCTAssertTrue(app.buttons["help"].waitForExistence(timeout: 5))
    }
    func testTutorialSkipAndBack() {
        tap("help")
        tap("tutorial-hint-1")
        tap("tutorial-back")
        XCTAssertTrue(app.buttons["tutorial-hint-1"].isEnabled)
        tap("tutorial-done")
        XCTAssertTrue(app.buttons["help"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["hint-1"].isEnabled)
    }
}
