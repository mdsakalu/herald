import Foundation

enum OutputFormatter {
    static func format(response: NotificationResponse, asJSON: Bool) -> String {
        if asJSON {
            return formatJSON(response: response)
        } else {
            return formatPlain(response: response)
        }
    }

    private static func formatJSON(response: NotificationResponse) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        guard let data = try? encoder.encode(response),
              let json = String(data: data, encoding: .utf8) else {
            return "{\"error\": \"encoding failed\"}"
        }
        return json
    }

    private static func formatPlain(response: NotificationResponse) -> String {
        var parts: [String] = []
        parts.append("@\(response.activationType.rawValue.uppercased())")

        if let value = response.activationValue {
            parts.append(value)
        }
        if let text = response.userText {
            parts.append("text: \(text)")
        }

        return parts.joined(separator: "\n")
    }
}
