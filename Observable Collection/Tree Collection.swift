// RxPlus © 2019 Constantino Tsarouhas

import Foundation

/// A random-access collection where elements are organised in a tree structure and accessible by index path.
public protocol TreeCollection : RandomAccessCollection where Index == IndexPath {
	
	/// Returns the number of elements accessible via given path, or the number of root elements when given an empty path.
	///
	/// - Parameter path: The index path.
	///
	/// - Returns: The number of elements accessible via `path`, or the number of root elements if `path` is empty.
	func count(in path: IndexPath) -> Int
	
}
