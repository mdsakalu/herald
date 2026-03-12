import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private let resumeOnce: ResumeOnce
    private let continuation: CheckedContinuation<NotificationResponse, Never>
    private let actionLabels: [String]
    private let deliveredAt: Date?

    init(
        resumeOnce: ResumeOnce,
        continuation: CheckedContinuation<NotificationResponse, Never>,
        actionLabels: [String],
        deliveredAt: Date?
    ) {
        self.resumeOnce = resumeOnce
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
        case UNNotificationDismissActionIdentifier, UNNotificationDefaultActionIdentifier:
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
                result = NotificationResponse(
                    activationType: .actionClicked,
                    activationValue: response.actionIdentifier,
                    activationValueIndex: actionLabels.firstIndex(of: response.actionIdentifier),
                    deliveredAt: deliveredAt,
                    activationAt: now,
                    userText: nil
                )
            }
        }

        resumeOnce.resume(continuation, returning: result)
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
