import Foundation

final class SignalHandler: @unchecked Sendable {
    private let notificationID: String
    private let manager: NotificationManager
    private let jsonOutput: Bool
    private var sigintSource: DispatchSourceSignal?
    private var sigtermSource: DispatchSourceSignal?

    init(notificationID: String, manager: NotificationManager, jsonOutput: Bool) {
        self.notificationID = notificationID
        self.manager = manager
        self.jsonOutput = jsonOutput
    }

    func install() {
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

            let response = NotificationResponse(
                activationType: .closed,
                activationValue: nil,
                activationValueIndex: nil,
                deliveredAt: nil,
                activationAt: Date(),
                userText: nil
            )
            print(OutputFormatter.format(response: response, asJSON: self.jsonOutput))
            exit(0)
        }
        return source
    }
}
