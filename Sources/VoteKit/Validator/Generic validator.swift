/// Validators which are useful for all kind of votes 
public struct GenericValidator<voteType: VoteStub>: Validateable{
	public typealias closureType = @Sendable ([voteType], _ constituents: Set<Constituent>, _ options: [VoteOption]) -> [voteType]
	public typealias offenseClosureType = @Sendable (_ for: voteType, _ options: [VoteOption]) -> String


	/// The id of the validator
	public let id: String

	/// A name for use in UI
	public let name: String

	/// Generates an error string for why a vote wasn't validated
	private let offenseText: offenseClosureType

	/// Returns every vote in violation of the validator
	private var closure: closureType


	/// Validates the given votes
	/// - Parameters:
	///   - votes: The votes to validate
	///   - constituents: The users allowed to vote
	/// - Returns: An array of error strings. Can be used along with \.name when showing the errors on the frontend
	public func validate(_ votes: [voteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult{
		let offenders = closure(votes, constituents, allOptions)
		let offenseTexts = offenders.map{offenseText($0, [])}
		return VoteValidationResult(name: self.id, errors: offenseTexts)
	}

	public init(id: String, name: String, offenseText: @escaping offenseClosureType, closure: @escaping closureType){
		self.id = id
		self.name = name
		self.offenseText = offenseText
		self.closure = closure
	}
	public init(id: String, name: String, offenseText: @Sendable @escaping (_ for: voteType) -> String, closure: @escaping closureType){
		self.init(id: id, name: name, offenseText: {u, o in offenseText(u)}, closure: closure)
	}
}


extension GenericValidator{
	public static var allValidators: [GenericValidator<voteType>] {[.everyoneHasVoted/*, .onlyVerifiedVotes*/, .noBlankVotes]}
	/// Will not validate any constitutent voting multiple times
	internal static var oneVotePerUser: GenericValidator {
		GenericValidator(id: "OneVotePerUser", name: "One vote per. user", offenseText: {"\($0.constituent.identifier) voted multiple times"}) { votes, _, _   in
			let nonUniques =  Set(votes.map(\.constituent.identifier).nonUniques())
			return votes.filter{nonUniques.contains($0.constituent.identifier)}
		}
	}
	
	/// Will not validate untill everyone on the allowed voters list has votes
	public static var everyoneHasVoted: GenericValidator {
		GenericValidator(id: "EveryoneVoted", name: "All verified users are required to vote", offenseText: {"\($0.constituent.identifier) hasn't voted"}) { votes, constituents, _ in
			let voters = votes.map(\.constituent)
			let offenders = constituents.compactMap{ const -> voteType? in
				if voters.contains(const){
					return nil
				} else {
					return voteType(bareBonesVote: const)
				}
			}
			
			return offenders
		}
	}
	
//	/// Will not validate if a constituent who is not on the allowed users list has voted
//	public static var onlyVerifiedVotes: GenericValidator {
//		GenericValidator(id: "onlyVerifiedVotes", name: "Only verified votes", offenseText: {"\($0.constituent.identifier) has voted even though they aren't on the list of verified users"}) { votes, constituents, _  in
//
//			return votes.compactMap { vote in
//				if constituents.contains(vote.constituent){
//					return nil
//				} else {
//					return vote
//				}
//			}
//		}
//	}
	
	/// All votes should be for atleast one of the options
	public static var noBlankVotes: GenericValidator {
		GenericValidator(id: "NoBlanks", name: "No blank votes", offenseText: {"\($0.constituent) voted blank"}) { votes, _,_  in
			votes.filter {$0.isBlank}
		}
	}
}
