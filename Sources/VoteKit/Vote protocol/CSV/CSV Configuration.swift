import Foundation

public struct CSVConfiguration: Codable, Sendable {
    public struct SpecialKeys: Hashable, Codable, Sendable {
        public init(constituentsExportHeader: String? = nil, constituentsExportHideNames: Bool = false, constituentsExportHideEmails: Bool = false, constituentsExportShowTags: Bool = false, extraBools: [String: Bool] = [:], extraStrings: [String: String] = [:]) {
            self.constituentsExportHeader = constituentsExportHeader
            self.constituentsExportHideNames = constituentsExportHideNames
            self.constituentsExportHideEmails = constituentsExportHideEmails
            self.constituentsExportShowTags = constituentsExportShowTags
            self.extraBools = extraBools
            self.extraStrings = extraStrings
        }

        public static var empty: Self {self.init()}

        public var constituentsExportHeader: String?
        public var constituentsExportHideNames: Bool = false
        public var constituentsExportHideEmails: Bool = false
        public var constituentsExportShowTags: Bool = false
        public var extraBools: [String: Bool] = [:]
        public var extraStrings: [String: String] = [:]
    }

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

    public let specialKeys: SpecialKeys

    public init(name: String, preHeaders: [String], preValues: [String], optionHeader: String, specialKeys: SpecialKeys = .empty) throws(CSVConfigurationError) {
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
        if let ceh = specialKeys.constituentsExportHeader {
            guard Self.isValid(values: ceh, allowsComma: true, minimumBrackets: 0, maximumBrackets: 0) else {
                throw CSVConfigurationError.invalidSpecialKey
            }

			// "constituents-export header" must either contain a single comma surrounded by other (at least one) characters or no commas at all if "constituents-export hide-names" is true
			let firstCommaIndex = ceh.firstIndex(of: ",")

            let expectedCommaCount = (specialKeys.constituentsExportHideNames ? 0 : 1) + (specialKeys.constituentsExportHideEmails ? 0 : 1) + (specialKeys.constituentsExportShowTags ? 1 : 0)
            if expectedCommaCount == 0 {
                guard firstCommaIndex == nil else {
                    throw CSVConfigurationError.invalidSpecialKey
                }
            } else if let firstCommaIndex = firstCommaIndex {
                // The correct number of fields and the commas should not be in the end of the string
                guard let lastCommaIndex = ceh.lastIndex(of: ","),
                      expectedCommaCount == ceh.filter({$0 == ","}).count,
                      firstCommaIndex > ceh.startIndex && lastCommaIndex < ceh.endIndex else {
                    throw CSVConfigurationError.invalidSpecialKey

                }
            } else { throw CSVConfigurationError.invalidSpecialKey }
        }

        // Unsupported combination
        if specialKeys.constituentsExportShowTags && specialKeys.constituentsExportHeader != nil {
            throw CSVConfigurationError.incompatibleSpecialKeyCombination
        }

        self.preHeaders = preHeaders
        self.preValues = preValues
        self.optionHeader = optionHeader
        self.specialKeys = specialKeys
    }

    /// Converts the preValues into parts of a CSV line
    /// - Parameter constituent: The constituents being represented on the line
    /// - Returns: CSV
    func preValues(constituent: Constituent) -> String {
        return self.preValues.map { str in
            if str == "{constituentID}" {
                return constituent.identifier
			} else if str == "{constituentTag}" {
				return constituent.tag ?? ""
            } else {
                return str
            }
        }.joined(separator: ",")
    }

    /// Generates the part of the header containing all the options
    /// - Parameter allOptionNames: The names/identifiers of all options
    /// - Returns: The option part of the header
    func optionHeaders(allOptionNames: [String]) -> String {
        var csv = ""
        for i in allOptionNames {
            csv += "," + optionHeader.replacingOccurrences(of: "{option name}", with: i)
        }
        return csv
    }

