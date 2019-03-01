// RxPlus © 2019 Constantino Tsarouhas

import UIKit

/// An item that can provide a table view cell presentation.
///
/// Objects conforming to this protocol are part of an app's view model — adding conformance to this protocol is discouraged for types of data model objects since that would couple presentation behaviour to data. Instead, define a type that presents a given model object, even for model objects with a unique table view cell presentation.
public protocol TableViewCellPresentable {
	
	/// The identifier of the cell prototype.
	var prototypeIdentifier: String { get }
	
	/// Configures given cell.
	///
	/// - Requires: `cell.reuseIdentifier == self.prototypeIdentifier`.
	///
	/// - Parameter cell: The cell to configure.
	/// - Parameter indexPath: The index path of the item.
	func configure(_ cell: UITableViewCell, for indexPath: IndexPath)
	
}
