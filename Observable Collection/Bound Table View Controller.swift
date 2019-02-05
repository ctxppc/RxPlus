// RxPlus © 2019 Constantino Tsarouhas

import UIKit

/// A table view controller that presents a tree collection and can update itself.
public class BoundTableViewController<Collection : ObservableTreeCollection> : UITableViewController {
	
	/// The collection presented by the table view controller.
	///
	/// The table view controller assigns a change handler to the collection while the collection is assigned to the table view controller.
	public var presentedCollection: Collection? {
		
		willSet {
			presentedCollection?.treeChangeHandler = nil
		}
		
		didSet {
			presentedCollection?.treeChangeHandler = { [weak self] in self?.observe($0) }
			tableView?.reloadData()
		}
		
	}
	
	/// Observes given changes to the tree collection.
	private func observe(_ changes: [TreeCollectionChange]) {
		
		guard let tableView = tableView else { return }
		
		tableView.beginUpdates()
		defer { tableView.endUpdates() }
		
		for change in changes {
			switch change {
				case .insertions(let indexPaths):						tableView.insertRows(at: .init(indexPaths), with: .automatic)
				case .move(let previousIndexPath, let newIndexPath):	tableView.moveRow(at: previousIndexPath, to: newIndexPath)
				case .deletions(let indexPaths):						tableView.deleteRows(at: .init(indexPaths), with: .automatic)
			}
		}
		
	}
	
}
