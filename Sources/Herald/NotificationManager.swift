import ArgumentParser
import UserNotifications
import Foundation

struct NotificationConfig: Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let body: String
    let actions: [ActionSpec]
    let replyPlaceholder: String?
    let timeout: Int
    let soundName: String?
    let imagePath: String?
    let groupID: String?
    let threadID: String?
    let level: InterruptionLevelOption
    let relevance: Double?
    let badge: Int?

    var isInteractive: Bool {
        !actions.isEmpty || replyPlaceholder != nil
    }

    var actionLabels: [String] {
        actions.map(\.label)
    }
}

final class NotificationManager: @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()
    private var activeDelegate: NotificationDelegate?

    func send(config: NotificationConfig) async throws {
        try await authorize()

        let categoryID = registerCategory(config: config)
        let content = try buildContent(config: config, categoryID: categoryID)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: config.id, content: content, trigger: trigger)
        try await center.add(request)
    }

    func sendAndWait(config: NotificationConfig) async throws -> NotificationResponse {
        try await authorize()

        let categoryID = registerCategory(config: config)
        let content = try buildContent(config: config, categoryID: categoryID)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: config.id, content: content, trigger: trigger)
        try await center.add(request)

        let deliveredAt = Date()
        return await waitForResponse(config: config, deliveredAt: deliveredAt)
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

    private func authorize() async throws {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                writeStderr("Notification permission denied. Enable in System Settings > Notifications > Herald.\n")
                throw ExitCode(2)
            }
        } catch let error as ExitCode {
            throw error
        } catch {
            writeStderr("Authorization error: \(error.localizedDescription)\n")
            let settings = await center.notificationSettings()
            writeStderr("Authorization status: \(settings.authorizationStatus.rawValue)\n")
            writeStderr("Hint: Open System Settings > Notifications and enable notifications for Herald.\n")
            throw ExitCode(2)
        }
    }

    private func buildContent(
        config: NotificationConfig,
        categoryID: String
    ) throws -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = config.title
        content.body = config.body
        content.categoryIdentifier = categoryID

        if let subtitle = config.subtitle { content.subtitle = subtitle }
        if let threadID = config.threadID { content.threadIdentifier = threadID }
        if let groupID = config.groupID { content.targetContentIdentifier = groupID }
        if let relevance = config.relevance { content.relevanceScore = max(0.0, min(1.0, relevance)) }
        if let badge = config.badge { content.badge = NSNumber(value: badge) }

        if let soundName = config.soundName {
            content.sound = resolveSound(soundName)
        }

        content.interruptionLevel = config.level.unLevel

        if let imagePath = config.imagePath {
            content.attachments = [try createAttachment(from: imagePath)]
        }

        return content
    }

    private func waitForResponse(config: NotificationConfig, deliveredAt: Date) async -> NotificationResponse {
        let resumeOnce = ResumeOnce()

        return await withCheckedContinuation { continuation in
            let delegate = NotificationDelegate(
                resumeOnce: resumeOnce,
                continuation: continuation,
                actionLabels: config.actionLabels,
                deliveredAt: deliveredAt
            )
            self.activeDelegate = delegate
            center.delegate = delegate

            if config.timeout > 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(config.timeout)) {
                    self.center.removeDeliveredNotifications(withIdentifiers: [config.id])
                    self.center.removePendingNotificationRequests(withIdentifiers: [config.id])
                    resumeOnce.resume(continuation, returning: NotificationResponse(
                        activationType: .timeout,
                        activationValue: nil,
                        activationValueIndex: nil,
                        deliveredAt: deliveredAt,
                        activationAt: Date(),
                        userText: nil
                    ))
                }
            }
        }
    }

    /// Resolve sound specification.
    ///
    /// Formats:
    ///   - "none" — no sound
    ///   - "default" — system default
    ///   - "critical" — default critical sound (bypasses DND/mute)
    ///   - "critical:0.8" — critical with volume (0.0-1.0)
    ///   - "Glass" — named system sound from Library/Sounds
    private func resolveSound(_ spec: String) -> UNNotificationSound? {
        let lower = spec.lowercased()

        if lower == "none" { return nil }
        if lower == "default" { return .default }
        if lower == "critical" { return .defaultCritical }

        if lower.hasPrefix("critical:") {
            let rest = String(spec.dropFirst("critical:".count))
            if let volume = Float(rest) {
                return UNNotificationSound.defaultCriticalSound(withAudioVolume: max(0.0, min(1.0, volume)))
            }
            // Named critical sound: "critical:SoundName" or "critical:SoundName:0.5"
            let parts = rest.split(separator: ":", maxSplits: 1)
            let name = UNNotificationSoundName(rawValue: String(parts[0]))
            if parts.count > 1, let volume = Float(parts[1]) {
                return .criticalSoundNamed(name, withAudioVolume: max(0.0, min(1.0, volume)))
            }
            return .criticalSoundNamed(name)
        }

        return UNNotificationSound(named: UNNotificationSoundName(rawValue: spec))
    }

    private func registerCategory(config: NotificationConfig) -> String {
        var notificationActions: [UNNotificationAction] = []

        if let replyPlaceholder = config.replyPlaceholder {
            notificationActions.append(UNTextInputNotificationAction(
                identifier: "__reply__",
                title: "Reply",
                options: [],
                textInputButtonTitle: "Send",
                textInputPlaceholder: replyPlaceholder
            ))
        }

        for spec in config.actions {
            notificationActions.append(spec.toAction())
        }

        let categoryID = notificationActions.isEmpty
            ? "herald.default"
            : "herald.\(notificationActions.map(\.identifier).joined(separator: "+"))"

        let category = UNNotificationCategory(
            identifier: categoryID,
            actions: notificationActions,
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])

        return categoryID
    }

    private func createAttachment(from path: String) throws -> UNNotificationAttachment {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw NotificationError.attachmentNotFound(path)
        }

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

    private func writeStderr(_ message: String) {
        FileHandle.standardError.write(Data(message.utf8))
    }
}

/// Thread-safe guard ensuring a CheckedContinuation is resumed exactly once.
final class ResumeOnce: @unchecked Sendable {
    private var resumed = false
    private let lock = NSLock()

    func resume(_ continuation: CheckedContinuation<NotificationResponse, Never>, returning value: NotificationResponse) {
        lock.lock()
        let shouldResume = !resumed
        if shouldResume { resumed = true }
        lock.unlock()

        if shouldResume {
            continuation.resume(returning: value)
        }
    }
}

extension InterruptionLevelOption {
    var unLevel: UNNotificationInterruptionLevel {
        switch self {
        case .passive: return .passive
        case .active: return .active
        case .timeSensitive: return .timeSensitive
        case .critical: return .critical
        }
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
