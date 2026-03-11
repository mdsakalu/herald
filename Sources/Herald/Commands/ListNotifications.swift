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

        var entries: [[String: String]] = []

        for notification in delivered {
            let content = notification.request.content
            if let group, content.targetContentIdentifier != group {
                continue
            }
            entries.append([
                "id": notification.request.identifier,
                "title": content.title,
                "message": content.body,
                "status": "delivered",
            ])
        }

        for request in pending {
            let content = request.content
            if let group, content.targetContentIdentifier != group {
                continue
            }
            entries.append([
                "id": request.identifier,
                "title": content.title,
                "message": content.body,
                "status": "pending",
            ])
        }

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
