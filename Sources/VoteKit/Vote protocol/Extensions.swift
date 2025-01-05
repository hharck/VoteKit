extension VoteProtocol {
	public func validate() -> [VoteValidationResult] {
		
        var validators: [any Validateable<VoteType>] = genericValidators
        
        if let self = self as? (any HasCustomValidators<VoteType>) {
            //validators += self.assumeIsolated { $0.customValidators }
            // FIXME: Temporary workaround for https://github.com/swiftlang/swift/issues/78442
            validators += self.customValidators
        }
        validators.append(AtLeastOneVote())
        validators.append(OneVotePerUser())
        var errors = validators.map { $0.validate(votes, constituents, options) }
        if let self = (self as? (any HasManualValidation)) {
            errors += self.assumeIsolated {
                $0.doManualValidation()
            }
        }
        return errors
    }
    
    public func validateThrowing() throws {
        let validationResults = validate()
        
        // If any validation has en error, throw it
        guard !validationResults.hasErrors else {
            throw ValidationErrors(error: validationResults)
        }
    }
}

struct ValidationErrors: Error {
    var error: [VoteValidationResult]
}

//MARK: Getters
extension VoteProtocol {
	/// Retrieves an array of options
	public func getAllOptions() async -> [VoteOption]{
		self.options
	}
	
	/// Checks if a given constituentID already has voted in this vote
	public func hasConstituentVoted(_ identifier: ConstituentIdentifier) -> Bool{
		self.votes.contains{
			$0.constituent.identifier == identifier
		}
	}

	/// Checks if a given constituent already has voted in this vote
	public func hasConstituentVoted(_ user: Constituent) -> Bool{
		hasConstituentVoted(user.identifier)
	}
}

//MARK: Manage constituents
extension VoteProtocol{
	public func resetVoteForUser(_ user: Constituent){
		resetVoteForUser(user.identifier)
	}
	
	/// Sets the constituents property, overriding any existing information
	public func setConstituents(_ voters: Set<Constituent>) async{
		self.constituents = voters
	}
	
	/// Adds a constituents and replaced any former ghosts if they exists
	public func addConstituents(_ voter: Constituent) async{
		if let dobbelganger = self.constituents.first(where: {$0.identifier == voter.identifier}){
			self.constituents.remove(dobbelganger)
		}
		
		self.constituents.insert(voter)
	}
	
	/// Adds multiple  constituents
	public func addConstituents(_ constituents: Set<Constituent>) async{
		self.constituents.formUnion(constituents)
	}
}

extension VoteProtocol{
	//MARK: Set votes
	/// Sets the votes property, overriding any existing information
	/// - Parameter votes: The votes to set
	/// - Returns: Whether all userIDs were unique
	@discardableResult public func setVotes(_ votes: [VoteType]) async -> Bool{
		guard votes.map(\.constituent.identifier).nonUniques().isEmpty else {
			return false
		}
		
		self.votes = votes
		return true
	}
	
	/// Adds a vote to the list of votes
	/// - Parameter vote: The vote to set
	/// - Returns: Whether all constituents were unique
	@discardableResult public func addVote(_ vote: VoteType) -> Bool{
		if hasConstituentVoted(vote.constituent){
			return false
		}
		
		self.votes.append(vote)
		return true
	}
	
	public func resetVoteForUser(_ id: ConstituentIdentifier){
		self.votes.removeAll{vote in
			vote.constituent.identifier == id
		}
	}
	
	
	
	@discardableResult public func removeConstituent(_ constituent: Constituent) -> Bool{
		// If the constituent hasn't cast a vote it will be removed from the list of eligible voters in a vote
		if !(self.votes.map(\.constituent.identifier).contains(constituent.identifier)){
			//FIXME: Compiler workaround for "await self.constituents.remove(constituent)"
            self.constituents = self.constituents.filter{$0 != constituent}
			return true
		} else {
			return false
		}
	}
}
