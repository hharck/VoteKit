public struct VoteValidationResult: Codable, Hashable, Sendable {
	fileprivate init(name: String, errors: [String]) {
		self.name = name
		self.errors = errors
	}
	/// The name of the validator responsible for giving this set of errors
	public let name: String
	
	/// The errors found during validation of a single validation rule
	public let errors: [String]
	
}

extension Validateable {
    public func makeResult(errors: [String] = []) -> VoteValidationResult {
        VoteValidationResult(name: name, errors: errors)
    }
}

extension Array where Element == VoteValidationResult {
	public var hasErrors: Bool {
        contains { !$0.errors.isEmpty }
	}
}
