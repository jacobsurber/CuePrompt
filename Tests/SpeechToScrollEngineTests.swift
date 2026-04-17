import XCTest
@testable import CuePrompt

final class SpeechToScrollEngineTests: XCTestCase {

    private func makeEngine() -> SpeechToScrollEngine {
        let engine = SpeechToScrollEngine()
        // Use tighter config for faster test convergence
        engine.config.lostTrackingTimeout = 2
        engine.config.momentumDecay = 0.1
        engine.config.momentumGain = 0.3
        return engine
    }

    private func words(_ texts: [String], startTime: TimeInterval = 0) -> [RecognizedWord] {
        texts.enumerated().map { i, text in
            RecognizedWord(text: text, timestamp: startTime + Double(i) * 0.3, confidence: 0.9)
        }
    }

    // MARK: - Initialization

    func testInitialState() {
        let engine = makeEngine()
        XCTAssertFalse(engine.isTracking)
        XCTAssertEqual(engine.scrollPosition, 0)
        XCTAssertEqual(engine.momentum, 0)
        XCTAssertEqual(engine.totalWords, 0)
        XCTAssertEqual(engine.progress, 0)
    }

    func testLoadScript() {
        let engine = makeEngine()
        engine.loadScript("Our revenue grew significantly last quarter")

        XCTAssertTrue(engine.isTracking)
        XCTAssertEqual(engine.scrollPosition, 0)
        XCTAssertGreaterThan(engine.totalWords, 0)
        XCTAssertFalse(engine.isLost)
    }

    // MARK: - Exact Following

    func testExactFollowingAdvancesPosition() {
        let engine = makeEngine()
        let script = "Our revenue grew significantly last quarter and we expect continued growth next year"
        engine.loadScript(script)

        let initialPos = engine.scrollPosition

        // Feed exact words from the script
        engine.processWords(words(["our", "revenue", "grew", "significantly"]))

        // Position should advance (anchor found)
        XCTAssertGreaterThan(engine.scrollPosition, initialPos,
            "Position should advance when exact words are spoken")
    }

    func testExactFollowingBoostsMomentum() {
        let engine = makeEngine()
        engine.loadScript("Our revenue grew significantly last quarter and we expect growth")

        engine.processWords(words(["our", "revenue", "grew", "significantly"]))

        XCTAssertGreaterThan(engine.momentum, 0,
            "Momentum should increase when strong anchors are found")
    }

    // MARK: - Drift Behavior

    func testDriftForwardWithoutSpeech() {
        let engine = makeEngine()
        engine.loadScript("one two three four five six seven eight nine ten")

        let startPos = engine.scrollPosition

        // Tick several times without speech
        for _ in 0..<10 {
            engine.tick(deltaTime: 0.1)
        }

        XCTAssertGreaterThan(engine.scrollPosition, startPos,
            "Should drift forward even without speech (base drift rate)")
    }

    func testDriftSpeedIncreasesWithMomentum() {
        let engine = makeEngine()
        let script = "alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa"
        engine.loadScript(script)

        // Measure drift without momentum
        let pos0 = engine.scrollPosition
        engine.tick(deltaTime: 1.0)
        let lowMomentumDrift = engine.scrollPosition - pos0

        // Reset and add momentum via anchor
        engine.reset()
        engine.processWords(words(["alpha", "bravo", "charlie"]))
        let posAfterAnchor = engine.scrollPosition
        engine.tick(deltaTime: 1.0)
        let highMomentumDrift = engine.scrollPosition - posAfterAnchor

        XCTAssertGreaterThan(highMomentumDrift, lowMomentumDrift,
            "Higher momentum should produce faster drift")
    }

    // MARK: - Paraphrasing Tolerance

    func testParaphrasingDoesNotStall() {
        let engine = makeEngine()
        let script = "Our quarterly revenue showed significant improvement over the previous period with strong customer acquisition"
        engine.loadScript(script)

        // Speak paraphrased content (not matching the script)
        engine.processWords(words(["we", "had", "really", "good", "numbers"]))

        // Even without matches, drift should continue
        let posAfterSpeech = engine.scrollPosition
        for _ in 0..<20 {
            engine.tick(deltaTime: 0.1)
        }

        XCTAssertGreaterThan(engine.scrollPosition, posAfterSpeech,
            "Engine should keep drifting even when speech doesn't match script")
    }

    // MARK: - Ad-lib Recovery

    func testAdLibFollowedByReturn() {
        let engine = makeEngine()
        let script = "Our revenue grew significantly and we expect continued growth in the international markets"
        engine.loadScript(script)

        // First, anchor to a known position
        engine.processWords(words(["revenue", "grew", "significantly"]))
        let anchoredPos = engine.scrollPosition

        // Ad-lib some unrelated content
        engine.processWords(words(["you", "know", "funny", "story", "about", "that"]))

        // Drift forward a bit
        for _ in 0..<5 {
            engine.tick(deltaTime: 0.1)
        }

        // Return to script — "continued growth" should re-anchor
        engine.processWords(words(["continued", "growth", "international"]))

        XCTAssertGreaterThan(engine.scrollPosition, anchoredPos,
            "Should re-anchor forward when presenter returns to script")
    }

    // MARK: - Pause / Resume

