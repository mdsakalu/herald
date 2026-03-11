import ArgumentParser

@main
struct Herald: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "herald",
        abstract: "Modern macOS notification CLI built on UNUserNotificationCenter.",
        version: "0.1.0",
        subcommands: [Send.self, ListNotifications.self, RemoveNotifications.self],
        defaultSubcommand: Send.self
    )
}
