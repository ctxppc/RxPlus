// RxPlus © 2019 Constantino Tsarouhas

import Foundation

/// A random-access collection where elements are organised in a tree structure and accessible by index path in pre-order.
public protocol TreeCollection : RandomAccessCollection where Index == IndexPath {
	
	/// Returns the number of elements accessible via given path, or the number of root elements when given an empty path.
	///
	/// - Requires: `path` is a valid
	///
	/// - Parameter path: The index path.
	///
	/// - Returns: The number of elements accessible via `path`, or the number of root elements if `path` is empty.
	func numberOfChildren(at path: IndexPath) -> Int
	
}
