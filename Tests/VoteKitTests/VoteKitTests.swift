import XCTest
@testable import VoteKit

final class VoteKitTests: XCTestCase {
    func testCreationOfCSVConfigs() throws {
        let _: [CSVConfiguration] = [.defaultConfiguration(),.SMKid(), .defaultWithTags(), .onlyIds()]
    }
}
