import ArgumentParser
import Foundation

enum NotificationClickAction: Sendable, Equatable {
    case open(URL)

    static let kindUserInfoKey = "herald.onClick.kind"
    static let targetURLUserInfoKey = "herald.onClick.targetURL"

    static func parse(
        _ rawValue: String,
        currentDirectoryURL: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true),
        fileManager: FileManager = .default
    ) throws -> NotificationClickAction {
        let parts = rawValue.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else {
            throw ValidationError(#"--on-click must use the format "open:<target>"."#)
        }

        let verb = String(parts[0]).lowercased()
        let target = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else {
            throw ValidationError("--on-click target cannot be empty.")
        }

        switch verb {
        case "open":
            return .open(try resolveOpenTarget(target, currentDirectoryURL: currentDirectoryURL, fileManager: fileManager))
        default:
            throw ValidationError("Unsupported --on-click action: \(verb). Supported: open:<target>.")
        }
    }

    var userInfo: [String: String] {
        switch self {
        case .open(let url):
            return [
                Self.kindUserInfoKey: "open",
                Self.targetURLUserInfoKey: url.absoluteString,
            ]
        }
    }

    static func from(userInfo: [AnyHashable: Any]) -> NotificationClickAction? {
        guard let kind = userInfo[kindUserInfoKey] as? String,
              let rawTarget = userInfo[targetURLUserInfoKey] as? String else {
            return nil
        }

        switch kind {
        case "open":
            guard let url = URL(string: rawTarget) else { return nil }
            return .open(url)
        default:
            return nil
        }
    }

    private static func resolveOpenTarget(
        _ target: String,
        currentDirectoryURL: URL,
        fileManager: FileManager
    ) throws -> URL {
        if let url = URL(string: target),
           let scheme = url.scheme,
           !scheme.isEmpty {
            return url
        }

        let expandedPath = (target as NSString).expandingTildeInPath
        let baseDirectoryURL = currentDirectoryURL.hasDirectoryPath
            ? currentDirectoryURL
            : currentDirectoryURL.deletingLastPathComponent()

        let fileURL: URL
        if expandedPath.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: expandedPath)
        } else {
            fileURL = URL(fileURLWithPath: expandedPath, relativeTo: baseDirectoryURL)
        }

        let normalizedURL = fileURL.standardizedFileURL.resolvingSymlinksInPath()
        guard fileManager.fileExists(atPath: normalizedURL.path) else {
            throw ValidationError("Click target not found: \(target)")
        }

        return normalizedURL
    }
}
