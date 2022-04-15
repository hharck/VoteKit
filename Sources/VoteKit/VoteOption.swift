import Foundation

/// Defines an option in a vote
public struct VoteOption: Sendable, Hashable, Equatable, Codable{
	public let id: UUID
	public var name: String
	public var subTitle: String?
	public var customData: [String: String] = [:]
	
	public init(_ name: String, subTitle: String? = nil, customData: [String: String]? = nil){
		self.name = name
		self.subTitle = subTitle
		self.id = UUID()
	}
}

//Adds support for creating options as a simple array of strings; mostly used for testing purposes
extension VoteOption: ExpressibleByStringLiteral{
	public init(stringLiteral value: String) {
		self.init(value)
	}
}
