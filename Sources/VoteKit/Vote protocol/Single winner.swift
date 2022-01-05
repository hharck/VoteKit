public protocol SingleWinnerVote: VoteProtocol{
	func findWinner(force: Bool, excluding: Set<VoteOption>) async throws -> WinnerWrapper
    func count(force: Bool) async throws -> [VoteOption : UInt]
}

extension SingleWinnerVote{
	func count(force: Bool, excluding: Set<VoteOption>) async throws -> [VoteOption: UInt] {
		try await self.count(force: force)
	}
}


public enum WinnerWrapper{
	case singleWinner(winner: VoteOption)
	case tie(winners: Set<VoteOption>)
	
	public init(_ set: Set<VoteOption>){
		if set.count == 1{
			self = .singleWinner(winner: set.first!)
		} else {
			self = .tie(winners: set)
		}
	}
	
	///Anables input of any kind of sequence
	public init<T: Sequence>(_ sequence: T) where T.Element == VoteOption{
		self.init(Set(sequence))
	}
	
	public func winners() -> Set<VoteOption>{
		switch self {
		case .singleWinner(let winner):
			return [winner]
		case .tie(let winners):
			return winners
		}
	}
}
