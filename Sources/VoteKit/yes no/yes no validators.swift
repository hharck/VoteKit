public enum yesNoValidators: String, Codable, CaseIterable{
	case preferenceForAllRequired
}

extension yesNoValidators: Validateable{
	public func validate(_ votes: [yesNoVote.yesNoVoteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult {
		switch self {
		case .preferenceForAllRequired:
			return validatePreferenceForAllRequired(votes, constituents, allOptions)
		}
	}
	
	
	public func validatePreferenceForAllRequired(_ votes: [yesNoVote.yesNoVoteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult {
		let errors = votes.filter{ vote in
			// Checks for unexpected values and stops execution on debug builds
			assert(allOptions.count >= vote.values.count, "Constituent has voted for more options than those available\nVoted for: \(vote.values.keys.map(\.name))\nAvailable: \(allOptions.map(\.name))")
			
			
			// Checks if the constituent has voted for all options
			if allOptions.count == vote.values.count{
				return false
			} else if vote.values.isEmpty {
				//It's a blank vote then, which is handled by the 'noBlankVotes' validator
				return false
			} else {
				// The number of options selected is between 1 and n-1, which means the validator failed, and this vote will be added to the errors array
				return true
			}
		}
			.map { vote in
				"\(vote.constituent.identifier) hasn't voted for all candidates"
			}
		
		return VoteValidationResult(name: self.name, errors: errors)
	}
	
	public var name: String {
		switch self {
		case .preferenceForAllRequired:
			return "Preference for all options"
		}
	}
}
