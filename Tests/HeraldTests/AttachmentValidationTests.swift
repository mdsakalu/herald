import Foundation
import Testing

@testable import Herald

@Suite("Attachment validation")
struct AttachmentValidationTests {
    @Test("Still image attachments are accepted")
    func acceptsStillImages() throws {
        let pngURL = URL(fileURLWithPath: "/tmp/test-image.png")
        let jpegURL = URL(fileURLWithPath: "/tmp/test-image.jpg")

        #expect(try NotificationManager.attachmentTypeHint(for: pngURL) == "public.png")
        #expect(try NotificationManager.attachmentTypeHint(for: jpegURL) == "public.jpeg")
    }

    @Test("GIF attachments are rejected")
    func rejectsGIFs() {
        let url = URL(fileURLWithPath: "/tmp/test-image.gif")

        #expect(throws: NotificationError.self) {
            _ = try NotificationManager.attachmentTypeHint(for: url)
        }
    }

    @Test("Video attachments are rejected")
    func rejectsVideos() {
        let url = URL(fileURLWithPath: "/tmp/test-video.mp4")

        #expect(throws: NotificationError.self) {
            _ = try NotificationManager.attachmentTypeHint(for: url)
        }
    }
}
