import ArgumentParser
import AppKit

struct Herald: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "herald",
        abstract: "Modern macOS notification CLI built on UNUserNotificationCenter.",
        version: HeraldVersion.current,
        subcommands: [Send.self, ListNotifications.self, RemoveNotifications.self],
        defaultSubcommand: Send.self
    )
}

@main
enum HeraldApp {
    static func main() async {
        // Start NSApplication to enable system dialogs (notification permission prompt)
        // and receive UNUserNotificationCenter delegate callbacks.
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        // Run the ArgumentParser command on a detached task
        Task.detached {
            do {
                var command = try Herald.parseAsRoot()
                if var asyncCommand = command as? AsyncParsableCommand {
                    try await asyncCommand.run()
                } else {
                    try command.run()
                }
            } catch {
                Herald.exit(withError: error)
            }
            Foundation.exit(0)
        }

        // Drive the event loop for delegate callbacks and system dialogs
        app.run()
    }
}
