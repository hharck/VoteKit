extension Sequence where Element : Hashable {
	/// Contains all the elements of an array that isn't unique
	public func nonUniques() -> Set<Element> {
		var unique: Set<Element> = []
		
		return Set(self.compactMap{ element -> Element? in
            if unique.insert(element).inserted {
                return nil
			} else {
                return element
			}
		})
	}
}
