import ArgumentParser
import UserNotifications
import Foundation

final class NotificationManager: @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()
    // Strong reference to keep delegate alive (center.delegate is weak)
    private var activeDelegate: NotificationDelegate?

    func sendAndWait(
        id: String,
        title: String,
        subtitle: String?,
        body: String,
        actions: [String],
        replyPlaceholder: String?,
        closeLabel: String?,
        timeout: Int,
        soundName: String?,
        imagePath: String?,
        groupID: String?,
        threadID: String?,
        level: InterruptionLevelOption,
        relevance: Double?,
        badge: Int?
    ) async throws -> NotificationResponse {
        // 1. Request authorization
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                FileHandle.standardError.write(Data("Notification permission denied. Enable in System Settings > Notifications > Herald.\n".utf8))
                throw ExitCode(2)
            }
        } catch let error as ExitCode {
            throw error
        } catch {
            FileHandle.standardError.write(Data("Authorization error: \(error.localizedDescription)\n".utf8))
            // Check current settings for diagnostics
            let settings = await center.notificationSettings()
            FileHandle.standardError.write(Data("Authorization status: \(settings.authorizationStatus.rawValue)\n".utf8))
            FileHandle.standardError.write(Data("Hint: Open System Settings > Notifications and enable notifications for Herald.\n".utf8))
            throw ExitCode(2)
        }

        // 2. Register category with actions
        let categoryID = registerCategory(actions: actions, replyPlaceholder: replyPlaceholder, closeLabel: closeLabel)

        // 3. Build notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle { content.subtitle = subtitle }
        if let threadID { content.threadIdentifier = threadID }
        content.categoryIdentifier = categoryID

        // Sound
        if let soundName {
            switch soundName.lowercased() {
            case "none":
                content.sound = nil
            case "default":
                content.sound = .default
            default:
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
            }
        }

        // Interruption level
        switch level {
        case .passive:
            content.interruptionLevel = .passive
        case .active:
            content.interruptionLevel = .active
        case .timeSensitive:
            content.interruptionLevel = .timeSensitive
        case .critical:
            content.interruptionLevel = .critical
        }

        // Relevance score
        if let relevance {
            content.relevanceScore = max(0.0, min(1.0, relevance))
        }

        // Badge
        if let badge {
            content.badge = NSNumber(value: badge)
        }

        // Attachment
        if let imagePath {
            let attachment = try createAttachment(from: imagePath)
            content.attachments = [attachment]
        }

        // Target content identifier for grouping
        if let groupID {
            content.targetContentIdentifier = groupID
        }

        // 4. Schedule notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await center.add(request)

        let deliveredAt = Date()

        // 5. Wait for response
        let response: NotificationResponse = await withCheckedContinuation { continuation in
            let delegate = NotificationDelegate(
                continuation: continuation,
                actionLabels: actions,
                deliveredAt: deliveredAt
            )
            self.activeDelegate = delegate
            center.delegate = delegate

            // Set up timeout if specified
            if timeout > 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(timeout)) {
                    // Remove the notification and return timeout response
                    self.center.removeDeliveredNotifications(withIdentifiers: [id])
                    self.center.removePendingNotificationRequests(withIdentifiers: [id])
                    continuation.resume(returning: NotificationResponse(
                        activationType: .timeout,
                        activationValue: nil,
                        activationValueIndex: nil,
                        deliveredAt: deliveredAt,
                        activationAt: Date(),
                        userText: nil
                    ))
                }
            }

            // NSApplication.run() in Herald.main() drives the event loop
            // for delegate callbacks — no manual RunLoop needed here
        }

        return response
    }

    func removeNotifications(ids: [String]) {
        center.removeDeliveredNotifications(withIdentifiers: ids)
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func removeAllNotifications() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        await center.deliveredNotifications()
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    // MARK: - Private

    private func registerCategory(actions: [String], replyPlaceholder: String?, closeLabel: String?) -> String {
        var notificationActions: [UNNotificationAction] = []

        // If reply is enabled, add a text input action
        if let replyPlaceholder {
            let replyAction = UNTextInputNotificationAction(
                identifier: "__reply__",
                title: "Reply",
                options: [],
                textInputButtonTitle: "Send",
                textInputPlaceholder: replyPlaceholder
            )
            notificationActions.append(replyAction)
        }

        // Add button actions
        for label in actions {
            let action = UNNotificationAction(
                identifier: label,
                title: label,
                options: []
            )
            notificationActions.append(action)
        }

        let categoryID: String
        if notificationActions.isEmpty {
            categoryID = "herald.default"
            let category = UNNotificationCategory(
                identifier: categoryID,
                actions: [],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
            center.setNotificationCategories([category])
        } else {
            // Deterministic category ID from action names
            let actionIDs = notificationActions.map(\.identifier).joined(separator: "+")
            categoryID = "herald.\(actionIDs)"
            let category = UNNotificationCategory(
                identifier: categoryID,
                actions: notificationActions,
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
            center.setNotificationCategories([category])
        }

        return categoryID
    }

    private func createAttachment(from path: String) throws -> UNNotificationAttachment {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw NotificationError.attachmentNotFound(path)
        }

        // Copy to temp location (required by UNNotificationAttachment)
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("herald-attachments", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let tempFile = tempDir.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: tempFile.path) {
            try FileManager.default.removeItem(at: tempFile)
        }
        try FileManager.default.copyItem(at: url, to: tempFile)

        return try UNNotificationAttachment(identifier: UUID().uuidString, url: tempFile, options: nil)
    }
}

enum NotificationError: LocalizedError {
    case attachmentNotFound(String)

    var errorDescription: String? {
        switch self {
        case .attachmentNotFound(let path):
            return "Attachment file not found: \(path)"
        }
    }
}
