import Foundation

enum ActivationType: String, Sendable, Codable {
    case actionClicked
    case defaultActionClicked
    case replied
    case dismissed
    case timeout
    case closed
}

struct NotificationResponse: Sendable, Codable {
    let activationType: ActivationType
    let activationValue: String?
    let activationValueIndex: Int?
    let deliveredAt: Date?
    let activationAt: Date
    let userText: String?
}
