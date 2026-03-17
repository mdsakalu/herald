import ArgumentParser
import Foundation

struct RemoveNotifications: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove notifications by ID or all."
    )

    @Option(name: .long, help: "Notification ID to remove.")
    var id: String?

    @Flag(name: .long, help: "Remove all notifications.")
    var all: Bool = false

    func validate() throws {
        let optionCount = [id != nil, all].filter { $0 }.count
        if optionCount == 0 {
            throw ValidationError("Specify --id or --all.")
        }
        if optionCount > 1 {
            throw ValidationError("Specify only one of --id or --all.")
        }
    }

    func run() async throws {
        let manager = NotificationManager()

        if all {
            manager.removeAllNotifications()
            // Wait for async removal to complete
            try await Task.sleep(for: .milliseconds(500))
            print("Removed all notifications.")
        } else if let id {
            manager.removeNotifications(ids: [id])
            try await Task.sleep(for: .milliseconds(500))
            print("Removed notification: \(id)")
        }

        Foundation.exit(0)
    }
}
