import Foundation
import Testing

@testable import Herald

@Suite("OutputFormatter")
struct OutputFormatterTests {
    let sampleDate = Date(timeIntervalSince1970: 1_710_000_000) // 2024-03-09T16:00:00Z

    @Test("JSON output includes all fields for action click")
    func jsonActionClicked() throws {
        let response = NotificationResponse(
            activationType: .actionClicked,
            activationValue: "Yes",
            activationValueIndex: 0,
            deliveredAt: sampleDate,
            activationAt: sampleDate.addingTimeInterval(5),
            userText: nil
        )
        let output = OutputFormatter.format(response: response, asJSON: true)
        let data = try #require(output.data(using: .utf8))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let parsed = try #require(json)

        #expect(parsed["activationType"] as? String == "actionClicked")
        #expect(parsed["activationValue"] as? String == "Yes")
        #expect(parsed["activationValueIndex"] as? Int == 0)
        #expect(parsed["userText"] == nil || parsed["userText"] is NSNull)
    }

    @Test("JSON output includes userText for reply")
    func jsonReply() throws {
        let response = NotificationResponse(
            activationType: .replied,
            activationValue: "__reply__",
            activationValueIndex: nil,
            deliveredAt: sampleDate,
            activationAt: sampleDate.addingTimeInterval(10),
            userText: "Looks great!"
        )
        let output = OutputFormatter.format(response: response, asJSON: true)
        let data = try #require(output.data(using: .utf8))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let parsed = try #require(json)

        #expect(parsed["activationType"] as? String == "replied")
        #expect(parsed["userText"] as? String == "Looks great!")
    }

    @Test("JSON output for timeout has no activation value")
    func jsonTimeout() throws {
        let response = NotificationResponse(
            activationType: .timeout,
            activationValue: nil,
            activationValueIndex: nil,
            deliveredAt: sampleDate,
            activationAt: sampleDate.addingTimeInterval(30),
            userText: nil
        )
        let output = OutputFormatter.format(response: response, asJSON: true)
        let data = try #require(output.data(using: .utf8))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let parsed = try #require(json)

        #expect(parsed["activationType"] as? String == "timeout")
        #expect(parsed["activationValue"] == nil || parsed["activationValue"] is NSNull)
    }

    @Test("JSON output for closed (signal)")
    func jsonClosed() throws {
        let response = NotificationResponse(
            activationType: .closed,
            activationValue: nil,
            activationValueIndex: nil,
            deliveredAt: nil,
            activationAt: sampleDate,
            userText: nil
        )
        let output = OutputFormatter.format(response: response, asJSON: true)
        let data = try #require(output.data(using: .utf8))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let parsed = try #require(json)

        #expect(parsed["activationType"] as? String == "closed")
        #expect(parsed["deliveredAt"] == nil || parsed["deliveredAt"] is NSNull)
    }

    @Test("JSON output for default action click has no activation value")
    func jsonDefaultActionClicked() throws {
        let response = NotificationResponse(
            activationType: .defaultActionClicked,
            activationValue: nil,
            activationValueIndex: nil,
            deliveredAt: sampleDate,
            activationAt: sampleDate.addingTimeInterval(2),
            userText: nil
        )
        let output = OutputFormatter.format(response: response, asJSON: true)
        let data = try #require(output.data(using: .utf8))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let parsed = try #require(json)

        #expect(parsed["activationType"] as? String == "defaultActionClicked")
        #expect(parsed["activationValue"] == nil || parsed["activationValue"] is NSNull)
    }

    @Test("Plain text output for action click")
    func plainActionClicked() {
        let response = NotificationResponse(
            activationType: .actionClicked,
            activationValue: "Yes",
            activationValueIndex: 0,
            deliveredAt: sampleDate,
            activationAt: sampleDate,
            userText: nil
        )
        let output = OutputFormatter.format(response: response, asJSON: false)
        #expect(output == "@ACTIONCLICKED\nYes")
    }

    @Test("Plain text output for reply includes text")
    func plainReply() {
        let response = NotificationResponse(
            activationType: .replied,
            activationValue: "__reply__",
            activationValueIndex: nil,
            deliveredAt: sampleDate,
            activationAt: sampleDate,
            userText: "Hello"
        )
        let output = OutputFormatter.format(response: response, asJSON: false)
        #expect(output == "@REPLIED\n__reply__\ntext: Hello")
    }

    @Test("Plain text output for timeout")
    func plainTimeout() {
        let response = NotificationResponse(
            activationType: .timeout,
            activationValue: nil,
            activationValueIndex: nil,
            deliveredAt: sampleDate,
            activationAt: sampleDate,
            userText: nil
        )
        let output = OutputFormatter.format(response: response, asJSON: false)
        #expect(output == "@TIMEOUT")
    }

    @Test("Plain text output for dismissed")
    func plainDismissed() {
        let response = NotificationResponse(
            activationType: .dismissed,
            activationValue: nil,
            activationValueIndex: nil,
            deliveredAt: sampleDate,
            activationAt: sampleDate,
            userText: nil
        )
        let output = OutputFormatter.format(response: response, asJSON: false)
        #expect(output == "@DISMISSED")
    }

    @Test("Plain text output for default action click")
    func plainDefaultActionClicked() {
        let response = NotificationResponse(
            activationType: .defaultActionClicked,
            activationValue: nil,
            activationValueIndex: nil,
            deliveredAt: sampleDate,
            activationAt: sampleDate,
            userText: nil
        )
        let output = OutputFormatter.format(response: response, asJSON: false)
        #expect(output == "@DEFAULTACTIONCLICKED")
    }
}
