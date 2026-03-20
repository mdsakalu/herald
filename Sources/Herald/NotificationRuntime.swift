import AppKit
import Foundation
import UserNotifications

protocol URLOpening: Sendable {
    func open(_ url: URL) -> Bool
}

struct WorkspaceURLOpener: URLOpening {
    func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}

struct LaunchContext: Sendable {
    let arguments: [String]
    let stdinIsTerminal: Bool
    let stdoutIsTerminal: Bool
    let stderrIsTerminal: Bool
    let environment: [String: String]

    static func current() -> LaunchContext {
        LaunchContext(
            arguments: CommandLine.arguments,
            stdinIsTerminal: FileHandle.standardInput.isTerminal,
            stdoutIsTerminal: FileHandle.standardOutput.isTerminal,
            stderrIsTerminal: FileHandle.standardError.isTerminal,
            environment: ProcessInfo.processInfo.environment
        )
    }

    var shouldAwaitNotificationActivation: Bool {
        guard arguments.count == 1 else { return false }
        guard !stdoutIsTerminal, !stderrIsTerminal else { return false }
        return environment["TERM"] == nil
    }

    var shouldBypassAppRuntime: Bool {
        arguments.contains("--version") || arguments.contains("--help") || arguments.contains("-h")
    }
}

final class NotificationRuntime: @unchecked Sendable {
    static let shared = NotificationRuntime()

    private struct InteractiveSession {
        let resumeOnce: ResumeOnce
        let continuation: CheckedContinuation<NotificationResponse, Never>
        let actionLabels: [String]
        let deliveredAt: Date?
    }

    private let center: UNUserNotificationCenter
    private let opener: any URLOpening
    private let lock = NSLock()
    private let delegate: NotificationDelegate

    private var interactiveSession: InteractiveSession?
    private var launchContinuation: CheckedContinuation<Bool, Never>?
    private var pendingLaunchResponse = false

    init(
        center: UNUserNotificationCenter = .current(),
        opener: any URLOpening = WorkspaceURLOpener()
    ) {
        self.center = center
        self.opener = opener
        self.delegate = NotificationDelegate()
        self.delegate.runtime = self
    }

    func installDelegate() {
        center.delegate = delegate
    }

    func beginInteractiveSession(
        resumeOnce: ResumeOnce,
        continuation: CheckedContinuation<NotificationResponse, Never>,
        actionLabels: [String],
        deliveredAt: Date?
    ) {
        lock.lock()
        interactiveSession = InteractiveSession(
            resumeOnce: resumeOnce,
            continuation: continuation,
            actionLabels: actionLabels,
            deliveredAt: deliveredAt
        )
        lock.unlock()
    }

    func finishInteractiveSession(with response: NotificationResponse) {
        lock.lock()
        let session = interactiveSession
        interactiveSession = nil
        lock.unlock()

        guard let session else { return }
        session.resumeOnce.resume(session.continuation, returning: response)
    }

    func waitForLaunchResponse(timeout: TimeInterval) async -> Bool {
        await withCheckedContinuation { continuation in
            lock.lock()
            if pendingLaunchResponse {
                pendingLaunchResponse = false
                lock.unlock()
                continuation.resume(returning: true)
                return
            }

            launchContinuation = continuation
            lock.unlock()

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                self.finishLaunchWait(returning: false)
            }
        }
    }

    func handle(response: UNNotificationResponse) {
        let session = currentInteractiveSession()
        let result = Self.makeResult(
            actionIdentifier: response.actionIdentifier,
            actionLabels: session?.actionLabels ?? [],
            deliveredAt: session?.deliveredAt,
            userText: (response as? UNTextInputNotificationResponse)?.userText
        )

        if case UNNotificationDefaultActionIdentifier = response.actionIdentifier,
           let clickAction = NotificationClickAction.from(userInfo: response.notification.request.content.userInfo) {
            handle(clickAction)
        }

        if session != nil {
            finishInteractiveSession(with: result)
        } else {
            signalLaunchResponse()
        }
    }

    private func currentInteractiveSession() -> InteractiveSession? {
        lock.lock()
        let session = interactiveSession
        lock.unlock()
        return session
    }

    static func makeResult(
        actionIdentifier: String,
        actionLabels: [String],
        deliveredAt: Date?,
        userText: String?,
        activationAt: Date = Date()
    ) -> NotificationResponse {
        switch actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            return NotificationResponse(
                activationType: .dismissed,
                activationValue: nil,
                activationValueIndex: nil,
                deliveredAt: deliveredAt,
                activationAt: activationAt,
                userText: nil
            )

        case UNNotificationDefaultActionIdentifier:
            return NotificationResponse(
                activationType: .defaultActionClicked,
                activationValue: nil,
                activationValueIndex: nil,
                deliveredAt: deliveredAt,
                activationAt: activationAt,
                userText: nil
            )

        default:
            if let userText {
                return NotificationResponse(
                    activationType: .replied,
                    activationValue: actionIdentifier,
                    activationValueIndex: actionLabels.firstIndex(of: actionIdentifier),
                    deliveredAt: deliveredAt,
                    activationAt: activationAt,
                    userText: userText
                )
            }

            return NotificationResponse(
                activationType: .actionClicked,
                activationValue: actionIdentifier,
                activationValueIndex: actionLabels.firstIndex(of: actionIdentifier),
                deliveredAt: deliveredAt,
                activationAt: activationAt,
                userText: nil
            )
        }
    }

    private func handle(_ clickAction: NotificationClickAction) {
        switch clickAction {
        case .open(let url):
            if !opener.open(url) {
                writeStderr("Failed to open click target: \(url.absoluteString)\n")
            }
        }
    }

    private func signalLaunchResponse() {
        lock.lock()
        let continuation = launchContinuation
        if continuation == nil {
            pendingLaunchResponse = true
        }
        launchContinuation = nil
        lock.unlock()

        continuation?.resume(returning: true)
    }

    private func finishLaunchWait(returning value: Bool) {
        lock.lock()
        let continuation = launchContinuation
        launchContinuation = nil
        lock.unlock()

        continuation?.resume(returning: value)
    }

    private func writeStderr(_ message: String) {
        FileHandle.standardError.write(Data(message.utf8))
    }
}
