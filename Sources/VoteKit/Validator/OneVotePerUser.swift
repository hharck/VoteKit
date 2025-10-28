/// Will not validate any constitutent voting multiple times
internal struct OneVotePerUser<VoteType: VoteStub>: Validateable {
    let id = "OneVotePerUser"
    let name = "One vote per user"

    func validate(_ votes: [VoteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult {
        let nonUniques = Set(votes.map(\.constituent.identifier).nonUniques())
        let offenders = votes.filter { nonUniques.contains($0.constituent.identifier) }
        let offenseTexts = offenders.map { "\($0.constituent.identifier) voted multiple times"}
        return makeResult(errors: offenseTexts)
    }

    static var allValidators: [OneVotePerUser<VoteType>] { [Self()] }
}
