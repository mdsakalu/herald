import Foundation

final class SignalHandler: @unchecked Sendable {
    private let notificationID: String
    private let manager: NotificationManager
    private var sigintSource: DispatchSourceSignal?
    private var sigtermSource: DispatchSourceSignal?

    init(notificationID: String, manager: NotificationManager) {
        self.notificationID = notificationID
        self.manager = manager
    }

    func install() {
        // Ignore default signal handling
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        sigintSource = makeSource(signal: SIGINT)
        sigtermSource = makeSource(signal: SIGTERM)

        sigintSource?.resume()
        sigtermSource?.resume()
    }

    private func makeSource(signal sig: Int32) -> DispatchSourceSignal {
        let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.manager.removeNotifications(ids: [self.notificationID])
            print("@CLOSED")
            exit(0)
        }
        return source
    }
}
