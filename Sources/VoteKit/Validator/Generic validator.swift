/// Validators which are useful for all kind of votes 
public struct GenericValidator<VoteType: VoteStub>: Validateable {
	public typealias ClosureType = @Sendable ([VoteType], _ constituents: Set<Constituent>, _ options: [VoteOption]) -> [VoteType]
	public typealias OffenseClosureType = @Sendable (_ for: VoteType, _ options: [VoteOption]) -> String

	/// The id of the validator
	public let id: String

	/// A name for use in UI
	public let name: String

	/// Generates an error string for why a vote wasn't validated
	private let offenseText: OffenseClosureType

	/// Returns every vote in violation of the validator
	private var closure: ClosureType

	/// Validates the given votes
	/// - Parameters:
	///   - votes: The votes to validate
	///   - constituents: The users allowed to vote
	/// - Returns: An array of error strings. Can be used along with \.name when showing the errors on the frontend
	public func validate(_ votes: [VoteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult {
		let offenders = closure(votes, constituents, allOptions)
		let offenseTexts = offenders.map {offenseText($0, [])}
        return makeResult(errors: offenseTexts)
	}

	public init(id: String, name: String, offenseText: @escaping OffenseClosureType, closure: @escaping ClosureType) {
		self.id = id
		self.name = name
		self.offenseText = offenseText
		self.closure = closure
	}
	public init(id: String, name: String, offenseText: @Sendable @escaping (_ for: VoteType) -> String, closure: @escaping ClosureType) {
		self.init(id: id, name: name, offenseText: {u, _ in offenseText(u)}, closure: closure)
	}
}

extension GenericValidator {
	public static var allValidators: [GenericValidator<VoteType>] {[.everyoneHasVoted, .noBlankVotes]}

	/// Will not validate untill everyone on the allowed voters list has votes
	public static var everyoneHasVoted: GenericValidator {
        GenericValidator(id: "EveryoneVoted", name: "All verified users are required to vote") {"\($0.constituent.identifier) hasn't voted"} closure: { votes, constituents, _ in
			let voters = votes.map(\.constituent)
			let offenders = constituents.compactMap { const -> VoteType? in
				if voters.contains(const) {
					return nil
				} else {
					return VoteType(bareBonesVote: const)
				}
			}

			return offenders
		}
	}

	/// All votes should be for atleast one of the options
	public static var noBlankVotes: GenericValidator {
        GenericValidator(id: "NoBlanks", name: "No blank votes") {"\($0.constituent) voted blank"} closure: { votes, _, _  in
			votes.filter(\.isBlank)
		}
	}
}
