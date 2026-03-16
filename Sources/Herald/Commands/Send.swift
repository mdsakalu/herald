import ArgumentParser
import Foundation

struct Send: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a notification (default subcommand)."
    )

    @Option(name: .long, help: "Notification body text. Reads from stdin if omitted.")
    var message: String?

    @Option(name: .long, help: "Title text.")
    var title: String = "Herald"

    @Option(name: .long, help: "Subtitle text.")
    var subtitle: String?

    @Option(name: .long, help: "Enable text input field; value is placeholder text.")
    var reply: String?

    @Option(name: .long, help: """
        Comma-separated button specs (max 4). \
        Format: Label[!option...][:icon]  \
        Options: !destructive (red), !auth (require unlock), !foreground (launch app)  \
        Icon: SF Symbol name after colon  \
        Examples: "Approve:checkmark.circle,Reject:xmark.circle", "Delete!destructive:trash,Keep"
        """)
    var actions: String?

    @Option(name: .long, help: "Auto-dismiss seconds (0 = sticky until interaction).")
    var timeout: Int = 0

    @Option(name: .long, help: """
        Sound: "default", "none", "critical", "critical:VOLUME", or a sound name. \
        Volume is 0.0-1.0. Critical sounds bypass DND and mute (requires entitlement).
        """)
    var sound: String?

    @Option(name: .long, help: "Attachment file path (image, GIF, video).")
    var image: String?

    @Option(name: .long, help: "Notification grouping ID (for replacement).")
    var group: String?

    @Option(name: .long, help: "Conversation thread ID (visual grouping in NC).")
    var thread: String?

    @Option(name: .long, help: "Interruption level: passive, active, timeSensitive, critical.")
    var level: InterruptionLevelOption = .active

    @Option(name: .long, help: "Stacking priority (0.0-1.0, higher = more prominent).")
    var relevance: Double?

    @Option(name: .long, help: "App icon badge number.")
    var badge: Int?

    @Option(name: .long, help: "Notification identifier (for update/replace). Auto-generated if omitted.")
    var id: String?

    @Flag(name: .long, help: "Output structured JSON.")
    var json: Bool = false

    func run() async throws {
        let body = try resolveBody()
        let notificationID = id ?? UUID().uuidString
        let actionSpecs = try parseActions()

        let config = NotificationConfig(
            id: notificationID,
            title: title,
            subtitle: subtitle,
            body: body,
            actions: actionSpecs,
            replyPlaceholder: reply,
            timeout: timeout,
            soundName: sound,
            imagePath: image,
            groupID: group,
            threadID: thread,
            level: level,
            relevance: relevance,
            badge: badge
        )

        let manager = NotificationManager()

        if config.isInteractive {
            let signalHandler = SignalHandler(notificationID: notificationID, manager: manager, jsonOutput: json)
            signalHandler.install()

            let response = try await manager.sendAndWait(config: config)
            print(OutputFormatter.format(response: response, asJSON: json))
        } else {
            try await manager.send(config: config)
        }
    }

    private func resolveBody() throws -> String {
        let body: String
        if let msg = message {
            body = msg
        } else if !FileHandle.standardInput.isTerminal {
            let data = FileHandle.standardInput.readDataToEndOfFile()
            body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } else {
            throw ValidationError("--message is required (or pipe content via stdin).")
        }

        guard !body.isEmpty else {
            throw ValidationError("Message body cannot be empty.")
        }
        return body
    }

    private func parseActions() throws -> [ActionSpec] {
        let specs = ActionSpec.parseAll(actions)
        if specs.count > 4 {
            throw ValidationError("Maximum 4 action buttons allowed.")
        }
        return specs
    }
}

enum InterruptionLevelOption: String, ExpressibleByArgument, Sendable {
    case passive
    case active
    case timeSensitive
    case critical
}

extension FileHandle {
    var isTerminal: Bool {
        isatty(fileDescriptor) == 1
    }
}
