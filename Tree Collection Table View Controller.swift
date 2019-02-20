// RxPlus © 2019 Constantino Tsarouhas

import DepthKit
import os
import RxSwift
import UIKit

/// A table view controller that presents a sectioned tree collection and updates itself in response to any changes to the collection.
open class BoundTableViewController<PresentedCollection : ReactiveCollection & TreeCollection> : UITableViewController {
	
	/// The presented collection.
	///
	/// First-level elements are presented as sections and second-level elements are presented as rows. Higher-level elements are ignored. The table view is empty when this property is `nil`.
	///
	/// In the case that the collection has reference semantics, it must not be mutated directly.
	public var presentedCollection: PresentedCollection?
	
	/// Registers a configurator function for an element of some type.
	///
	/// This method should be invoked early in the table view controller's lifetime such as in an initialiser or `awakeFromNib()`, and especially before the collection is presented. The table view is not reloaded when a configurator is registered.
	///
	/// - Precondition: `addConfigurator(prototypeIdentifier:configure:)` hasn't been invoked already for `Element`.
	///
	/// - Parameter prototypeIdentifier:	The prototype identifier for `Cell`s that present `Element`s.
	/// - Parameter configure:				A function that configures given `Cell` for presentation of given `Element`.
	public func addConfigurator<Cell, Element, PrototypeIdentifier>(
		prototypeIdentifier:	PrototypeIdentifier,
		configure:				@escaping (Cell, Element) -> ()
	) where Cell : UITableViewCell, PrototypeIdentifier : RawRepresentable, PrototypeIdentifier.RawValue == String {
		let elementTypeIdentifier = ObjectIdentifier(Element.self)
		assert(cellConfiguratorsByElementTypeIdentifier[elementTypeIdentifier] == nil, "Existing cell configurator for \(Element.self)")
		cellConfiguratorsByElementTypeIdentifier[elementTypeIdentifier] = CellConfigurator(prototypeIdentifier: prototypeIdentifier.rawValue, configure: configure)
	}
	
	/// Cell configurators keyed by object identifiers on element types.
	private var cellConfiguratorsByElementTypeIdentifier: [ObjectIdentifier : CellConfigurator] = [:]
	
	/// A value encapsulating a cell prototype identifier and a type-erased cell configurator function.
	private struct CellConfigurator {
		
		/// Creates a cell configurator with given prototype identifier and typed configurator function.
		///
		/// - Parameter prototypeIdentifier: The prototype identifier of cells of type `Cell`.
		/// - Parameter configure: A function that configures a given table view cell for presenting a given element.
		init<Cell : UITableViewCell, Element>(prototypeIdentifier: String, configure: @escaping (Cell, Element) -> ()) {
			self.prototypeIdentifier = prototypeIdentifier
			configurator = { cell, element in
				configure(cell as! Cell, element as! Element)
			}
		}
		
		/// The prototype identifier of cells of type `Cell` from the configurator's initialiser.
		let prototypeIdentifier: String
		
		/// Configures given cell for given element.
		///
		/// - Parameter cell: The cell to configure. It must be convertible to `Cell` from the configurator's initialiser.
		/// - Parameter element: The element to configure the cell with. It must be convertible to `Element` from the configurator's initialiser.
		func configure(_ cell: UITableViewCell, for element: Any) {
			configurator(cell, element)
		}
		
		/// The type-erased configurator function.
		private let configurator: (UITableViewCell, Any) -> ()
		
	}
	
	open override func numberOfSections(in tableView: UITableView) -> Int {
		guard let collection = presentedCollection else { return 0 }
		return collection.count(in: [])
	}
	
	open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let collection = presentedCollection !! "No collection available"
		return collection.count(in: [section])
	}
	
	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let collection = presentedCollection !! "No collection available"
		let element = collection[indexPath]
		
		if let configurator = cellConfiguratorsByElementTypeIdentifier[.init(type(of: element))] {
			let cell = tableView.dequeueReusableCell(withIdentifier: configurator.prototypeIdentifier, for: indexPath)
			configurator.configure(cell, for: element)
			return cell
		} else {
			os_log(.error, "No cell configurator register for element of type %@", String(describing: type(of: element)))
			let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
			cell.textLabel?.text = "Unformatted element"
			cell.detailTextLabel?.text = String(reflecting: element)
			return cell
		}
		
	}
	
}

extension BoundTableViewController : ObserverType {
	
	public typealias E = PresentedCollection.E
	
	public func on(_ event: Event<E>) {
		TODO.unimplemented
	}
	
}
