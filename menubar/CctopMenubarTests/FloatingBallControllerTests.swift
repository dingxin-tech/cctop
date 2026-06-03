import XCTest
@testable import CctopMenubar

@MainActor
final class FloatingBallControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "floatingBallPositionX")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "floatingBallPositionX")
        super.tearDown()
    }

    func testPositionPersistence() {
        let controller = FloatingBallController()
        controller.handleDrag(to: 350.0)
        let saved = UserDefaults.standard.double(forKey: "floatingBallPositionX")
        XCTAssertEqual(saved, 350.0, accuracy: 0.01)
    }

    func testToastShowAndCollapse() {
        let controller = FloatingBallController()
        XCTAssertNil(controller.currentToast)

        let toast = ToastEvent(
            sessionId: "test-1",
            projectName: "MyProject",
            message: "Permission needed",
            status: .waitingPermission
        )
        controller.showToast(toast)
        XCTAssertNotNil(controller.currentToast)
        XCTAssertEqual(controller.currentToast?.sessionId, "test-1")

        controller.collapseToast()
        XCTAssertNil(controller.currentToast)
    }

    func testToastReplacement() {
        let controller = FloatingBallController()

        let toast1 = ToastEvent(
            sessionId: "a", projectName: "ProjectA",
            message: "First", status: .waitingPermission
        )
        let toast2 = ToastEvent(
            sessionId: "b", projectName: "ProjectB",
            message: "Second", status: .waitingInput
        )

        controller.showToast(toast1)
        XCTAssertEqual(controller.currentToast?.sessionId, "a")

        controller.showToast(toast2)
        XCTAssertEqual(controller.currentToast?.sessionId, "b")
    }

    func testUpdateCounts() {
        let controller = FloatingBallController()
        XCTAssertEqual(controller.lastCounts, .zero)

        let counts = StatusCounts(permission: 1, attention: 0, working: 2, idle: 0)
        controller.update(counts: counts)
        XCTAssertEqual(controller.lastCounts, counts)
    }

    func testTearDown() {
        let controller = FloatingBallController()
        let toast = ToastEvent(
            sessionId: "x", projectName: "P",
            message: "msg", status: .working
        )
        controller.showToast(toast)
        controller.tearDown()
        XCTAssertNil(controller.currentToast)
        XCTAssertNil(controller.pillFrame)
    }
}
