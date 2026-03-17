import ArgumentParser
import AppKit

struct Herald: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "herald",
        abstract: "Modern macOS notification CLI built on UNUserNotificationCenter.",
        discussion: """
            QUICK REFERENCE (send is the default subcommand):

              herald --message "Hello" --timeout 5              Fire-and-forget
              herald --message "OK?" --actions "Yes,No" --json  Buttons, wait for click
              herald --message "?" --reply "Type..." --json     Text input, wait for reply
              herald --message "?" --reply "..." --actions "Submit,Skip" --json  Both
              echo "Done" | herald --title "CI" --sound default Pipe via stdin

            KEY FLAGS (see 'herald send --help' for all):
              --message    Notification body (or pipe via stdin)
              --title      Title text (default: Herald)
              --actions    Comma-separated button labels (max 10)
              --reply      Enable text input; value is placeholder
              --timeout    Auto-dismiss seconds (0 = wait forever)
              --sound      "default", "none", "critical", "critical:VOL", or sound name
              --image      Attachment: png/jpg/jpeg/heic/heif/tif/tiff/bmp
              --level      passive / active / timeSensitive / critical
              --json       Structured JSON output

            Non-interactive sends (no --actions/--reply) are fire-and-forget.
            Interactive sends block until the user responds or --timeout expires.
            """,
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
