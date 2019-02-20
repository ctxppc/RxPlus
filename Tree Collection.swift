// RxPlus © 2019 Constantino Tsarouhas

import Foundation
import DepthKit

/// A bidirectional collection where elements are organised in a tree structure and accessible by index path in pre-order.
///
/// The root node of the underlying tree is represented by the empty index path but is not an element of the tree collection, i.e., `[]` is not a valid index of the tree collection. The first element of the root node is the first element of the tree collection. The last element of the tree collection is the right-most deepest node of the underlying tree.
///
/// - Invariant: `startIndex` is `[0]`; `endIndex` is `[count(in: [])]`.
/// - Invariant: For any valid index path `p` = `[a, b, …]`, every index path `[a, b, …, z]` with `z` an integer between 0 and `count(in: p) - 1` is also valid. In other words, the collection doesn't _skip_ over valid index paths.
///
/// Default implementations are provided for `startIndex`, `endIndex`, `index(before:)`, and `index(after:)` which respect these invariants.
public protocol TreeCollection : BidirectionalCollection where Index == IndexPath {
	
	/// Returns the number of elements directly contained by the node with given index path.
	///
	/// - Requires: `path` is either the empty index path or a valid index in `self`.
	///
	/// - Parameter path: The index path of the parent.
	///
	/// - Returns: The number of elements directly contained by the node at `path`.
	func count(in path: IndexPath) -> Int
	
}

extension TreeCollection {
	
	public var startIndex: IndexPath {
		return [0]
	}
	
	public var endIndex: IndexPath {
		return [count(in: [])]
	}
	
	public var isEmpty: Bool {
		return count(in: []) == 0
	}
	
	public func index(before path: IndexPath) -> IndexPath {
		guard let (parent, leaf) = path.splittingLast() else { preconditionFailure("No index path precedes the empty path.") }
		return leaf > 0 ? parent.appending(leaf - 1) : parent
	}
	
	public func index(after path: IndexPath) -> IndexPath {
		
		// Go deeper if possible.
		if count(in: path) > 0 {
			return path.appending(0)
		}
		
		// Cannot go deeper: find first uncle node (pre-order traversal)
		for (ancestry, parent) in path.unfoldingBackward() {
			// parent is already visited; try parent's sibling
			let uncle = parent + 1
			if uncle < count(in: ancestry) {
				return ancestry.appending(uncle)
			}
		}
		
		return endIndex
		
	}
	
}
