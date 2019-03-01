// RxPlus © 2019 Constantino Tsarouhas

import DepthKit
import os
import RxSwift
import UIKit

/// A table view controller that presents a sectioned tree collection of presentable items and updates itself in response to any changes to the collection.
///
/// The table view controller presents first-level elements as sections and second-level elements as items. Elements in deeper levels are ignored. A section element that conforms to the `TableViewSectionViewPresentable` is presented using the header and footer view the element provides, otherwise it's presented using a section title and detail text if it conforms to the `TableViewSectionPresentable` protocol. Sections that don't conform to either of these protocols are presented without a header and footer. Item elements must conform to the `TableViewCellPresentable` protocol; otherwise a description of the item is presented and an error is logged.
///
/// This class can be used as-is or be subclassed.
open class BoundTableViewController<PresentedCollection : ReactiveCollection & TreeCollection> : UITableViewController {
	
	/// The presented collection.
	///
	/// First-level elements are presented as sections and second-level elements are presented as items. Higher-level elements are ignored. The table view is empty when this property is `nil`.
	///
	/// In the case that the collection has reference semantics, it must not be mutated directly.
	public var collection: PresentedCollection? {
		didSet { tableView?.reloadData() }
	}
	
	open override func numberOfSections(in tableView: UITableView) -> Int {
		guard let collection = collection else { return 0 }
		return collection.count(in: [])
	}
	
	open override func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
		guard let section = element(at: [sectionIndex], as: TableViewSectionPresentable.self) else { return nil }
		return section.titleText
	}
	
	open override func tableView(_ tableView: UITableView, titleForFooterInSection sectionIndex: Int) -> String? {
		guard let section = element(at: [sectionIndex], as: TableViewSectionPresentable.self) else { return nil }
		return section.detailText
	}
	
	open override func tableView(_ tableView: UITableView, viewForHeaderInSection sectionIndex: Int) -> UIView? {
		guard let section = element(at: [sectionIndex], as: TableViewSectionViewPresentable.self) else { return nil }
		return section.headerView(for: sectionIndex)
	}
	
	open override func tableView(_ tableView: UITableView, heightForHeaderInSection sectionIndex: Int) -> CGFloat {
		guard let section = element(at: [sectionIndex], as: TableViewSectionViewPresentable.self) else { return 0 }
		return section.headerViewHeight(for: sectionIndex)
	}
	
	open override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection sectionIndex: Int) -> CGFloat {
		guard let section = element(at: [sectionIndex], as: TableViewSectionViewPresentable.self) else { return 0 }
		return section.estimatedHeaderViewHeight(for: sectionIndex)
	}
	
	open override func tableView(_ tableView: UITableView, viewForFooterInSection sectionIndex: Int) -> UIView? {
		guard let section = element(at: [sectionIndex], as: TableViewSectionViewPresentable.self) else { return nil }
		return section.footerView(for: sectionIndex)
	}
	
	open override func tableView(_ tableView: UITableView, heightForFooterInSection sectionIndex: Int) -> CGFloat {
		guard let section = element(at: [sectionIndex], as: TableViewSectionViewPresentable.self) else { return 0 }
		return section.footerViewHeight(for: sectionIndex)
	}
	
	open override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection sectionIndex: Int) -> CGFloat {
		guard let section = element(at: [sectionIndex], as: TableViewSectionViewPresentable.self) else { return 0 }
		return section.estimatedFooterViewHeight(for: sectionIndex)
	}
	
	open override func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
		return (collection !! "No collection available").count(in: [sectionIndex])
	}
	
	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if let item = element(at: indexPath, as: TableViewCellPresentable.self) {
			let cell = tableView.dequeueReusableCell(withIdentifier: item.prototypeIdentifier, for: indexPath)
			item.configure(cell, for: indexPath)
			return cell
		} else {
			os_log(.error, "Item at %@ does not conform to %@", indexPath.description, String(describing: TableViewCellPresentable.self))
			let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
			cell.textLabel?.text = String(reflecting: collection![indexPath])
			return cell
		}
	}
	
	private func element<T>(at indexPath: IndexPath, as type: T.Type) -> T? {
		return (collection !! "No collection available")[indexPath] as? T
	}
	
}

extension BoundTableViewController : ObserverType {
	
	public typealias E = PresentedCollection.E
	
	public func on(_ event: Event<E>) {
		switch event {
			case .next(let difference):	observe(difference)
			case .error(let error):		fatalError("Unexpected reactive collection error: \(error)")
			case .completed:			fatalError("Premature completion")
		}
	}
	
	private func observe(_ difference: E) {
		
		guard let tableView = tableView else { return }
		
		tableView.beginUpdates()
		defer { tableView.endUpdates() }
		
		func observe(_ change: E.Change) {
			TODO.unimplemented
		}
		
		difference.insertions.forEach(observe)
		difference.removals.forEach(observe)
		
	}
	
}
