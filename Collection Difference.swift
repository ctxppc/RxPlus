// RxPlus © 2019 Constantino Tsarouhas

// TODO: Remove in favour of Swift 5's corresponding implementation when it ships.

// Adapted from https://github.com/apple/swift/blob/9b45fc46ee62236834b3ed463aa325366d14a8bc/stdlib/public/core/CollectionDifference.swift

/// A type that represents the difference between two collection states.
public struct CollectionDifference<ChangeElement> {
	
	/// A type that represents a single change to a collection.
	///
	/// The `offset` of each `insert` refers to the offset of its `element` in the final state after the difference is fully applied. The `offset` of each `remove` refers to the offset of its `element` in the original state. Non-`nil` values of `associatedWith` refer to the offset of the complementary change.
	public enum Change {
		
		case insert(offset: Int, element: ChangeElement, associatedWith: Int?)
		case remove(offset: Int, element: ChangeElement, associatedWith: Int?)
		
		public var offset: Int {
			switch self {
				case .insert(offset: let offset, element: _, associatedWith: _):	return offset
				case .remove(offset: let offset, element: _, associatedWith: _):	return offset
			}
		}
		
		public var element: ChangeElement {
			switch self {
				case .insert(offset: _, element: let element, associatedWith: _):	return element
				case .remove(offset: _, element: let element, associatedWith: _):	return element
			}
		}
		
		public var offsetOfComplementaryChange: Int? {
			switch self {
				case .insert(offset: _, element: _, associatedWith: let offset):	return offset
				case .remove(offset: _, element: _, associatedWith: let offset):	return offset
			}
		}
		
	}
	
	/// Creates an instance from a collection of changes.
	///
	/// To guarantee that instances are unambiguous and safe for compatible base states, this initializer will fail unless its parameter meets to the following requirements:
	///
	/// 1) All insertion offsets are unique
	/// 2) All removal offsets are unique
	/// 3) All offset associations between insertions and removals are symmetric
	///
	/// - Parameter changes: A collection of changes that represent a transition between two states.
	///
	/// - Complexity: O(*n* log(*n*)) where *n* is the length of the parameter.
	public init?<C: Collection>(_ changes: C) where C.Element == Change {
		
		var valid: Bool {
			
			var offsetsByAssociatedInsertion: [Int : Int] = [:]
			var offsetsByAssociatedRemoval: [Int : Int] = [:]
			var insertionOffsets: Set<Int> = []
			var removalOffsets: Set<Int> = []
			
			for change in changes {
				
				guard change.offset >= 0 else { return false }
				
				switch change {
					
					case .remove:
					guard !removalOffsets.contains(change.offset) else { return false }
					removalOffsets.insert(change.offset)
					
					case .insert:
					guard !insertionOffsets.contains(change.offset) else { return false }
					insertionOffsets.insert(change.offset)
					
				}
				
				if let offsetOfComplementaryChange = change.offsetOfComplementaryChange {
					guard offsetOfComplementaryChange >= 0 else { return false }
					switch change {
						
						case .remove:
						guard offsetsByAssociatedRemoval[change.offset] == nil else { return false }
						offsetsByAssociatedRemoval[change.offset] = offsetOfComplementaryChange
						
						case .insert:
						guard offsetsByAssociatedInsertion[offsetOfComplementaryChange] == nil else { return false }
						offsetsByAssociatedInsertion[offsetOfComplementaryChange] = change.offset
						
					}
				}
				
			}
			
			return offsetsByAssociatedInsertion == offsetsByAssociatedRemoval
			
		}
		
		guard valid else { return nil }
		
		let changes = changes.sorted { preceding, following in
			switch (preceding, following) {
				case (.remove, .insert):	return true
				case (.insert, .remove):	return false
				default:					return preceding.offset < following.offset
			}
		}
		
		// Find first insertion via binary search.
		let firstInsertionIndex: Int
		if changes.isEmpty {
			firstInsertionIndex = 0
		} else {
			var range = 0...changes.count
			while range.lowerBound != range.upperBound {
				let i = (range.lowerBound + range.upperBound) / 2
				switch changes[i] {
					case .insert:	range = range.lowerBound...i
					case .remove:	range = (i + 1)...range.upperBound
				}
			}
			firstInsertionIndex = range.lowerBound
		}
		
		self.init(
			insertions: .init(changes[firstInsertionIndex..<changes.count]),
			removals: .init(changes[0..<firstInsertionIndex])
		)
		
	}
	
	/// Creates a collection difference with given insertions and removals.
	///
	/// - Warning: This initialiser does not validate or reorder changes.
	internal init(insertions: [Change], removals: [Change]) {
		self.insertions = insertions
		self.removals = removals
	}
	
	/// The `.insert` changes contained by this difference, from lowest offset to highest.
	public let insertions: [Change]
	
	/// The `.remove` changes contained by this difference, from lowest offset to highest.
	public let removals: [Change]
	
}
