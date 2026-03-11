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

    @Option(name: .long, help: "Comma-separated button labels (up to 4).")
    var actions: String?

    @Option(name: .long, help: "Close/dismiss button text.")
    var closeLabel: String?

    @Option(name: .long, help: "Auto-dismiss seconds (0 = sticky until interaction).")
    var timeout: Int = 0

    @Option(name: .long, help: "Sound name (\"default\", \"none\", or system sound name).")
    var sound: String?

    @Option(name: .long, help: "Attachment file path (image, GIF, video, audio).")
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
        // Resolve message: flag > stdin
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

        let notificationID = id ?? UUID().uuidString
        let actionLabels = actions?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) } ?? []

        if actionLabels.count > 4 {
            throw ValidationError("Maximum 4 action buttons allowed.")
        }

        let manager = NotificationManager()

        // Set up signal handling for graceful cleanup
        let signalHandler = SignalHandler(notificationID: notificationID, manager: manager)
        signalHandler.install()

        do {
            let response = try await manager.sendAndWait(
                id: notificationID,
                title: title,
                subtitle: subtitle,
                body: body,
                actions: actionLabels,
                replyPlaceholder: reply,
                closeLabel: closeLabel,
                timeout: timeout,
                soundName: sound,
                imagePath: image,
                groupID: group,
                threadID: thread,
                level: level,
                relevance: relevance,
                badge: badge
            )

            let output = OutputFormatter.format(response: response, asJSON: json)
            print(output)
        } catch {
            FileHandle.standardError.write(Data("Error: \(error.localizedDescription)\n".utf8))
            throw ExitCode(1)
        }
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
