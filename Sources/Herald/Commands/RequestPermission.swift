import ArgumentParser
import Foundation
import UserNotifications

struct RequestPermission: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "request-permission",
        abstract: "Trigger the macOS notification permission prompt."
    )

    @Flag(name: .long, help: "Output structured JSON.")
    var json: Bool = false

    func run() async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        var status = ""
        var granted = false
        var errorString: String?

        do {
            granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            status = granted ? "granted" : "denied"
        } catch {
            status = "error"
            errorString = error.localizedDescription
        }

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            var result: [String: String] = [
                "status": status,
                "previous_status": String(describing: settings.authorizationStatus.rawValue)
            ]

            if let errorString = errorString {
                result["error"] = errorString
            }

            if let data = try? encoder.encode(result),
               let output = String(data: data, encoding: .utf8) {
                print(output)
            }
        } else {
            if let errorString = errorString {
                print("Authorization error: \(errorString)")
            } else {
                print("Authorization status: \(status)")
            }
        }

        Foundation.exit(0)
    }
}
