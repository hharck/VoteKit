public struct VoteValidationResult: Codable, Hashable {
	public init(name: String, errors: [String]) {
		self.name = name
		self.errors = errors
	}
	/// The name of the validator responsible for giving this set of errors
	public let name: String
	
	/// The errors found doing validation of a single validationrule
	public let errors: [String]
	
}

// Turns ValidationResult into a Sequence
extension VoteValidationResult: Sequence{
	public func makeIterator() -> IndexingIterator<[String]>{
		return self.errors.makeIterator()
	}
	
	public func count() -> Int {
		return self.errors.count
	}
}

extension Array where Element == VoteValidationResult{
	//Sums the number of errors
	public var countErrors: Int{
		self.map{$0.count()}.reduce(0, +)
	}
}

// Makes it possible to throw an array of Validation results
extension VoteValidationResult: Sendable{}
extension Array: Error where Element == VoteValidationResult{}
func + (lhs: [VoteValidationResult], rhs: VoteValidationResult) -> [VoteValidationResult]{
	lhs + [rhs]
}
