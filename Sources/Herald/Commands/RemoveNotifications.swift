import ArgumentParser
import Foundation

struct RemoveNotifications: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove notifications by ID, group, or all."
    )

    @Option(name: .long, help: "Notification ID to remove.")
    var id: String?

    @Option(name: .long, help: "Remove all notifications in this group.")
    var group: String?

    @Flag(name: .long, help: "Remove all notifications.")
    var all: Bool = false

    func validate() throws {
        let optionCount = [id != nil, group != nil, all].filter { $0 }.count
        if optionCount == 0 {
            throw ValidationError("Specify --id, --group, or --all.")
        }
        if optionCount > 1 {
            throw ValidationError("Specify only one of --id, --group, or --all.")
        }
    }

    func run() async throws {
        let manager = NotificationManager()

        if all {
            manager.removeAllNotifications()
            print("Removed all notifications.")
        } else if let id {
            manager.removeNotifications(ids: [id])
            print("Removed notification: \(id)")
        } else if let group {
            // Remove by group: find matching notifications first
            let delivered = await manager.getDeliveredNotifications()
            let pending = await manager.getPendingNotifications()

            let deliveredIDs = delivered
                .filter { $0.request.content.targetContentIdentifier == group }
                .map(\.request.identifier)
            let pendingIDs = pending
                .filter { $0.content.targetContentIdentifier == group }
                .map(\.identifier)
            let idsToRemove = deliveredIDs + pendingIDs

            if idsToRemove.isEmpty {
                print("No notifications found for group: \(group)")
            } else {
                manager.removeNotifications(ids: idsToRemove)
                print("Removed \(idsToRemove.count) notification(s) from group: \(group)")
            }
        }

        // Exit cleanly
        Foundation.exit(0)
    }
}
