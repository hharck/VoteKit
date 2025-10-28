import Foundation
public actor SimpleMajority: SingleWinnerVote {
    public var id: UUID
    public var name: String
    public var options: [VoteOption]
    public var constituents: Set<Constituent>
    public var votes: [SimpleMajorityVote] = []
    public var genericValidators: [GenericValidator<SimpleMajorityVote>]
    public static let typeName: String = "Simple majority"
    
    public init(id: UUID = UUID(), name: String, options: [VoteOption], constituents: Set<Constituent>, votes: [SimpleMajorityVote] = [], genericValidators: [GenericValidator<SimpleMajorityVote>]){
        self.id = id
        self.name = name
        self.options = options
        self.constituents = constituents
        self.votes = votes
        self.genericValidators = genericValidators
    }
    
    public init(options: [VoteOption], constituents: Set<Constituent>, votes: [SimpleMajorityVote]) {
        self.votes = votes
        self.options = options
        self.constituents = constituents
        
        self.id = UUID()
        self.name = "Imported vote"
        self.genericValidators = []
    }
    
	public struct SimpleMajorityVote: VoteStub{
        public var constituent: Constituent
        public var preferredOption: VoteOption?
        
        public var isBlank: Bool { preferredOption == nil }
        
        public init(bareBonesVote constituent: Constituent) {
            self.constituent = constituent
        }
        
        public init(constituent: Constituent, preferredOption: VoteOption? = nil) {
			self.constituent = constituent
			self.preferredOption = preferredOption
		}
	}
}


extension SimpleMajority.SimpleMajorityVote{
    public static func fromCSVLine(config: CSVConfiguration, values: [String], options: [VoteOption], constituent: Constituent) -> SimpleMajority.SimpleMajorityVote? {
        guard values.count == options.count else {
            return nil
        }

        var option: VoteOption?
        for i in 0..<values.count {
            let value = values[i]
            switch value{
            case "0":
                break
            case "1":
                if option != nil{
                    //Multiple values must have a 1, therefore the data is invalid
                    return nil
                }
                option = options[i]
            default:
                return nil
            }
        }
        
        guard option != nil else{
            return nil
        }
        
        return self.init(constituent: constituent, preferredOption: option)
    }
    
    public func csvValueFor(config: CSVConfiguration, option: VoteOption) -> String {
        if option == preferredOption {
            return "1"
        } else {
            return "0"
        }
    }
}
