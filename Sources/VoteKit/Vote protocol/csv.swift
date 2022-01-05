extension VoteProtocol{
	public func toCSV() -> String {
		//Generates header row
		var csv = "Tidsstempel,Studienummer"
		
		let allOptionsSortedByName = options.sorted(by: {$0.name < $1.name})
		for i in allOptionsSortedByName {
			csv += ",Stemmeseddel [\(i.name)]"
		}
		
		return votes.map{vote in
			vote.generateCSVLine(for: allOptionsSortedByName)
		}
		.reduce(csv, +)
	}
	
	
	public static func fromCSV(_ csv: String) -> Self?{
		let lines = csv.split(whereSeparator: \.isNewline)
		guard !lines.isEmpty else {
			return nil
		}
		let headerLine = lines.first!.split(separator: ",")
		let valueLines = lines.dropFirst()
		
		guard headerLine.count >= 3, headerLine[0].contains("Tidsstempel"), headerLine[1].contains("Studienummer") else {
			return nil
		}
		
		var errorFlag = false
		let options = headerLine.dropFirst(2).compactMap { str -> VoteOption? in
			let trim = String(str.trimmingCharacters(in: .whitespaces).dropFirst("Stemmeseddel [".count).dropLast(1))
			guard !trim.isEmpty else {
				errorFlag = true
				return nil
			}
			return VoteOption(trim)
		}
		
		guard !errorFlag else {
			return nil
		}
		
		let votes = valueLines.compactMap { val -> Self.voteType? in
			let elements = val.split(separator: ",")
			guard elements.count >= 3 else {
				errorFlag = true
				return nil
			}
			let constituentID = elements[1].trimmingCharacters(in: .whitespaces)
			guard !constituentID.isEmpty else {
				errorFlag = true
				return nil
			}
			let constituent = Constituent(name: nil, identifier: constituentID)
			let values = elements.dropFirst(2).map{$0.trimmingCharacters(in: .whitespaces)}
			return Self.voteType.fromCSVLine(values: values, options: options, constituent: constituent)
		}
		
		guard !errorFlag else {
			return nil
		}
		
		return Self.init(options: options, constituents: Set(votes.map(\.constituent)), votes: votes)
	}
}

extension VoteStub{
	
	/// - Parameter options: The options in the vote
	/// - Returns: "\n[DATE],[ConstituentID],[Preference for option 1],[preference for option 2] ..., [preference for option n]"
	func generateCSVLine(for options: [VoteOption]) -> String{
		let firstColumns = "\n01/01/2001 00.00.01,\(self.constituent.identifier)"
		let values = options
			.map{csvValueFor(option: $0)}
			.reduce(into: "") { partialResult, val in
				assert(!val.contains(","))
				
				partialResult += "," + val
			}
		return firstColumns + values
	}
}
