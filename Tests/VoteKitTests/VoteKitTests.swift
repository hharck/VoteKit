import Testing
@testable import VoteKit

@Suite
struct CSVTesting {
    @Test
    func creationOfCSVConfigs() throws {
        let _: [CSVConfiguration] = [.defaultConfiguration(), .SMKid(), .defaultWithTags(), .onlyIds()]
    }
}
