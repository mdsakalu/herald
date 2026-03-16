import UserNotifications

/// Parses action specifications from CLI flag values.
///
/// Format: `Label[!option...][[:icon]]`
///
/// Examples:
///   - `Approve` — plain button
///   - `Delete!destructive` — red destructive button
///   - `Approve:checkmark.circle` — button with SF Symbol icon
///   - `Delete!destructive:trash` — destructive button with icon
///   - `Login!auth` — requires device unlock
///   - `Open!foreground` — launches app to foreground
///   - `Delete!destructive!foreground:trash` — multiple options
struct ActionSpec: Sendable {
    let label: String
    let icon: String?
    let options: UNNotificationActionOptions

    /// Parse a single action spec string like "Delete!destructive:trash"
    static func parse(_ raw: String) -> ActionSpec {
        // Split on ":" — last component after colon is the icon (if present)
        // But only if the colon-separated part looks like an icon (no "!" in it)
        var remaining = raw
        var icon: String?

        if let colonIndex = remaining.lastIndex(of: ":") {
            let candidate = String(remaining[remaining.index(after: colonIndex)...])
            if !candidate.isEmpty && !candidate.contains("!") {
                icon = candidate
                remaining = String(remaining[..<colonIndex])
            }
        }

        // Split on "!" — first part is the label, rest are options
        let parts = remaining.split(separator: "!", omittingEmptySubsequences: true)
        let label = parts.isEmpty ? remaining : String(parts[0])

        var options: UNNotificationActionOptions = []
        for part in parts.dropFirst() {
            switch part.lowercased() {
            case "destructive": options.insert(.destructive)
            case "auth": options.insert(.authenticationRequired)
            case "foreground": options.insert(.foreground)
            default: break
            }
        }

        return ActionSpec(label: label, icon: icon, options: options)
    }

    /// Parse comma-separated action specs
    static func parseAll(_ raw: String?) -> [ActionSpec] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespaces)) }
            .map { parse($0) }
    }

    /// Build a UNNotificationAction from this spec
    func toAction() -> UNNotificationAction {
        if let icon {
            return UNNotificationAction(
                identifier: label,
                title: label,
                options: options,
                icon: UNNotificationActionIcon(systemImageName: icon)
            )
        } else {
            return UNNotificationAction(
                identifier: label,
                title: label,
                options: options
            )
        }
    }
}
