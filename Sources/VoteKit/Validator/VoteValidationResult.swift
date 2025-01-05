public struct VoteValidationResult: Codable, Hashable {
	public init(name: String, errors: [String]) {
		self.name = name
		self.errors = errors
	}
	/// The name of the validator responsible for giving this set of errors
	public let name: String
	
	/// The errors found during validation of a single validation rule
	public let errors: [String]
	
}

extension Array where Element == VoteValidationResult {
	public var hasErrors: Bool {
        contains { !$0.errors.isEmpty }
	}
}

// Makes it possible to throw an array of Validation results
extension VoteValidationResult: Sendable {}
func + (lhs: [VoteValidationResult], rhs: VoteValidationResult) -> [VoteValidationResult]{
	lhs + [rhs]
}
