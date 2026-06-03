import Foundation

struct ToastEvent {
    let sessionId: String
    let projectName: String
    let message: String
    let status: SessionStatus
}

extension Notification.Name {
    static let floatingBallToast = Notification.Name("floatingBallToast")
    static let floatingBallClicked = Notification.Name("floatingBallClicked")
    static let floatingBallToastClicked = Notification.Name("floatingBallToastClicked")
}
