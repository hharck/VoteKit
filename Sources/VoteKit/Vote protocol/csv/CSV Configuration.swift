import Foundation

public struct CSVConfiguration: Codable, Sendable{
    public let name: String
    /* Elements containing the following will be replaced:
     - {constituentID} -> The identifier of the constituent on the given line
	 - {constituentTag} -> The optional tag for the constituent
     */
    let preValues: [String]
    
    let preHeaders: [String]
    
    /* Elements containing the following will be replaced:
     - {option name} -> The option name
     Only valid with a single tag
     */
    let optionHeader: String
    
    public let specialKeys: [String: String]
    
    public init(name: String, preHeaders: [String], preValues: [String], optionHeader: String, specialKeys: [String: String] = [:]) throws{
        self.name = name
        // Validates input
        guard preHeaders.count == preValues.count else {
            throw CSVConfigurationError.incompatiblePreHeaderAndValues
        }
        
        guard Self.isValid(values: preValues), preValues.contains("{constituentID}") else {
            throw CSVConfigurationError.invalidPreValues
        }
        
        guard Self.isValid(values: preHeaders) else {
            throw CSVConfigurationError.invalidPreHeaders
        }
        
        guard Self.isValid(values: optionHeader, minimumBrackets: 1, maximumBrackets: 1), optionHeader.contains("{option name}") else {
            throw CSVConfigurationError.invalidOptionHeader
        }
        
        
        // Checks special keys
        if let ceh = specialKeys["constituents-export header"]{
            guard
                Self.isValid(values: ceh, allowsComma: true, minimumBrackets: 0, maximumBrackets: 0),
                // "constituents-export header" must contain a single comma surrounded by other characters
                let fIndex = ceh.firstIndex(of: ","),
                let lIndex = ceh.lastIndex(of: ","),
                fIndex == lIndex && fIndex > ceh.startIndex && lIndex < ceh.endIndex
            else {
                throw CSVConfigurationError.invalidSpecialKey
            }
        }
        
        
        self.preHeaders = preHeaders
        self.preValues = preValues
        self.optionHeader = optionHeader
        self.specialKeys = specialKeys
    }
    
    
    /// Converts the preValues into parts of a CSV line
    /// - Parameter constituent: The constituents being represented on the line
    /// - Returns: CSV
    func preValues(constituent: Constituent) -> String{
        return self.preValues.map { str in
            if str == "{constituentID}"{
                return constituent.identifier
			} else if str == "{constituentTag}"{
				return constituent.tag ?? ""
            } else {
                return str
            }
        }.joined(separator: ",")
    }
    
    /// Generates the part of the header containing all the options
    /// - Parameter allOptionNames: The names/identifiers of all options
    /// - Returns: The option part of the header
    func optionHeaders(allOptionNames: [String]) -> String{
        var csv = ""
        for i in allOptionNames{
            csv += "," + optionHeader.replacingOccurrences(of: "{option name}", with: i)
        }
        return csv
    }
    
    /// Splits the option header into the pieces surrounding its tags
    /// - Parameter tags: The tags to match
    /// - Returns: The pieces surrounding the tags
    func optionHeaderSplit(by tags: [String] = ["option name"]) -> [String]{
        optionHeader
            .split(separator: "{", omittingEmptySubsequences: false)
        //Removes all tags
            .map{mStr in
                mStr
                    .split(separator: "}", omittingEmptySubsequences: false)
                // Filters away tags
                    .filter{!tags.contains(String($0))}
                    .joined()
            }
            .map(String.init(_:))
    }
    
    /// Validates an array of possible csv default values
    /// - Parameter values: The values to check
    /// - Returns: Whether all values are valid
    private static func isValid(values: [String]) -> Bool{
        !values.contains{
            !isValid(values: $0)
        }
    }
    
    
    /// Validates a default value for CSV
    /// - Parameters:
    ///   - values: The value to check
    ///   - minimumBrackets: The minimum number of brackets expected
    ///   - maximumBrackets: The maximum number of brackets expected
    /// - Returns: The validity of the value
    private static func isValid(values: String, allowsComma: Bool = false, minimumBrackets: Int = 0, maximumBrackets: Int? = nil) -> Bool{
        if values.isEmpty{
            return false
        }
        
        // Check for invalid characters
        if values.contains(";") || values.contains("\n") || values.contains("\r") || values.contains("\t"){
            return false
        }
        if !allowsComma && values.contains(",") {
            return false
        }
        
        // Check for non closed tags
        let leftPattern = try! NSRegularExpression(pattern: "\\{")
        let rightPattern = try! NSRegularExpression(pattern: "\\}")
        
        let leftCount = leftPattern.numberOfMatches(in: values, range: NSRange(values.startIndex..., in: values))
        let rightCount = rightPattern.numberOfMatches(in: values, range: NSRange(values.startIndex..., in: values))
        
        guard leftCount == rightCount else {
            return false
        }
        
        // Checks that the number of brackets is within range, leftCount is only checked due to it being equal to rightCount above
        guard leftCount >= minimumBrackets && (maximumBrackets == nil || leftCount <= maximumBrackets!) else {
            return false
        }
        
        
        return true
    }
}

fileprivate enum CSVConfigurationError: String, Error{
    case invalidPreHeaders = "The pre headers are invalid"
    case invalidPreValues = "The pre values are invalid"
    case invalidOptionHeader = "The option header is invalid"
    case incompatiblePreHeaderAndValues = "The number of pre headers and pre values must be the same"
    case invalidSpecialKey = "A special key is invalid"
}

// Default configurations
extension CSVConfiguration{
    //Format: https://github.com/vstenby/AlternativeVote/blob/main/KABSDemo.csv
    public static func SMKid() -> CSVConfiguration{
        try! self.init(name: "SMKid", preHeaders: ["Tidsstempel", "Studienummer"], preValues: ["01/01/2001 00.00.01", "{constituentID}"], optionHeader: "Stemmeseddel [{option name}]", specialKeys: ["Alternative vote priority suffix" : ".0", "constituents-export header" : "Navn,Studienummer"])
    }
    
    public static func defaultConfiguration() -> CSVConfiguration{
        try! self.init(name: "Default", preHeaders: ["Constituent id"], preValues: ["{constituentID}"], optionHeader: "{option name}")
    }
}
