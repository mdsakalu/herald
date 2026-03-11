import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private let continuation: CheckedContinuation<NotificationResponse, Never>
    private let actionLabels: [String]
    private let deliveredAt: Date?

    init(
        continuation: CheckedContinuation<NotificationResponse, Never>,
        actionLabels: [String],
        deliveredAt: Date?
    ) {
        self.continuation = continuation
        self.actionLabels = actionLabels
        self.deliveredAt = deliveredAt
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let now = Date()

        let result: NotificationResponse
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            result = NotificationResponse(
                activationType: .dismissed,
                activationValue: nil,
                activationValueIndex: nil,
                deliveredAt: deliveredAt,
                activationAt: now,
                userText: nil
            )

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body
            result = NotificationResponse(
                activationType: .dismissed,
                activationValue: nil,
                activationValueIndex: nil,
                deliveredAt: deliveredAt,
                activationAt: now,
                userText: nil
            )

        default:
            if let textResponse = response as? UNTextInputNotificationResponse {
                result = NotificationResponse(
                    activationType: .replied,
                    activationValue: response.actionIdentifier,
                    activationValueIndex: actionLabels.firstIndex(of: response.actionIdentifier),
                    deliveredAt: deliveredAt,
                    activationAt: now,
                    userText: textResponse.userText
                )
            } else {
                let index = actionLabels.firstIndex(of: response.actionIdentifier)
                result = NotificationResponse(
                    activationType: .actionClicked,
                    activationValue: response.actionIdentifier,
                    activationValueIndex: index,
                    deliveredAt: deliveredAt,
                    activationAt: now,
                    userText: nil
                )
            }
        }

        continuation.resume(returning: result)
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even when herald is "foreground"
        completionHandler([.banner, .sound, .list])
    }
}
