import XCTest
@testable import DicyaninStageDirector

final class DicyaninStageDirectorTests: XCTestCase {
    func testArgs() {
        let a = LaunchArgs(["app", "-Route", "a/b", "-Seed", "7", "-P.yaw", "-30", "-Other", "x"])
        XCTAssertEqual(a.route, "a/b"); XCTAssertEqual(a.seed, 7); XCTAssertEqual(a.params["yaw"], "-30")
        XCTAssertTrue(a.isActive)
        XCTAssertFalse(LaunchArgs(["app"]).isActive)
    }

    @MainActor func testGroupsAndSuffix() {
        let b = RouteBook()
        b.group("kitchen") { $0.group("stove") { $0.route("flambe") { _ in } } }
        b.route("hero") { _ in }
        XCTAssertNotNil(b.resolve("kitchen/stove/flambe"))
        XCTAssertEqual(b.resolve("flambe")?.path, "kitchen/stove/flambe")
        XCTAssertNil(b.resolve("nope"))
    }

    func testRNGDeterministic() {
        var a = SeededRNG(seed: 3), b = SeededRNG(seed: 3)
        XCTAssertEqual(a.next(), b.next())
    }
}
