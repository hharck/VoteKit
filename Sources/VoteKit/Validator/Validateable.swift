public protocol Validateable: Sendable, Equatable{
	associatedtype voteType: VoteStub
	func validate(_ votes: [voteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult
	
	/// The id of the validator
	var id: String {get}
	
	/// A name for use in UI
	var name: String {get}
	
	static var allValidators: [Self] {get}
}

extension Validateable{
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}
}

extension Validateable where Self: RawRepresentable, RawValue == String{
	public var id: String {
		return self.rawValue
	}
}
extension Validateable where Self: CaseIterable{
	
	public static var allValidators: [Self] {Array(self.allCases)}
}
