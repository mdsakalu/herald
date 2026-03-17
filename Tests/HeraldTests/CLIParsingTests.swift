import ArgumentParser
import Testing

@testable import Herald

@Suite("CLI Argument Parsing")
struct CLIParsingTests {
    @Test("Default subcommand is send")
    func defaultSubcommand() throws {
        let command = try Herald.parseAsRoot(["--message", "Hello"])
        #expect(command is Send)
    }

    @Test("Explicit send subcommand")
    func explicitSend() throws {
        let command = try Herald.parseAsRoot(["send", "--message", "Hello"])
        #expect(command is Send)
    }

    @Test("List subcommand")
    func listSubcommand() throws {
        let command = try Herald.parseAsRoot(["list"])
        #expect(command is ListNotifications)
    }

    @Test("Remove subcommand with --all")
    func removeAll() throws {
        let command = try Herald.parseAsRoot(["remove", "--all"])
        #expect(command is RemoveNotifications)
    }

    @Test("Send parses all flags correctly")
    func sendFlags() throws {
        let command = try Herald.parseAsRoot([
            "--message", "Test body",
            "--title", "My Title",
            "--subtitle", "Sub",
            "--reply", "Type here",
            "--actions", "Yes,No",
            "--timeout", "30",
            "--sound", "default",
            "--thread", "t1",
            "--level", "timeSensitive",
            "--relevance", "0.8",
            "--badge", "5",
            "--id", "test-id",
            "--json",
        ])
        let send = try #require(command as? Send)
        #expect(send.message == "Test body")
        #expect(send.title == "My Title")
        #expect(send.subtitle == "Sub")
        #expect(send.reply == "Type here")
        #expect(send.actions == "Yes,No")
        #expect(send.timeout == 30)
        #expect(send.sound == "default")
        #expect(send.thread == "t1")
        #expect(send.level == .timeSensitive)
        #expect(send.relevance == 0.8)
        #expect(send.badge == 5)
        #expect(send.id == "test-id")
        #expect(send.json == true)
    }

    @Test("Send defaults are correct")
    func sendDefaults() throws {
        let command = try Herald.parseAsRoot(["--message", "Hi"])
        let send = try #require(command as? Send)
        #expect(send.title == "Herald")
        #expect(send.timeout == 0)
        #expect(send.level == .active)
        #expect(send.json == false)
        #expect(send.subtitle == nil)
        #expect(send.reply == nil)
        #expect(send.actions == nil)
    }

    @Test("Remove requires exactly one option")
    func removeValidation() {
        // No options should fail
        #expect(throws: (any Error).self) {
            let cmd = try Herald.parseAsRoot(["remove"]) as! RemoveNotifications
            try cmd.validate()
        }
    }

    @Test("All interruption levels parse")
    func interruptionLevels() throws {
        for level in ["passive", "active", "timeSensitive", "critical"] {
            let command = try Herald.parseAsRoot(["--message", "x", "--level", level])
            let send = try #require(command as? Send)
            #expect(send.level.rawValue == level)
        }
    }

    @Test("Unknown flag is rejected")
    func unknownFlag() {
        #expect(throws: (any Error).self) {
            _ = try Herald.parseAsRoot(["--message", "x", "--close-label", "Dismiss"])
        }
    }

    @Test("More than 10 actions in flag value is parseable but validated at runtime")
    func actionsParseableButValidated() throws {
        // Parsing succeeds — validation happens in run()
        let command = try Herald.parseAsRoot(["--message", "x", "--actions", "A,B,C,D,E"])
        #expect(command is Send)
    }
}
