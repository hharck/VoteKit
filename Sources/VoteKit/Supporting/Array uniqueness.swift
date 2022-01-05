extension Sequence where Element : Hashable {
	/// Contains all the elements of an array that isn't unique
	public func nonUniques() -> Set<Self.Element> {
		var unique: Set<Self.Element> = []
		
		return Set(self.compactMap{ element -> Self.Element? in
			if unique.contains(element){
				return element
			} else {
				unique.insert(element)
				return nil
			}
		})
	}
}
