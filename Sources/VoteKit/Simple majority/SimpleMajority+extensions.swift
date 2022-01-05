
extension SimpleMajority{
	func resetVoteForUser(_ id: ConstituentIdentifier) {
		votes.removeAll{$0.constituent.identifier == id}
	}
	
    public func count(force: Bool) async throws -> [VoteOption : UInt] {
        // Checks that all votes are valid
        if !force{
            try self.validateThrowing()
        }
        
        
		// Sets all to zero votes
		var result: [VoteOption: UInt] = options.reduce(into:  [VoteOption: UInt]()) { partialResult, option in
			partialResult[option] = 0
		}
		for vote in votes{
			if vote.preferredOption == nil {
				continue
			}
			
			result[vote.preferredOption!]? += 1
		}
		
		return result
	}
}

extension SimpleMajority{
	public func findWinner(force: Bool, excluding: Set<VoteOption>) async throws -> WinnerWrapper {
		let counted = try await self.count(force: force)
		
		var max: UInt = 0
		counted.forEach{ option in
			if option.value > max{
				max = option.value
			}
		}
		
		let winner = counted.compactMap { key, value -> VoteOption? in
			if value == max{
				return key
			} else {
				return nil
			}
		}
		
		return WinnerWrapper(winner)
	}
}
