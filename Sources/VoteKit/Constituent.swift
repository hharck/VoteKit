import Foundation
public typealias ConstituentIdentifier = String


/// The description of a voter in a vote
public struct Constituent: Hashable, Codable, Sendable{
	public var name: String?
	public var identifier: ConstituentIdentifier
	
	public var tag: String?
	
	public init(name: String? = nil, identifier: ConstituentIdentifier, tag: String? = nil){
		self.name = name
		self.identifier = identifier
		self.tag = tag
	}
}

// Primarily used for simply creating a constituent in tests
extension Constituent: ExpressibleByStringLiteral{
	public init(stringLiteral value: ConstituentIdentifier){
		self.init(identifier: value)
	}
}

// Allows for the conversion of any kind of sequence containing constituents to be converted into csv
extension Sequence where Element == Constituent{
    /// Creates a string representation of a CSV file containing the name and userid for all constituents
    /// - Returns: A string containing a CSV representation of the constituents
    public func toCSV(config: CSVConfiguration) -> String{
        var csv: String
		let showTags = config.specialKeys["constituents-export show-tags"] == "1"

        if let title = config.specialKeys["constituents-export header"]{
            csv = title
		} else if showTags{
			csv = "Name,Tag,Constituent identifier"
		} else {
            csv = "Name,Constituent identifier"
        }
        
		
        let voters = self.sorted { $0.identifier < $1.identifier}
        
        for voter in voters {
            csv += "\n"
            
            let name = voter.name ?? voter.identifier
			if showTags{
				let tag = voter.tag ?? ""
				csv += "\(name),\(tag),\(voter.identifier)"
			} else {
				csv += "\(name),\(voter.identifier)"
			}
        }
        return csv
    }
}
