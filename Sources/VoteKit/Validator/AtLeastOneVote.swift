/// Will only validate if one or more votes has been cast
internal struct AtLeastOneVote<VoteType: VoteStub>: Validateable {
    let id = "AtLeastOneVote"
    let name = "At least one vote"

    func validate(_ votes: [VoteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult {
        makeResult(errors: votes.isEmpty ? ["No votes cast"] : [])
    }

    static var allValidators: [AtLeastOneVote<VoteType>] { [Self()] }
}
