import Testing

@testable import Herald

@Suite("Version")
struct VersionTests {
    @Test("Version string is valid semver")
    func validSemver() {
        let parts = HeraldVersion.current.split(separator: ".")
        #expect(parts.count == 3)
        #expect(parts.allSatisfy { Int($0) != nil })
    }

    @Test("CLI reports same version as source")
    func cliVersionMatchesSource() {
        #expect(Herald.configuration.version == HeraldVersion.current)
    }
}