    /// Splits the option header into the pieces surrounding its tags
    /// - Parameter tags: The tags to match
    /// - Returns: The pieces surrounding the tags
    func optionHeaderSplit(by tags: [String] = ["option name"]) -> [String] {
        optionHeader
            .split(separator: "{", omittingEmptySubsequences: false)
        // Removes all tags
            .map {mStr in
                mStr
                    .split(separator: "}", omittingEmptySubsequences: false)
                // Filters away tags
                    .filter {!tags.contains(String($0))}
                    .joined()
            }
            .map(String.init(_:))
    }

    /// Validates an array of possible csv default values
    /// - Parameter values: The values to check
    /// - Returns: Whether all values are valid
    private static func isValid(values: [String]) -> Bool {
        !values.contains {
            !isValid(values: $0)
        }
    }

    /// Validates a default value for CSV
    /// - Parameters:
    ///   - values: The value to check
    ///   - minimumBrackets: The minimum number of brackets expected
    ///   - maximumBrackets: The maximum number of brackets expected
    /// - Returns: The validity of the value
    private static func isValid(values: String, allowsComma: Bool = false, minimumBrackets: Int = 0, maximumBrackets: Int? = nil) -> Bool {
        if values.isEmpty {
            return false
        }

        // Check for invalid characters
        if values.contains(";") || values.contains("\n") || values.contains("\r") || values.contains("\t") {
            return false
        }
        if !allowsComma && values.contains(",") {
            return false
        }

        // Check for non closed tags
        var openCount = 0
        var leftCount = 0
        var rightCount = 0
        for char in values {
            switch char {
            case "{":
                openCount += 1
                leftCount += 1
            case "}":
                guard openCount != 0 else { return false }
                openCount -= 1
                rightCount += 1
            default: break
            }
        }
        guard openCount == 0 else {
            return false
        }

        // Checks that the number of brackets is within range, leftCount is only checked due to it being equal to rightCount above
        guard leftCount >= minimumBrackets && (maximumBrackets == nil || leftCount <= maximumBrackets!) else {
            return false
        }

        return true
    }
}

public enum CSVConfigurationError: String, Error {
    case invalidPreHeaders = "The pre headers are invalid"
    case invalidPreValues = "The pre values are invalid"
    case invalidOptionHeader = "The option header is invalid"
    case incompatiblePreHeaderAndValues = "The number of pre headers and pre values must be the same"
    case invalidSpecialKey = "A special key is invalid"
	case incompatibleSpecialKeyCombination = "Incompatible special key combination"
}

// Default configurations
extension CSVConfiguration {
    // swiftlint:disable force_try
    static let defaultConfig = Self.defaultConfiguration()
    // Format: https://github.com/vstenby/AlternativeVote/blob/main/KABSDemo.csv
    public static func SMKid() -> CSVConfiguration {
        try! CSVConfiguration(name: "S/M-Kid", preHeaders: ["Tidsstempel", "Studienummer"], preValues: ["01/01/2001 00.00.01", "{constituentID}"], optionHeader: "Stemmeseddel [{option name}]", specialKeys: SpecialKeys(constituentsExportHeader: "Studienummer", constituentsExportHideNames: true, constituentsExportHideEmails: true, extraStrings: ["Alternative vote priority suffix": ".0"]))
    }

    public static func defaultConfiguration() -> CSVConfiguration {
        try! CSVConfiguration(name: "Default", preHeaders: ["Identifier"], preValues: ["{constituentID}"], optionHeader: "{option name}")
    }

	public static func defaultWithTags() -> CSVConfiguration {
		try! CSVConfiguration(name: "Default with tags", preHeaders: defaultConfig.preHeaders + ["Tag"], preValues: defaultConfig.preValues  + ["{constituentTag}"], optionHeader: defaultConfig.optionHeader, specialKeys: SpecialKeys(constituentsExportShowTags: true))
	}

	public static func onlyIds() -> CSVConfiguration {
		try! CSVConfiguration(name: "Only ids", preHeaders: defaultConfig.preHeaders, preValues: defaultConfig.preValues, optionHeader: defaultConfig.optionHeader, specialKeys: SpecialKeys(constituentsExportHideNames: true))
   }
    // swiftlint:enable force_try
}
