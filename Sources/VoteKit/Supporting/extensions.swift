import Foundation

extension Hashable where Self: Actor {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
	
	nonisolated public var hashValue: Int {
		var hasher = Hasher()
		self.hash(into: &hasher)
		return hasher.finalize()
	}
}

extension Equatable where Self: AnyObject {
	public static func == (lhs:Self, rhs:Self) -> Bool {
		return lhs === rhs
	}
}

extension UUID: @unchecked Sendable{}
