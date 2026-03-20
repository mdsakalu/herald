import Foundation
import Testing
import UserNotifications

@testable import Herald

@Suite("NotificationClickAction")
struct NotificationClickActionTests {
    @Test("open URL action parses")
    func openURLParses() throws {
        let action = try NotificationClickAction.parse("open:https://example.com/docs")
        #expect(action == .open(try #require(URL(string: "https://example.com/docs"))))
    }

    @Test("open file action resolves relative path")
    func openFileResolvesRelativePath() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = tempDir.appendingPathComponent("notes.md")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try Data("hello".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let action = try NotificationClickAction.parse(
            "open:notes.md",
            currentDirectoryURL: tempDir
        )

        #expect(action == .open(fileURL.standardizedFileURL.resolvingSymlinksInPath()))
    }

    @Test("unknown on-click verb is rejected")
    func unknownVerbRejected() {
        #expect(throws: (any Error).self) {
            _ = try NotificationClickAction.parse("visit:https://example.com")
        }
    }

    @Test("missing click target file is rejected")
    func missingFileRejected() {
        #expect(throws: (any Error).self) {
            _ = try NotificationClickAction.parse("open:missing.md")
        }
    }
}

@Suite("LaunchContext")
struct LaunchContextTests {
    @Test("detached no-arg launch waits for notification activation")
    func detachedLaunchWaits() {
        let context = LaunchContext(
            arguments: ["/Applications/Herald.app/Contents/MacOS/herald"],
            stdinIsTerminal: false,
            stdoutIsTerminal: false,
            stderrIsTerminal: false,
            environment: [:]
        )

        #expect(context.shouldAwaitNotificationActivation == true)
    }

    @Test("shell launch stays in CLI mode")
    func shellLaunchStaysCLI() {
        let context = LaunchContext(
            arguments: ["/usr/local/bin/herald"],
            stdinIsTerminal: true,
            stdoutIsTerminal: true,
            stderrIsTerminal: true,
            environment: ["TERM": "xterm-256color"]
        )

        #expect(context.shouldAwaitNotificationActivation == false)
    }

    @Test("help and version skip app runtime setup")
    func helpAndVersionBypassAppRuntime() {
        let versionContext = LaunchContext(
            arguments: ["/tmp/Herald", "--version"],
            stdinIsTerminal: true,
            stdoutIsTerminal: true,
            stderrIsTerminal: true,
            environment: ["TERM": "xterm-256color"]
        )
        let helpContext = LaunchContext(
            arguments: ["/tmp/Herald", "--help"],
            stdinIsTerminal: true,
            stdoutIsTerminal: true,
            stderrIsTerminal: true,
            environment: ["TERM": "xterm-256color"]
        )

        #expect(versionContext.shouldBypassAppRuntime == true)
        #expect(helpContext.shouldBypassAppRuntime == true)
    }
}

@Suite("NotificationRuntime")
struct NotificationRuntimeTests {
    let sampleDate = Date(timeIntervalSince1970: 1_710_000_000)

    @Test("default action click is distinct from dismiss")
    func defaultActionClickIsDistinct() {
        let response = NotificationRuntime.makeResult(
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            actionLabels: [],
            deliveredAt: sampleDate,
            userText: nil,
            activationAt: sampleDate.addingTimeInterval(1)
        )

        #expect(response.activationType == .defaultActionClicked)
        #expect(response.activationValue == nil)
        #expect(response.activationValueIndex == nil)
    }

    @Test("dismiss action stays dismissed")
    func dismissStaysDismissed() {
        let response = NotificationRuntime.makeResult(
            actionIdentifier: UNNotificationDismissActionIdentifier,
            actionLabels: [],
            deliveredAt: sampleDate,
            userText: nil,
            activationAt: sampleDate.addingTimeInterval(1)
        )

        #expect(response.activationType == .dismissed)
    }
}
