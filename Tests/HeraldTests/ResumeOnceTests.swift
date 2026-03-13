import Foundation
import Testing

@testable import Herald

@Suite("ResumeOnce")
struct ResumeOnceTests {
    private func makeResponse(_ type: ActivationType) -> NotificationResponse {
        NotificationResponse(
            activationType: type,
            activationValue: nil,
            activationValueIndex: nil,
            deliveredAt: nil,
            activationAt: Date(),
            userText: nil
        )
    }

    @Test("First resume succeeds")
    func firstResumeSucceeds() async {
        let result: NotificationResponse = await withCheckedContinuation { continuation in
            let guard_ = ResumeOnce()
            guard_.resume(continuation, returning: makeResponse(.timeout))
        }
        #expect(result.activationType == .timeout)
    }

    @Test("Second resume is silently ignored")
    func secondResumeIgnored() async {
        let result: NotificationResponse = await withCheckedContinuation { continuation in
            let guard_ = ResumeOnce()
            guard_.resume(continuation, returning: makeResponse(.timeout))
            // This would crash without ResumeOnce — here it's silently ignored
            guard_.resume(continuation, returning: makeResponse(.dismissed))
        }
        // First value wins
        #expect(result.activationType == .timeout)
    }

    @Test("Concurrent resumes don't crash")
    func concurrentResumes() async {
        for _ in 0..<100 {
            let result: NotificationResponse = await withCheckedContinuation { continuation in
                let guard_ = ResumeOnce()
                DispatchQueue.global().async {
                    guard_.resume(continuation, returning: makeResponse(.timeout))
                }
                DispatchQueue.global().async {
                    guard_.resume(continuation, returning: makeResponse(.dismissed))
                }
            }
            #expect(result.activationType == .timeout || result.activationType == .dismissed)
        }
    }
}
