// RxPlus © 2019 Constantino Tsarouhas

import Foundation

/// A tree collection that can be observed for changes.
///
/// Assign a handler to `treeChangeHandler` to receive index path-based changes; assign a handler to `changeHandler` to receive offset-based changes. When both handlers are set, `treeChangeHandler` is first invoked followed by `changeHandler`.
public protocol ObservableTreeCollection : TreeCollection, ObservableCollection {
	
	/// The change handler for the tree collection, or `nil` if (index path-based) changes are not required.
	var treeChangeHandler: TreeCollectionChangeHandler? { get set }
	
}

/// A function that does work in response to observed changes.
public typealias TreeCollectionChangeHandler = ([TreeCollectionChange]) -> ()

public enum TreeCollectionChange {
	
	/// An observation that the collection has inserted elements at given offsets.
	///
	/// The collection's indices are invalidated by this change. The offsets of existing elements are moved appropriately.
	///
	/// - Parameter indexPaths: The offsets from the collection's start index that contain the new elements.
	case insertions(indexPaths: Set<IndexPath>)
	
	/// An observation that the collection has moved an element from one offset to another.
	///
	/// The collection's indices are invalidated by this change. The offsets of other elements are adjusted appropriately.
	///
	/// - Parameter previousIndexPath: The moved element's offset from the collection's start index before the move.
	/// - Parameter newIndexPath: The moved element's offset from the collection's start index after the move.
	case move(previousIndexPath: IndexPath, newIndexPath: IndexPath)
	
	/// An observation that the collection has deleted elements at given offsets.
	///
	/// The collection's indices are invalidated by this change. The offsets of the remaining elements are moved appropriately.
	///
	/// - Parameter indexPaths: The offsets from the collection's start index that contain the deleted elements.
	case deletions(indexPaths: Set<IndexPath>)
	
}
