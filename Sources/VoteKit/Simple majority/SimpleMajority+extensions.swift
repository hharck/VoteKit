extension SimpleMajority{
	func resetVoteForUser(_ id: ConstituentIdentifier) {
		votes.removeAll { $0.constituent.identifier == id }
	}
	
    public func count(force: Bool) async throws -> [VoteOption : UInt] {
        // Checks that all votes are valid
        if !force{
            try self.validateThrowing()
        }
        
        
		// Sets all to zero votes
		let result: [VoteOption: UInt] = options.reduce(into: [VoteOption: UInt]()) { partialResult, option in
			partialResult[option] = 0
		}
        return try votes.compactMap(\.preferredOption)
            .reduce(into: result) { partialResult, option in
                guard partialResult.keys.contains(option) else {
                    throw SimpleValidationErrors.nonExistingOption
                }
                partialResult[option]? += 1
            }
	}
}

enum SimpleValidationErrors: String, Error {
    case nonExistingOption = "Tried to count non-existing option"
}

extension SimpleMajority {
	public func findWinner(force: Bool, excluding: Set<VoteOption>) async throws -> WinnerWrapper {
		let counted = try await self.count(force: force)
        let highestCount = counted.values.max()
        let winner = counted.filter{ $0.value == highestCount }.map(\.key)
		return WinnerWrapper(winner)
	}
}
