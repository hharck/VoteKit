nonisolated public enum SimpleMajorityValidators: String, Codable, CaseIterable {
    case noInvalidOptions
}

extension SimpleMajorityValidators: Validateable {
    public func validate(_ votes: [SimpleMajority.VoteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult {
        switch self {
        case .noInvalidOptions:
            let allCorrect = votes
                .compactMap(\.preferredOption)
                .allSatisfy(allOptions.contains(_:))
            return makeResult(errors: allCorrect ? [] : ["Unknown option"])
        }
    }

    public typealias VoteType = SimpleMajority.VoteType

    public var name: String {
        switch self {
        case .noInvalidOptions: "No invalid options"
        }
    }
}
