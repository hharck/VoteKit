import Foundation
public protocol VoteProtocol: Actor{
	associatedtype voteType: VoteStub
	associatedtype particularValidator: Validateable
	/// A unique identifier for the vote
	var id: UUID {get}
	
	/// Name of the vote
	var name: String {get}
	
	/// The options available in this vote
	var options: [VoteOption] {get}
	
	/// A set of users who are expected to vote
	var constituents: Set<Constituent> {get set}
	
	/// The votes cast 
	var votes: [voteType] {get set}
		
	/// Extra data used by clients
	var customData: [String: String] {get set}
	  
	func validateParticularValidators() -> [VoteValidationResult]
	var particularValidators: [particularValidator] {get}
	var genericValidators: [GenericValidator<voteType>] {get}

	init(options: [VoteOption], constituents: Set<Constituent>, votes: [voteType])
	
	static var typeName: String {get}
}

public protocol VoteStub: Codable, Sendable, Hashable{
	/// The constituent who did cast this vote
	var constituent: Constituent {get set}
	/// Used for creating a constituent that hasn't voted; most often used by validators
	init(bareBonesVote constituent: Constituent)
	
	var isBlank: Bool {get}
	
	static func fromCSVLine(values: [String], options: [VoteOption], constituent: Constituent) -> Self?
	func csvValueFor(option: VoteOption) -> String
}
