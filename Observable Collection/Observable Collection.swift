// RxPlus © 2019 Constantino Tsarouhas

import Foundation

/// A random-access collection that can be efficiently observed for changes.
public protocol ObservableCollection : class, RandomAccessCollection {
	
	/// The change handler for the collection, or `nil` if changes are ignored.
	var changeHandler: CollectionChangeHandler? { get set }
	
}

/// A function that does work in response to an observed change.
public typealias CollectionChangeHandler = ([CollectionChange]) -> ()

public enum CollectionChange {
	
	/// An observation that the collection has inserted elements at given offsets.
	///
	/// The collection's indices are invalidated by this change. The offsets of existing elements are moved appropriately.
	///
	/// - Parameter offsets: The offsets from the collection's start index that contain the new elements.
	case insertions(offsets: IndexSet)
	
	/// An observation that the collection has moved an element from one offset to another.
	///
	/// The collection's indices are invalidated by this change. The offsets of other elements are adjusted appropriately.
	///
	/// - Parameter previousOffset: The moved element's offset from the collection's start index before the move.
	/// - Parameter newOffset: The moved element's offset from the collection's start index after the move.
	case move(previousOffset: Int, newOffset: Int)
	
	/// An observation that the collection has deleted elements at given offsets.
	///
	/// The collection's indices are invalidated by this change. The offsets of the remaining elements are moved appropriately.
	///
	/// - Parameter offsets: The offsets from the collection's start index that contain the deleted elements.
	case deletions(offsets: IndexSet)
	
}
