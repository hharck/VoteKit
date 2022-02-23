import Foundation
extension VoteProtocol{
    public func toCSV(config: CSVConfiguration) -> String {
        
        //Generates header row
        var csv = config.preHeaders.joined(separator: ",")
        
        let allOptionsSortedByName = options.sorted(by: {$0.name < $1.name})
        csv += config.optionHeaders(allOptionNames: allOptionsSortedByName.map(\.name))
        
        
        return votes.map{vote in
            vote.generateCSVLine(config: config, for: allOptionsSortedByName)
        }
        .reduce(csv, +)
    }
    
    
    public static func fromCSV(config: CSVConfiguration, _ csv: String) -> Self?{
        let lines = csv.split(whereSeparator: \.isNewline)
        guard !lines.isEmpty else {
            return nil
        }
        //"omittingEmptySubsequences: false" is not used here, to ensure empty header values will not remain, and therefore getting caught below
        let headerLine = lines.first!.split(separator: ",")
        let valueLines = lines.dropFirst()
        
        // Checks that the correct pre headers are used
        guard headerLine.count > config.preHeaders.count else {
            return nil
        }
        for i in 0..<config.preHeaders.count{
            guard headerLine[i] == config.preHeaders[i] else {
                return nil
            }
        }
        
        // Attempts to find the option
        let parts = config.optionHeaderSplit()
        guard parts.count == 2 else {
            assertionFailure("CSV: optionHeader did not contain the required tag")
            return nil
        }
        
        var errorFlag = false
        
        // Finds the names of the options
        let optionHeaders = headerLine.dropFirst(config.preHeaders.count)
        let options = optionHeaders.compactMap { str -> VoteOption? in
            // Checks that the option name is surrounded as expected
            guard str.hasPrefix(parts.first!), str.hasSuffix(parts.last!) else {
                errorFlag = true
                return nil
            }
            
            let optionName = str.dropFirst(parts.first!.count).dropLast(parts.last!.count)
            
            guard !optionName.isEmpty else {
                errorFlag = true
                return nil
            }
            return VoteOption(String(optionName))
        }
        
        guard !errorFlag else {
            return nil
        }
        
        // Finds the individual votes
        let votes = valueLines.compactMap { val -> Self.voteType? in
            let elements = val.split(separator: ",", omittingEmptySubsequences: false)
            // Checks that the expected number of values is available
            guard options.count == elements.count - config.preValues.count else {
                errorFlag = true
                return nil
            }
            
            // Only the first index of {constituentID} is required to find it
            guard let constituentIndex = config.preValues.firstIndex(of: "{constituentID}") else {
                errorFlag = true
                return nil
            }
			
			var constituentTag: String? = nil
			// Only the first index of {constituentID} is required to find it
			if let tagIndex = config.preValues.firstIndex(of: "{constituentTag}") {
				constituentTag = elements[tagIndex].trimmingCharacters(in: .whitespaces)
			}
			
            let constituentID = elements[constituentIndex].trimmingCharacters(in: .whitespaces)
            guard !constituentID.isEmpty else {
                errorFlag = true
                return nil
            }
            let constituent = Constituent(name: nil, identifier: String(constituentID), tag: constituentTag)
            let values = elements.dropFirst(config.preValues.count).map{$0.trimmingCharacters(in: .whitespaces)}
            return Self.voteType.fromCSVLine(config: config, values: values, options: options, constituent: constituent)
        }
        
        guard !errorFlag else {
            return nil
        }
        
        return Self.init(options: options, constituents: Set(votes.map(\.constituent)), votes: votes)
    }
}

extension VoteStub{
    /// Generates a single line of the exported CSV
    /// - Parameter options: The options in the vote
    /// - Returns: "\n[DATE],[ConstituentID],[Preference for option 1],[preference for option 2] ..., [preference for option n]"
    func generateCSVLine(config: CSVConfiguration, for options: [VoteOption]) -> String{
        let firstColumns = "\n" + config.preValues(constituent: self.constituent)
        
        let values = options
            .map{csvValueFor(config: config, option: $0)}
            .reduce(into: "") { partialResult, val in
                assert(!val.contains(","))
                
                partialResult += "," + val
            }
        return firstColumns + values
    }
}
