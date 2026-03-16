import Testing

@testable import Herald

@Suite("NotificationConfig")
struct NotificationConfigTests {
    private func makeConfig(
        actions: [String] = [],
        replyPlaceholder: String? = nil
    ) -> NotificationConfig {
        NotificationConfig(
            id: "test",
            title: "Title",
            subtitle: nil,
            body: "Body",
            actions: actions,
            replyPlaceholder: replyPlaceholder,
            timeout: 0,
            soundName: nil,
            imagePath: nil,
            threadID: nil,
            level: .active,
            relevance: nil,
            badge: nil
        )
    }

    @Test("isInteractive is false with no actions or reply")
    func notInteractive() {
        let config = makeConfig()
        #expect(config.isInteractive == false)
    }

    @Test("isInteractive is true with actions")
    func interactiveWithActions() {
        let config = makeConfig(actions: ["Yes", "No"])
        #expect(config.isInteractive == true)
    }

    @Test("isInteractive is true with reply placeholder")
    func interactiveWithReply() {
        let config = makeConfig(replyPlaceholder: "Type here...")
        #expect(config.isInteractive == true)
    }

    @Test("isInteractive is true with both actions and reply")
    func interactiveWithBoth() {
        let config = makeConfig(actions: ["Submit"], replyPlaceholder: "Type...")
        #expect(config.isInteractive == true)
    }
}
