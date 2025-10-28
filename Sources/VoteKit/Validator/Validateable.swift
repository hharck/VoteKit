public protocol Validateable<VoteType>: Sendable, Equatable {
	associatedtype VoteType: VoteStub
    associatedtype ValidatorList: Collection<Self> = [Self]

	func validate(_ votes: [VoteType], _ constituents: Set<Constituent>, _ allOptions: [VoteOption]) -> VoteValidationResult

	/// The id of the validator
	var id: String {get}

	/// A name for use in UI
	var name: String {get}

    static var allValidators: ValidatorList {get}
}

extension Validateable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}
}
extension Validateable where Self: RawRepresentable, RawValue == String {
	public var id: String {
		return self.rawValue
	}
}
extension Validateable where Self: CaseIterable {
	public static var allValidators: [Self] { Array(self.allCases) }
}
