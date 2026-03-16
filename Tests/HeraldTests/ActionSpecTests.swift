import UserNotifications
import Testing

@testable import Herald

@Suite("ActionSpec")
struct ActionSpecTests {
    @Test("Plain label")
    func plainLabel() {
        let spec = ActionSpec.parse("Approve")
        #expect(spec.label == "Approve")
        #expect(spec.icon == nil)
        #expect(spec.options == [])
    }

    @Test("Label with icon")
    func labelWithIcon() {
        let spec = ActionSpec.parse("Approve:checkmark.circle")
        #expect(spec.label == "Approve")
        #expect(spec.icon == "checkmark.circle")
        #expect(spec.options == [])
    }

    @Test("Destructive option")
    func destructive() {
        let spec = ActionSpec.parse("Delete!destructive")
        #expect(spec.label == "Delete")
        #expect(spec.icon == nil)
        #expect(spec.options.contains(.destructive))
    }

    @Test("Auth option")
    func authRequired() {
        let spec = ActionSpec.parse("Login!auth")
        #expect(spec.label == "Login")
        #expect(spec.options.contains(.authenticationRequired))
    }

    @Test("Foreground option")
    func foreground() {
        let spec = ActionSpec.parse("Open!foreground")
        #expect(spec.label == "Open")
        #expect(spec.options.contains(.foreground))
    }

    @Test("Multiple options")
    func multipleOptions() {
        let spec = ActionSpec.parse("Delete!destructive!foreground")
        #expect(spec.label == "Delete")
        #expect(spec.options.contains(.destructive))
        #expect(spec.options.contains(.foreground))
    }

    @Test("Options with icon")
    func optionsWithIcon() {
        let spec = ActionSpec.parse("Delete!destructive:trash")
        #expect(spec.label == "Delete")
        #expect(spec.icon == "trash")
        #expect(spec.options.contains(.destructive))
    }

    @Test("Multiple options with icon")
    func multipleOptionsWithIcon() {
        let spec = ActionSpec.parse("Delete!destructive!foreground:trash")
        #expect(spec.label == "Delete")
        #expect(spec.icon == "trash")
        #expect(spec.options.contains(.destructive))
        #expect(spec.options.contains(.foreground))
    }

    @Test("parseAll with comma-separated specs")
    func parseAll() {
        let specs = ActionSpec.parseAll("Approve:checkmark,Reject!destructive:xmark,Skip")
        #expect(specs.count == 3)
        #expect(specs[0].label == "Approve")
        #expect(specs[0].icon == "checkmark")
        #expect(specs[1].label == "Reject")
        #expect(specs[1].icon == "xmark")
        #expect(specs[1].options.contains(.destructive))
        #expect(specs[2].label == "Skip")
        #expect(specs[2].icon == nil)
        #expect(specs[2].options == [])
    }

    @Test("parseAll with nil returns empty")
    func parseAllNil() {
        let specs = ActionSpec.parseAll(nil)
        #expect(specs.isEmpty)
    }

    @Test("parseAll with empty string returns empty")
    func parseAllEmpty() {
        let specs = ActionSpec.parseAll("")
        #expect(specs.isEmpty)
    }

    @Test("Unknown option is silently ignored")
    func unknownOption() {
        let spec = ActionSpec.parse("Test!unknown")
        #expect(spec.label == "Test")
        #expect(spec.options == [])
    }

    @Test("toAction produces UNNotificationAction")
    func toAction() {
        let spec = ActionSpec.parse("Approve:checkmark.circle")
        let action = spec.toAction()
        #expect(action.identifier == "Approve")
        #expect(action.title == "Approve")
    }

    @Test("Destructive toAction sets options")
    func destructiveToAction() {
        let spec = ActionSpec.parse("Delete!destructive")
        let action = spec.toAction()
        #expect(action.options.contains(.destructive))
    }
}
