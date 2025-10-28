import Testing
@testable import VoteKit

@Suite
struct SimpleMajorityTest {
    @Test func handleUnknownOptions() async {
        let constituents: [Constituent] = ["1", "2", "3"]
        let options: [VoteOption] = ["a", "b", "c"]
        let correctVote = SimpleMajority(
            options: options,
            constituents: [],
            votes: [.init(constituent: constituents[0], preferredOption: options[0])]
        )
        
        await #expect(throws: Never.self, performing: { try await correctVote.validateThrowing() })
        
        let voteWithUnknownOption = SimpleMajority(
            options: ["a", "b", "c"],
            constituents: [],
            votes: [.init(constituent: constituents[0], preferredOption: "d")]
        )
        await #expect(throws: VoteKitValidationErrors.self, performing: { try await voteWithUnknownOption.validateThrowing() })
    }
}
