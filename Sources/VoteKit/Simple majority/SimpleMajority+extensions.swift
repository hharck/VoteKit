extension SimpleMajority{
	func resetVoteForUser(_ id: ConstituentIdentifier) {
		votes.removeAll { $0.constituent.identifier == id }
	}

    public func count(force: Bool) async throws(VoteKitValidationErrors) -> [VoteOption: UInt] {
        // Checks that all votes are valid
        if !force {
            try self.validateThrowing()
        }

        // Sets all to zero votes
        let result: [VoteOption: UInt] = options.reduce(into: [VoteOption: UInt]()) { partialResult, option in
            partialResult[option] = 0
        }
        return votes.compactMap(\.preferredOption)
            .reduce(into: result) { partialResult, option in
                partialResult[option, default: 0] += 1
            }
    }
}

extension SimpleMajority: HasCustomValidators {
    nonisolated public var customValidators: [SimpleMajorityValidators] {
        [SimpleMajorityValidators.noInvalidOptions]
    }

    public typealias CustomValidators = SimpleMajorityValidators
}

extension SimpleMajority {
    public func findWinner(force: Bool, excluding: Set<VoteOption>) async throws(VoteKitValidationErrors) -> WinnerWrapper {
        let counted = try await self.count(force: force)
        let highestCount = counted.values.max()
        let winner = counted.filter{ $0.value == highestCount }.map(\.key)
        return WinnerWrapper(winner)
    }
}
