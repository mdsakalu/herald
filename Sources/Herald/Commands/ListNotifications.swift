import ArgumentParser
import Foundation

struct ListNotifications: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List delivered and pending notifications."
    )

    @Option(name: .long, help: "Filter by group ID.")
    var group: String?

    @Flag(name: .long, help: "Output structured JSON.")
    var json: Bool = false

    func run() async throws {
        let manager = NotificationManager()
        let delivered = await manager.getDeliveredNotifications()
        let pending = await manager.getPendingNotifications()

        let filteredDelivered = delivered
            .filter { group == nil || $0.request.content.targetContentIdentifier == group }
            .map { ["id": $0.request.identifier, "title": $0.request.content.title,
                     "message": $0.request.content.body, "status": "delivered"] }

        let filteredPending = pending
            .filter { group == nil || $0.content.targetContentIdentifier == group }
            .map { ["id": $0.identifier, "title": $0.content.title,
                     "message": $0.content.body, "status": "pending"] }

        let entries = filteredDelivered + filteredPending

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(entries),
               let output = String(data: data, encoding: .utf8) {
                print(output)
            }
        } else {
            if entries.isEmpty {
                print("No notifications.")
            } else {
                for entry in entries {
                    let status = entry["status"] ?? "unknown"
                    let id = entry["id"] ?? "?"
                    let title = entry["title"] ?? ""
                    let message = entry["message"] ?? ""
                    print("[\(status)] \(id): \(title) — \(message)")
                }
            }
        }

        // Exit cleanly — no need to keep run loop alive
        Foundation.exit(0)
    }
}
