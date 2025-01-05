public enum HeaderValues: String {
    case name = "Name"
    case identifier = "Identifier"
    case tag = "Tag"
    case email = "Email"

    var shouldLowercase: Bool {
        switch self {
        case .identifier:
            return true
        default:
            return false
        }
    }
}

//MARK: Export
public typealias HeaderValueDictionary = [HeaderValues: String]
public typealias SequenceOfHeadervalueDictionaries = Sequence<HeaderValueDictionary>

extension HeaderValueDictionary {
    init(constituent: Constituent) {
        self.init()
        self[.name] = constituent.name
        self[.identifier] = constituent.identifier
        self[.tag] = constituent.tag
        self[.email] = constituent.email
    }
    public var name: String? {self[.name]}
    public var identifier: String? {self[.identifier]}
    public var tag: String? {self[.tag]}
    public var email: String? {self[.email]}
}

extension Constituent {
    init(rowNo: Int?, headerValues: HeaderValueDictionary) throws {
        guard let identifier = headerValues[.identifier] else {
            throw DecodeConstituentError.invalidIdentifier.errorOnLine(rowNo)
        }

        let name: String? = (headerValues[.name] == identifier) ? nil : headerValues[.name]

        self.init(name: name, identifier: identifier, tag: headerValues[.tag], email: headerValues[.email])
    }
}

extension SequenceOfHeadervalueDictionaries {
    public func toCSV(config: CSVConfiguration) -> String {
        var csv: String = ""
        let showTags = config.specialKeys.constituentsExportShowTags
        let showNames = !config.specialKeys.constituentsExportHideNames
        let showEmails = !config.specialKeys.constituentsExportHideEmails

        if let header = config.specialKeys.constituentsExportHeader {
            csv = header
        } else {
            if showNames { csv += HeaderValues.name.rawValue + "," }
            csv += HeaderValues.identifier.rawValue
            if showTags { csv += "," + HeaderValues.tag.rawValue }
            if showEmails { csv += "," + HeaderValues.email.rawValue }
        }

        let constituents = self.sorted {
            guard let first = $0[.identifier] else {
                return false
            }
            guard let second = $1[.identifier] else {
                return true
            }
            return first < second
        }
        for constituent in constituents {
            csv += "\n"

            if showNames {
                let name = constituent[.name] ?? constituent[.identifier] ?? ""
                csv += "\(name),"
            }
            csv += constituent[.identifier] ?? ""
            if showTags{
                csv += ",\(constituent[.tag] ?? "")"
            }
            if showEmails {
                csv += ",\(constituent[.email] ?? "")"
            }
        }
        return csv
    }

    public func getConstituents() throws -> [Constituent] {
        try self.enumerated().map{ ($0 + 1, $1 )}.map(Constituent.init)
    }
}

// Allows for the conversion of any kind of sequence containing constituents to be converted into csv
extension Sequence where Element == Constituent{
    /// Creates a string representation of a CSV file containing the name and userid for all constituents
    /// - Returns: A string containing a CSV representation of the constituents
    public func toCSV(config: CSVConfiguration) -> String{
        map(HeaderValueDictionary.init).toCSV(config: config)
    }
}


// MARK: Import

/// Creates an array of constituents from a CSV file
public func constituentDataListFromCSV(file: String, config: CSVConfiguration? = nil, maxNameLength: Int) throws -> [HeaderValueDictionary] {
	guard !file.contains(";"), !file.contains("\t") else {
		throw DecodeConstituentError.invalidCSV
	}
	
    let individualConstituentLines = file.split(whereSeparator: \.isNewline)
	
	// There has to be a limit
	if individualConstituentLines.count > 10_000 {
		throw DecodeConstituentError.nameTooLong
	}
	
	guard let header = individualConstituentLines.first else {
        throw DecodeConstituentError.lineError(error: .invalidHeader, line: 0)
    }

    let headerValues: [HeaderValues] = try {
        do {
            let split = header.split(separator: ",").map(String.init)
            let headerValues = split.compactMap(HeaderValues.init)
            guard split.count == headerValues.count else {
                throw DecodeConstituentError.invalidCSV
            }
            return headerValues
        } catch {
            if let config, let customHeader = config.specialKeys.constituentsExportHeader, header == customHeader  {

                var vals: [HeaderValues] = []
                if !config.specialKeys.constituentsExportHideNames {
                    vals.append(.name)
                }
                vals.append(.identifier)
                if config.specialKeys.constituentsExportShowTags {
                    vals.append(.tag)
                }
                if !config.specialKeys.constituentsExportHideEmails {
                    vals.append(.email)
                }
                return vals
            } else {
                if let error = error as? DecodeConstituentError {
                    throw error.errorOnLine(0)
                } else {
                    throw error
                }
            }
        }
    }()

    return try individualConstituentLines.dropFirst().enumerated().map{ index, row -> [HeaderValues: String] in
        let rowNo = index + 1
		let row = row.split(separator:",", omittingEmptySubsequences: false)
		guard row.count == headerValues.count else {
            throw DecodeConstituentError.invalidCSV.errorOnLine(rowNo)
		}

        let values: HeaderValueDictionary = headerValues.enumerated().reduce(into: HeaderValueDictionary()) { (partialResult, arg1) in
            let (index, headerValue) = arg1
            let str = String(row[index]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !str.isEmpty && str.count <= maxNameLength else {
				return
            }
            if headerValue.shouldLowercase {
                partialResult[headerValue] = str.lowercased()
            } else {
                partialResult[headerValue] = str
            }
        }

        guard values[.tag]?.first != "-" else {
            throw DecodeConstituentError.invalidTag.errorOnLine(rowNo)
        }
        guard (values[.email]?.count ?? .max) >= 5 else {
            throw DecodeConstituentError.invalidEmail.errorOnLine(rowNo)
        }
        return values
	}
}

public func constituentsListFromCSV(file: String, config: CSVConfiguration? = nil, maxNameLength: Int) throws -> [Constituent] {
    try constituentDataListFromCSV(file: file, config: config, maxNameLength: maxNameLength).getConstituents()
}

// MARK: Error type
public indirect enum DecodeConstituentError: Error{
	case invalidIdentifier, nameTooLong, invalidCSV, invalidHeader, invalidTag, invalidEmail
    case lineError(error: DecodeConstituentError, line: Int)
    func errorOnLine(_ line: Int?) -> Self {
        if case .lineError = self {
            return self
        } else if let line {
            return .lineError(error: self, line: line)
        } else {
            return self
        }
    }
}