    func testPauseStopsTracking() {
        let engine = makeEngine()
        engine.loadScript("one two three four five six seven eight nine ten")

        engine.tick(deltaTime: 0.5)
        let posBeforePause = engine.scrollPosition

        engine.pause()
        engine.tick(deltaTime: 1.0)

        XCTAssertEqual(engine.scrollPosition, posBeforePause,
            "Position should not change while paused")
    }

    func testResumeResumesTracking() {
        let engine = makeEngine()
        engine.loadScript("one two three four five six seven eight nine ten")

        engine.pause()
        engine.resume()

        let posAfterResume = engine.scrollPosition
        engine.tick(deltaTime: 0.5)

        XCTAssertGreaterThan(engine.scrollPosition, posAfterResume,
            "Should resume drifting after unpause")
    }

    func testPauseIgnoresWords() {
        let engine = makeEngine()
        engine.loadScript("alpha bravo charlie delta echo foxtrot")

        engine.pause()
        engine.processWords(words(["alpha", "bravo", "charlie"]))

        XCTAssertEqual(engine.scrollPosition, 0,
            "Words should be ignored while paused")
    }

    // MARK: - Stop

    func testStopEndTracking() {
        let engine = makeEngine()
        engine.loadScript("one two three four five")

        engine.stop()

        XCTAssertFalse(engine.isTracking)
        engine.tick(deltaTime: 1.0)
        XCTAssertEqual(engine.scrollPosition, 0,
            "Should not drift after stop")
    }

    // MARK: - Progress

    func testProgressCalculation() {
        let engine = makeEngine()
        engine.loadScript("one two three four five")

        XCTAssertEqual(engine.progress, 0)

        // Drift to near the end
        for _ in 0..<100 {
            engine.tick(deltaTime: 0.5)
        }

        XCTAssertGreaterThan(engine.progress, 0)
        XCTAssertLessThanOrEqual(engine.progress, 1.0)
    }

    func testProgressZeroForNoScript() {
        let engine = makeEngine()
        XCTAssertEqual(engine.progress, 0)
    }

    // MARK: - Slide Boundaries

    func testSlideIndexUpdates() {
        let engine = makeEngine()
        // Script with 20 words, slide boundaries at word 5 and 10
        let script = "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty"
        engine.loadScript(script, slideBoundaries: [5, 10])

        XCTAssertEqual(engine.currentSlideIndex, 0)

        // Advance past first boundary
        for _ in 0..<50 {
            engine.tick(deltaTime: 0.5)
        }

        // Should be past at least the first slide boundary
        XCTAssertGreaterThanOrEqual(engine.currentSlideIndex, 1,
            "Slide index should advance when position crosses boundary")
    }

    // MARK: - Lost Tracking

    func testLostTrackingDetection() {
        let engine = makeEngine()
        engine.config.lostTrackingTimeout = 0.5 // very short for testing
        engine.loadScript("alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango")

        XCTAssertFalse(engine.isLost)

        // Tick without any speech for longer than timeout
        for _ in 0..<20 {
            engine.tick(deltaTime: 0.1)
        }

        XCTAssertTrue(engine.isLost, "Should detect lost tracking after timeout with no anchors")
    }

    // MARK: - Reset

    func testResetClearsState() {
        let engine = makeEngine()
        engine.loadScript("one two three four five six seven eight nine ten")

        // Advance
        engine.processWords(words(["one", "two", "three"]))
        engine.tick(deltaTime: 1.0)

        engine.reset()

        XCTAssertEqual(engine.scrollPosition, 0)
        XCTAssertEqual(engine.momentum, 0)
        XCTAssertFalse(engine.isLost)
        XCTAssertEqual(engine.currentSlideIndex, 0)
    }

    // MARK: - Number Normalization Integration

    func testScriptWithNumbersMatchesSpokenWords() {
        let engine = makeEngine()
        // Script has "23" which normalizes to "twenty three"
        engine.loadScript("Revenue grew 23 percent last quarter with strong performance")

        // Speech recognizer outputs the words
        engine.processWords(words(["revenue", "grew", "twenty", "three", "percent"]))

        XCTAssertGreaterThan(engine.scrollPosition, 0,
            "Normalized numbers should match between script and speech")
    }

    // MARK: - Homophone Integration

    func testHomophonesMatchCorrectly() {
        let engine = makeEngine()
        engine.loadScript("Their revenue grew because they're expanding into new markets where there is demand")

        // Speak with different homophones — should all normalize to same form
        engine.processWords(words(["there", "revenue", "grew"]))

        XCTAssertGreaterThan(engine.scrollPosition, 0,
            "Homophones should match after normalization")
    }

    // MARK: - Edge Cases

    func testEmptyScript() {
        let engine = makeEngine()
        engine.loadScript("")

        XCTAssertEqual(engine.totalWords, 0)
        engine.processWords(words(["hello"]))
        engine.tick(deltaTime: 0.1)
        // Should not crash
    }

    func testVeryShortScript() {
        let engine = makeEngine()
        engine.loadScript("hello")

        XCTAssertEqual(engine.totalWords, 1)
        engine.tick(deltaTime: 0.1)
        // Should not crash
    }

    func testRepeatedLoadScript() {
        let engine = makeEngine()
        engine.loadScript("first script content here")
        engine.processWords(words(["first", "script", "content"]))

        engine.loadScript("second script different content entirely")
        XCTAssertEqual(engine.scrollPosition, 0, "Loading new script should reset position")
        XCTAssertEqual(engine.momentum, 0, "Loading new script should reset momentum")
    }
}
